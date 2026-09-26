import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_theme.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/backup/platform_backup_file_gateway.dart';
import 'package:the_registry/features/backup/registry_archive.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/reminders/data/memory_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/data/notification_prompt_store.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/presentation/onboarding_gate.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryApp extends StatefulWidget {
  const RegistryApp({
    super.key,
    required this.onboardingRepository,
    this.documentRepository,
    this.subscriptionRepository,
    this.imagePickerService,
    this.datePickerService,
    this.documentOcrService,
    this.clock,
    this.reminderScheduler,
    this.timeZoneSource,
    this.notificationPromptStore,
    this.backupArchive,
    this.backupFiles,
    this.backupService,
    this.backupTempDirectory,
    this.locale,
  });

  final OnboardingRepository onboardingRepository;
  final DocumentRepository? documentRepository;
  final SubscriptionRepository? subscriptionRepository;
  final ImagePickerService? imagePickerService;
  final DatePickerService? datePickerService;
  final DocumentOcrService? documentOcrService;
  final Clock? clock;
  final LocalReminderScheduler? reminderScheduler;
  final TimeZoneSource? timeZoneSource;
  final NotificationPromptStore? notificationPromptStore;
  final RegistryArchive? backupArchive;
  final BackupFileGateway? backupFiles;
  final RegistryBackupService? backupService;
  final Directory? backupTempDirectory;

  /// When null, the device locale is used. Unsupported languages fall back
  /// to English via [localeListResolutionCallback].
  final Locale? locale;

  static const _supportedLocales = [Locale('en'), Locale('fr'), Locale('ar')];

  static Locale _resolveLocale(
    List<Locale>? locales,
    Iterable<Locale> supported,
  ) {
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

  @override
  State<RegistryApp> createState() => _RegistryAppState();
}

class _RegistryAppState extends State<RegistryApp> with WidgetsBindingObserver {
  late final DocumentRepository _documents =
      widget.documentRepository ?? createDefaultDocumentRepository();
  late final SubscriptionRepository _subscriptions =
      widget.subscriptionRepository ?? createDefaultSubscriptionRepository();
  late final ImagePickerService _images =
      widget.imagePickerService ?? createDefaultImagePicker();
  late final DatePickerService _dates =
      widget.datePickerService ?? createDefaultDatePicker();
  late final DocumentOcrService _ocr =
      widget.documentOcrService ?? createDefaultDocumentOcr();
  late final Clock _clock = widget.clock ?? const Clock();
  late final RegistryArchive _archive = _createArchive();
  late final BackupFileGateway _backupFiles =
      widget.backupFiles ?? const PlatformBackupFileGateway();
  late final RegistryBackupService _backups =
      widget.backupService ??
      RegistryBackupService(
        archive: _archive,
        files: _backupFiles,
        clock: _clock,
        tempDirectory: widget.backupTempDirectory ?? Directory.systemTemp,
      );
  late final ReminderCoordinator _reminders = ReminderCoordinator(
    documents: _documents,
    subscriptions: _subscriptions,
    scheduler: widget.reminderScheduler ?? MemoryReminderScheduler(),
    clock: _clock,
    timeZone: widget.timeZoneSource ?? FixedTimeZoneSource(tz.UTC),
    promptStore: widget.notificationPromptStore,
    locale: _reminderLocale(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_reminders.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reminders.reconcile());
    }
  }

  Locale _reminderLocale([List<Locale>? locales]) {
    return resolveReminderLocale([
      if (widget.locale != null) widget.locale!,
      ...?locales,
      ...WidgetsBinding.instance.platformDispatcher.locales,
    ]);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final resolved = _reminderLocale(locales);
    if (resolved == _reminders.locale) {
      return;
    }
    _reminders.locale = resolved;
    unawaited(_reminders.reconcile());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminders.dispose();
    super.dispose();
  }

  RegistryArchive _createArchive() {
    final provided = widget.backupArchive;
    if (provided != null) {
      return provided;
    }
    final documents = _documents;
    final subscriptions = _subscriptions;
    if (documents is InMemoryDocumentRepository &&
        subscriptions is InMemorySubscriptionRepository) {
      return MemoryRegistryArchive(
        documentsRepository: documents,
        subscriptionsRepository: subscriptions,
      );
    }
    throw StateError(
      'A saved registry needs the archive created with its database.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistryDependencies(
      documents: _documents,
      subscriptions: _subscriptions,
      imagePicker: _images,
      datePicker: _dates,
      documentOcr: _ocr,
      clock: _clock,
      reminders: _reminders,
      backups: _backups,
      backupFiles: _backupFiles,
      child: MaterialApp(
        onGenerateTitle: (context) => 'Registry',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        locale: widget.locale,
        supportedLocales: RegistryApp._supportedLocales,
        localeListResolutionCallback: RegistryApp._resolveLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OnboardingGate(repository: widget.onboardingRepository),
      ),
    );
  }
}
