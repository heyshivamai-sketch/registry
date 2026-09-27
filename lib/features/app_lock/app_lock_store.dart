import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppLockStore implements Listenable {
  bool get enabled;

  Future<void> setEnabled(bool value);
}

class MemoryAppLockStore extends ChangeNotifier implements AppLockStore {
  MemoryAppLockStore({bool enabled = false}) {
    _enabled = enabled;
  }

  late bool _enabled;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    notifyListeners();
  }
}

class PreferencesAppLockStore extends ChangeNotifier implements AppLockStore {
  PreferencesAppLockStore(this._preferences)
    : _enabled = _preferences.getBool(enabledKey) ?? false;

  static const enabledKey = 'app_lock_enabled';

  final SharedPreferences _preferences;
  bool _enabled;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _preferences.setBool(enabledKey, value);
    notifyListeners();
  }
}
