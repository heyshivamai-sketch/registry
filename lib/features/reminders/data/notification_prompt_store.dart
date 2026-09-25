import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the system notification dialog was already shown.
///
/// A later save must not raise that dialog again. Turning notifications on
/// after a denial goes through system settings.
abstract class NotificationPromptStore {
  Future<bool> wasPrompted();

  Future<void> markPrompted();
}

class MemoryNotificationPromptStore implements NotificationPromptStore {
  bool prompted = false;

  @override
  Future<bool> wasPrompted() async => prompted;

  @override
  Future<void> markPrompted() async {
    prompted = true;
  }
}

class PreferencesNotificationPromptStore implements NotificationPromptStore {
  PreferencesNotificationPromptStore(this._preferences);

  final SharedPreferences _preferences;

  static const key = 'registry_notification_prompted';

  @override
  Future<bool> wasPrompted() async => _preferences.getBool(key) ?? false;

  @override
  Future<void> markPrompted() async {
    await _preferences.setBool(key, true);
  }
}
