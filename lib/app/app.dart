import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:the_registry/app/theme/app_theme.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/presentation/onboarding_gate.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryApp extends StatelessWidget {
  const RegistryApp({
    super.key,
    required this.onboardingRepository,
    this.locale,
  });

  final OnboardingRepository onboardingRepository;

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
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => 'Registry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: _supportedLocales,
      localeListResolutionCallback: _resolveLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OnboardingGate(repository: onboardingRepository),
    );
  }
}
