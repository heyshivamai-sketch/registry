import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Saves each binding.takeScreenshot() call as a PNG under artifacts/store_media/raw.
Future<void> main() => integrationDriver(
  onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
    final file = File('artifacts/store_media/raw/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
  responseDataCallback: null,
);
