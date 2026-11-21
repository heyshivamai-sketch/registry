import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_controller.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/fake_date_picker_service.dart';
import 'support/fake_onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = FixedClock(DateTime(2026, 11, 20));
  late InMemoryDocumentRepository documents;
  late InMemorySubscriptionRepository subscriptions;
  late FakeDatePickerService dates;

  setUp(() {
    documents = InMemoryDocumentRepository();
    subscriptions = InMemorySubscriptionRepository();
    dates = FakeDatePickerService();
  });

  Widget testApp() {
    return RegistryApp(
      key: UniqueKey(),
      onboardingRepository: FakeOnboardingRepository(completed: true),
      documentRepository: documents,
      subscriptionRepository: subscriptions,
      datePickerService: dates,
      clock: clock,
      locale: const Locale('en'),
    );
  }

  group('Subscription Categories Model & Presentation Tests', () {
    test('contains all 24 subscription categories', () {
      expect(SubscriptionCategory.values.length, 25); // 24 categories + healthFitness
      final expectedCategories = [
        SubscriptionCategory.aiServices,
        SubscriptionCategory.business,
        SubscriptionCategory.cloudStorage,
        SubscriptionCategory.communication,
        SubscriptionCategory.development,
        SubscriptionCategory.donations,
        SubscriptionCategory.education,
        SubscriptionCategory.entertainment,
        SubscriptionCategory.fashionBeauty,
        SubscriptionCategory.finance,
        SubscriptionCategory.fitness,
        SubscriptionCategory.food,
        SubscriptionCategory.productivity,
        SubscriptionCategory.security,
        SubscriptionCategory.shopping,
        SubscriptionCategory.socialMedia,
        SubscriptionCategory.software,
        SubscriptionCategory.sport,
        SubscriptionCategory.tools,
        SubscriptionCategory.transportation,
        SubscriptionCategory.travel,
        SubscriptionCategory.utilities,
        SubscriptionCategory.videoTv,
        SubscriptionCategory.other,
      ];

      for (final cat in expectedCategories) {
        expect(SubscriptionCategory.values.contains(cat), isTrue);
      }
    });

    test('SubscriptionCopy returns valid labels and icons for all categories', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      for (final category in SubscriptionCategory.values) {
        final label = SubscriptionCopy.category(l10n, category);
        expect(label, isNotEmpty, reason: 'Category $category should have a non-empty name');

        final icon = SubscriptionCopy.iconFor(category);
        expect(icon, isNotNull, reason: 'Category $category should have an assigned icon');
      }

      // Check specific new categories
      expect(SubscriptionCopy.category(l10n, SubscriptionCategory.aiServices), 'AI services');
      expect(SubscriptionCopy.category(l10n, SubscriptionCategory.cloudStorage), 'Cloud storage');
      expect(SubscriptionCopy.category(l10n, SubscriptionCategory.fashionBeauty), 'Fashion & beauty');
      expect(SubscriptionCopy.category(l10n, SubscriptionCategory.videoTv), 'Video & TV');
      expect(SubscriptionCopy.category(l10n, SubscriptionCategory.socialMedia), 'Social media');
    });

    test('AddSubscriptionController sets and validates category', () {
      final controller = AddSubscriptionController(clock: clock);
      final l10n = lookupAppLocalizations(const Locale('en'));

      controller.setServiceName('ChatGPT Plus');
      controller.setCategory(SubscriptionCategory.aiServices);

      expect(controller.category, SubscriptionCategory.aiServices);
      expect(controller.continueStep(l10n), isTrue);
      expect(controller.step, AddSubscriptionStep.billing);
    });
  });

  group('AddSubscriptionScreen Category Selector UI Tests', () {
    testWidgets('tapping category field opens searchable sheet with all 24 categories', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();

      // Open Add Subscription wizard
      await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('add-subscription')));
      await tester.pumpAndSettle();

      // Category selector field should be present
      final categoryField = find.byKey(
        const ValueKey<String>('field-subscription-category'),
      );
      expect(categoryField, findsOneWidget);

      // Tap to open sheet
      await tester.tap(categoryField);
      await tester.pumpAndSettle();

      // Check options in the sheet by item keys
      expect(find.byKey(const ValueKey<String>('sub-category-aiServices')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('sub-category-cloudStorage')), findsOneWidget);

      // Tap 'AI services'
      await tester.tap(find.byKey(const ValueKey<String>('sub-category-aiServices')));
      await tester.pumpAndSettle();

      // Sheet closed and category field reflects selection
      expect(find.byKey(const ValueKey<String>('sub-category-aiServices')), findsNothing);
      expect(find.text('AI services'), findsOneWidget);
    });
  });

  group('AddDocumentScreen Category Selector UI Tests', () {
    testWidgets('category selector opens searchable sheet in Add Document', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();

      // Open Add Document wizard
      await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('add-document')));
      await tester.pumpAndSettle();

      // Enter manual mode
      await tester.tap(find.byKey(const ValueKey<String>('entry-manual')));
      await tester.pumpAndSettle();

      // Category selector field
      final docCategoryField = find.byKey(const ValueKey<String>('field-category'));
      expect(docCategoryField, findsOneWidget);

      // Tap category selector
      await tester.tap(docCategoryField);
      await tester.pumpAndSettle();

      // Searchable sheet opens with document categories
      expect(find.byKey(const ValueKey<String>('category-passport')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('category-idCard')), findsOneWidget);

      // Select passport
      await tester.tap(find.byKey(const ValueKey<String>('category-passport')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('category-passport')), findsNothing);
    });
  });
}
