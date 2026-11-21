import 'package:flutter/material.dart';

import 'app/registry_bootstrap.dart';
import 'features/documents/data/firebase_ai_document_ocr_bootstrap.dart';
import 'features/reminders/data/device_time_zone_source.dart';
import 'features/reminders/data/plugin_local_reminder_scheduler.dart';

/// Reset first-run onboarding during development:
/// `flutter run --dart-define=RESET_ONBOARDING=true`
const bool kResetOnboarding = bool.fromEnvironment('RESET_ONBOARDING');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documentScanner = await initializeFirebaseAiDocumentScanner();
  runApp(
    RegistryBootstrap(
      reminderScheduler: PluginLocalReminderScheduler(),
      timeZoneSource: const DeviceTimeZoneSource(),
      documentOcrService: documentScanner,
    ),
  );
}
