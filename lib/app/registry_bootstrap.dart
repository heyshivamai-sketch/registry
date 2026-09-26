import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/app/theme/app_theme.dart';
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/reminders/data/notification_prompt_store.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Loads on-device records before any repository-backed screen is built.
///
/// An open failure stays on an error screen. It does not substitute an empty
/// repository, so a later save cannot overwrite records that are already stored.
class RegistryBootstrap extends StatefulWidget {
  const RegistryBootstrap({
    super.key,
    this.openStore,
    this.loadPreferences,
    this.onboardingRepository,
    this.locale,
    this.resetOnboarding = false,
    this.reminderScheduler,
    this.timeZoneSource,
  });

  final Future<RegistryStore> Function()? openStore;
  final Future<SharedPreferences> Function()? loadPreferences;

  /// When set, startup does not read onboarding preferences itself.
  final OnboardingRepository? onboardingRepository;
  final Locale? locale;
  final bool resetOnboarding;
  final LocalReminderScheduler? reminderScheduler;
  final TimeZoneSource? timeZoneSource;

  @override
  State<RegistryBootstrap> createState() => _RegistryBootstrapState();
}

class _RegistryBootstrapState extends State<RegistryBootstrap> {
  _StartupPhase _phase = _StartupPhase.loading;
  RegistryStore? _store;
  OnboardingRepository? _onboarding;
  NotificationPromptStore? _notificationPrompts;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final opener = widget.openStore ?? openDefaultRegistryStore;
    final loadPreferences =
        widget.loadPreferences ?? SharedPreferences.getInstance;
    RegistryStore? store;
    try {
      store = await opener();
      final OnboardingRepository onboarding;
      NotificationPromptStore? prompts;
      final injected = widget.onboardingRepository;
      if (injected != null) {
        onboarding = injected;
      } else {
        final preferences = await loadPreferences();
        prompts = PreferencesNotificationPromptStore(preferences);
        final stored = SharedPreferencesOnboardingRepository(preferences);
        if (widget.resetOnboarding) {
          await stored.reset();
        }
        onboarding = stored;
      }
      if (!mounted || generation != _generation) {
        await store.close();
        return;
      }
      setState(() {
        _store = store;
        _onboarding = onboarding;
        _notificationPrompts = prompts;
        _phase = _StartupPhase.ready;
      });
    } catch (_) {
      await store?.close();
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _store = null;
        _onboarding = null;
        _phase = _StartupPhase.failed;
      });
    }
  }

  void _retry() {
    setState(() => _phase = _StartupPhase.loading);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final onboarding = _onboarding;
    if (_phase == _StartupPhase.ready && store != null && onboarding != null) {
      return RegistryApp(
        onboardingRepository: onboarding,
        documentRepository: store.documents,
        subscriptionRepository: store.subscriptions,
        backupArchive: SqliteRegistryArchive(store),
        locale: widget.locale,
        reminderScheduler: widget.reminderScheduler,
        timeZoneSource: widget.timeZoneSource,
        notificationPromptStore: _notificationPrompts,
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: widget.locale,
      supportedLocales: _supportedLocales,
      localeListResolutionCallback: _resolveLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _phase == _StartupPhase.failed
          ? _StorageError(onRetry: _retry)
          : const _StorageLoading(),
    );
  }
}

enum _StartupPhase { loading, ready, failed }

const _supportedLocales = [Locale('en'), Locale('fr'), Locale('ar')];

Locale _resolveLocale(List<Locale>? locales, Iterable<Locale> supported) {
  if (locales != null) {
    for (final candidate in locales) {
      for (final supportedLocale in supported) {
        if (supportedLocale.languageCode == candidate.languageCode) {
          return supportedLocale;
        }
      }
    }
  }
  return const Locale('en');
}

class _StorageLoading extends StatelessWidget {
  const _StorageLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey<String>('registry-storage-loading'),
      body: Center(
        child: CircularProgressIndicator(
          semanticsLabel: l10n.storageLoadingLabel,
        ),
      ),
    );
  }
}

class _StorageError extends StatelessWidget {
  const _StorageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey<String>('registry-storage-error'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.error_outline,
                size: AppSpacing.iconLg,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.storageErrorTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.storageErrorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              RegistryPrimaryButton(
                key: const ValueKey<String>('registry-storage-retry'),
                label: l10n.storageErrorRetry,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
