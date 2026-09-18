import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const screenshotRootKey = ValueKey<String>('screenshot-root');

Widget wrapForScreenshot(Widget child) {
  return RepaintBoundary(key: screenshotRootKey, child: child);
}

Future<void> saveScreenshot(
  WidgetTester tester,
  String filename, {
  String folder = 'add_document',
}) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(screenshotRootKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('screenshots/$folder/$filename.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
