import 'package:flutter/services.dart';

/// Hides app-switcher pixels on Android while app lock is on.
///
/// iOS uses the Flutter privacy cover, which is shown as soon as the app
/// becomes inactive. This channel is a no-op where it is not implemented.
abstract class PrivacyFlag {
  Future<void> setSecure(bool secure);
}

class PlatformPrivacyFlag implements PrivacyFlag {
  static const channelName = 'com.registry.app/privacy';

  const PlatformPrivacyFlag({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  final MethodChannel _channel;

  @override
  Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on Object {
      // Tests and platforms without the channel still use the Flutter cover.
    }
  }
}
