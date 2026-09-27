import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/app_lock/device_authenticator.dart';
import 'package:the_registry/features/backup/presentation/profile_screen.dart';
import 'package:the_registry/features/app_lock/privacy_flag.dart';
import 'package:the_registry/features/csv_import/csv_file_gateway.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/verified_entitlement.dart';

class ScriptedDeviceAuthenticator implements DeviceAuthenticator {
  DeviceAuthAvailability availabilityResult = DeviceAuthAvailability.ready;
  DeviceAuthAttempt authenticateResult = DeviceAuthAttempt.authenticated;
  var authenticateCalls = 0;
  String? lastReason;
  bool? enabledDuringAuthenticate;
  bool Function()? readEnabled;

  @override
  Future<DeviceAuthAvailability> availability() async => availabilityResult;

  @override
  Future<DeviceAuthAttempt> authenticate({
    required String localizedReason,
  }) async {
    authenticateCalls += 1;
    lastReason = localizedReason;
    enabledDuringAuthenticate = readEnabled?.call();
    return authenticateResult;
  }
}

class RecordingPrivacyFlag implements PrivacyFlag {
  var secure = false;
  var calls = 0;

  @override
  Future<void> setSecure(bool secure) async {
    calls += 1;
    this.secure = secure;
  }
}

class ScriptedStoreProductSource implements StoreProductSource {
  ScriptedStoreProductSource(this.listing);

  final StoreListing? listing;

  @override
  Future<StoreListing?> loadLocalPro() async => listing;
}

class ScriptedPurchaseService implements PurchaseService {
  ScriptedPurchaseService({this.proof});

  final VerifiedEntitlementProof? proof;
  var calls = 0;

  @override
  Future<PurchaseAttempt> purchaseLocalPro() async {
    calls += 1;
    return PurchaseAttempt(proof: proof);
  }
}

Future<void> tapProfileControl(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  final scrollable = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.byType(Scrollable),
  );
  final target = find.byKey(key);
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  for (var attempt = 0; attempt < 8; attempt++) {
    if (tester.getCenter(target).dy < 420) {
      break;
    }
    await tester.drag(scrollable, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class ScriptedCsvFileGateway implements CsvFileGateway {
  ScriptedCsvFileGateway(this.bytes);

  Uint8List? bytes;
  var calls = 0;

  @override
  Future<Uint8List?> pickCsv() async {
    calls += 1;
    return bytes;
  }
}
