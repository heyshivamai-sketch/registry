import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/entitlements/presentation/local_pro_screen.dart';
import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';
import 'support/sample_document.dart';
import 'support/save_screenshot.dart';

void main() {
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.firstWhere((p) => p['name'] == 'flutter');
    final root = config.uri
        .resolve('${flutter['rootUri']}/')
        .resolve('../../bin/cache/artifacts/material_fonts/');
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          File.fromUri(
            root.resolve(entry.value),
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  for (final width in [320.0, 390.0, 768.0, 1024.0]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets('Home and Pro at width $width, scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final docs = InMemoryDocumentRepository();
        await docs.save(sampleDocument());
        await tester.pumpWidget(
          wrapForScreenshot(
            RegistryApp(
              onboardingRepository: FakeOnboardingRepository(completed: true),
              documentRepository: docs,
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byType(HomeMetricsRow),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expectWholeWords(tester);
        final label = find.descendant(
          of: find.byType(HomeMetricsRow),
          matching: find.text('Documents'),
        );
        final rich = find.descendant(
          of: label,
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(rich);
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 9),
        );
        expect(
          boxes.map((box) => box.top).toSet(),
          hasLength(1),
          reason: 'Documents must stay a whole word',
        );
        if (width == 390 && scale == 1) {
          await saveScreenshot(tester, 'home', folder: 'responsive_refresh');
          final messenger = ScaffoldMessenger.of(
            tester.element(find.byType(HomeMetricsRow)),
          );
          messenger.showSnackBar(
            const SnackBar(content: Text('Document saved on this device.')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final toast = tester.getRect(find.byType(SnackBar));
          final dock = tester.getRect(
            find.byKey(const ValueKey<String>('nav-dock')),
          );
          expect(toast.bottom, lessThanOrEqualTo(dock.top));
          await saveScreenshot(tester, 'toast', folder: 'responsive_refresh');
          messenger.hideCurrentSnackBar();
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
        await tester.pumpAndSettle();
        await tapProfileControl(
          tester,
          const ValueKey<String>('local-pro-open'),
        );
        expect(find.byType(LocalProScreen), findsOneWidget);
        expectWholeWords(tester);
        expect(tester.takeException(), isNull);
        if (width == 390 && scale == 1) {
          await saveScreenshot(tester, 'pro', folder: 'responsive_refresh');
        }
        Navigator.of(tester.element(find.byType(LocalProScreen))).pop();
        await tester.pumpAndSettle();
        for (final tab in [
          'nav-documents',
          'nav-subscriptions',
          'nav-profile',
        ]) {
          await tester.tap(find.byKey(ValueKey<String>(tab)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expectWholeWords(tester);
        }
        await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('documents-add')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectWholeWords(tester);
        if (width == 390 && scale == 1) {
          await saveScreenshot(
            tester,
            'scan_source',
            folder: 'responsive_refresh',
          );
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

void expectWholeWords(WidgetTester tester) {
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
    final text = paragraph.text.toPlainText();
    for (final word in RegExp(r'\p{L}{2,}', unicode: true).allMatches(text)) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      );
      expect(
        boxes.map((box) => box.top.round()).toSet().length,
        lessThanOrEqualTo(1),
        reason: 'Word "${word.group(0)}" was split in "$text"',
      );
    }
  }
}
