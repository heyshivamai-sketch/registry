import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_theme.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/presentation/onboarding_gate.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryApp extends StatefulWidget {
  const RegistryApp({
    super.key,
    required this.onboardingRepository,
    this.documentRepository,
    this.imagePickerService,
    this.datePickerService,
    this.locale,
  });

  final OnboardingRepository onboardingRepository;
  final DocumentRepository? documentRepository;
  final ImagePickerService? imagePickerService;
  final DatePickerService? datePickerService;

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

class _RegistryAppState extends State<RegistryApp> {
  late final DocumentRepository _documents =
      widget.documentRepository ?? createDefaultDocumentRepository();
  late final ImagePickerService _images =
      widget.imagePickerService ?? createDefaultImagePicker();
  late final DatePickerService _dates =
      widget.datePickerService ?? createDefaultDatePicker();

  @override
  Widget build(BuildContext context) {
    return RegistryDependencies(
      documents: _documents,
      imagePicker: _images,
      datePicker: _dates,
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
