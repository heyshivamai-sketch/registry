import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/launch_config.dart';
import 'package:the_registry/features/app_lock/privacy_flag.dart';
import 'package:the_registry/features/backup/backup_crypto.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_payload.dart';
import 'package:the_registry/features/backup/platform_backup_file_gateway.dart';
import 'package:the_registry/l10n/app_localizations.dart';

void main() {
  group('Regiday copy', () {
    for (final code in ['en', 'fr', 'ar']) {
      test('$code names the app Regiday and the upgrade Regiday Pro', () {
        final l10n = lookupAppLocalizations(Locale(code));
        expect(l10n.localProTitle, 'Regiday Pro');
        expect(l10n.appLockPrivacyCover, 'Regiday');
        expect(l10n.notificationTitle, contains('Regiday'));
        expect(l10n.notificationChannelName, contains('Regiday'));
        expect(l10n.localProIntro, contains('Regiday'));
        expect(l10n.profileMessage, contains('Regiday Pro'));
      });

      test('$code has no old brand names in user-facing strings', () {
        final arb =
            jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
                as Map<String, dynamic>;
        // Generic "your registry" wording is kept on purpose.
        const generic = {
          'homeTitle',
          'sectionRegistrySnapshot',
          'subscriptionReviewIntro',
        };
        for (final MapEntry(:key, :value) in arb.entries) {
          if (key.startsWith('@') || value is! String) continue;
          expect(value, isNot(contains('Local Pro')), reason: key);
          if (!generic.contains(key)) {
            expect(value, isNot(matches(RegExp(r'\bRegistry\b'))), reason: key);
          }
          expect(value, isNot(contains('verified email')), reason: key);
        }
      });
    }

    test('English upgrade copy is one-time and not a subscription', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.localProIntro, contains('one-time upgrade'));
      expect(l10n.localProIntro, contains('not a subscription'));
    });
  });

  group('persisted identifiers survive the rebrand', () {
    test('product id, backup format, and method channels are unchanged', () {
      expect(LaunchConfig.localProProductId, 'local_pro');
      expect(RegistryBackupCrypto.magic, [0x52, 0x47, 0x52, 0x59]);
      expect(RegistryBackupCrypto.containerVersion, 1);
      expect(RegistryBackupPayload.magic, [0x52, 0x47, 0x50, 0x59]);
      expect(RegistryBackupPayload.version, 2);
      expect(PlatformPrivacyFlag.channelName, 'com.residay.app/privacy');
      expect(
        MethodChannelAndroidBackupBridge.channel.name,
        'com.residay.app/backup_file',
      );
    });

    test('a .rgry file made before the rebrand still decrypts', () async {
      // Made by tool/phase2a_qa_fixtures.dart on 27 September 2026.
      final file = File(
        'test/fixtures/phase2a_qa_exact_free_limit.rgry',
      ).readAsBytesSync();
      final payload = await RegistryBackupCrypto.decrypt(
        file: file,
        password: 'phase2a-qa-password',
        cancel: BackupCancelToken(),
      );
      final snapshot = RegistryBackupPayload.decode(payload);
      expect(snapshot.documents, hasLength(10));
      expect(snapshot.subscriptions, hasLength(5));
      expect(snapshot.attachmentCount, 10);
    });
  });
}
