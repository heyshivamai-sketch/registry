import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/platform_backup_file_gateway.dart';

void main() {
  const gatewayBytes = <int>[1, 2, 3, 4];

  test('a missing destination stream is not a saved backup', () async {
    final gateway = PlatformBackupFileGateway(
      androidBridge: _Bridge(
        saveResult: () async => throw PlatformException(code: 'missing_stream'),
      ),
    );

    expect(
      gateway.saveBackup(
        bytes: Uint8List.fromList(gatewayBytes),
        suggestedName: 'registry-backup-2026-09-25.rgry',
      ),
      throwsA(isA<BackupDestinationException>()),
    );
  });

  test('a failed or partial write is not a saved backup', () async {
    final gateway = PlatformBackupFileGateway(
      androidBridge: _Bridge(
        saveResult: () async => throw PlatformException(code: 'write_failed'),
      ),
    );

    expect(
      gateway.saveBackup(
        bytes: Uint8List.fromList(gatewayBytes),
        suggestedName: 'registry-backup-2026-09-25.rgry',
      ),
      throwsA(isA<BackupDestinationException>()),
    );
  });

  test('cancelling the save dialog does not report success', () async {
    final gateway = PlatformBackupFileGateway(
      androidBridge: _Bridge(saveResult: () async => null),
    );

    expect(
      gateway.saveBackup(
        bytes: Uint8List.fromList(gatewayBytes),
        suggestedName: 'registry-backup-2026-09-25.rgry',
      ),
      throwsA(isA<BackupCancelled>()),
    );
  });

  test(
    'save completes only when the bridge confirms the destination',
    () async {
      final bridge = _Bridge(saveResult: () async => true);
      final gateway = PlatformBackupFileGateway(androidBridge: bridge);

      await gateway.saveBackup(
        bytes: Uint8List.fromList(gatewayBytes),
        suggestedName: 'registry-backup-2026-09-25.rgry',
      );

      expect(bridge.savedNames, ['registry-backup-2026-09-25.rgry']);
      expect(bridge.savedBytes.single, gatewayBytes);
    },
  );

  test(
    'an oversized content selection fails before any bytes are returned',
    () async {
      var returned = false;
      final gateway = PlatformBackupFileGateway(
        androidBridge: _Bridge(
          pickResult: () async => throw PlatformException(code: 'oversized'),
        ),
      );

      await expectLater(
        gateway.pickBackup().then((bytes) {
          returned = bytes != null;
          return bytes;
        }),
        throwsA(isA<BackupOversized>()),
      );
      expect(returned, isFalse);
    },
  );

  test(
    'bytes longer than the limit are rejected even if the bridge returns them',
    () async {
      final gateway = PlatformBackupFileGateway(
        androidBridge: _Bridge(
          pickResult: () async =>
              Uint8List(BackupLimits.maxBackupFileBytes + 1),
        ),
      );

      expect(gateway.pickBackup(), throwsA(isA<BackupOversized>()));
    },
  );
}

class _Bridge implements AndroidBackupBridge {
  _Bridge({this.saveResult, this.pickResult});

  final Future<bool?> Function()? saveResult;
  final Future<Uint8List?> Function()? pickResult;
  final savedNames = <String>[];
  final savedBytes = <List<int>>[];

  @override
  Future<bool?> save({required Uint8List bytes, required String name}) {
    savedNames.add(name);
    savedBytes.add(Uint8List.fromList(bytes));
    return saveResult!();
  }

  @override
  Future<Uint8List?> pick({required int maxBytes}) {
    expect(maxBytes, BackupLimits.maxBackupFileBytes);
    return pickResult!();
  }
}
