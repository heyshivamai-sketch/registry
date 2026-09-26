import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/backup/backup_models.dart';

Future<T> runBackupTask<T>({
  required BuildContext context,
  required String Function(BackupPhase phase) label,
  required Future<T> Function(
    BackupCancelToken cancel,
    void Function(BackupPhase phase) onProgress,
  )
  task,
}) async {
  final cancel = BackupCancelToken();
  final phase = ValueNotifier<BackupPhase>(BackupPhase.protecting);
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _BackupProgressDialog(
        phase: phase,
        label: label,
        onCancel: cancel.cancel,
      );
    },
  );
  unawaited(navigator.push(route));
  try {
    return await task(cancel, (next) {
      phase.value = next;
    });
  } finally {
    if (route.isActive) {
      navigator.removeRoute(route);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phase.dispose();
    });
  }
}

class _BackupProgressDialog extends StatelessWidget {
  const _BackupProgressDialog({
    required this.phase,
    required this.label,
    required this.onCancel,
  });

  final ValueNotifier<BackupPhase> phase;
  final String Function(BackupPhase phase) label;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey<String>('backup-progress'),
        content: ValueListenableBuilder<BackupPhase>(
          valueListenable: phase,
          builder: (context, current, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label(current),
                  key: const ValueKey<String>('backup-progress-label'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  key: const ValueKey<String>('backup-cancel'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.minTapTarget,
                      AppSpacing.minTapTarget,
                    ),
                  ),
                  onPressed: onCancel,
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
