import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_form_field.dart';
import '../../../core/widgets/registry_primary_button.dart';
import '../../../core/widgets/registry_surface.dart';
import '../backup_models.dart';
import 'backup_task.dart';
import '../../../l10n/app_localizations.dart';

class ImportBackupScreen extends StatefulWidget {
  const ImportBackupScreen({super.key, this.initialBytes, this.initialFileName});

  final Uint8List? initialBytes;
  final String? initialFileName;

  @override
  State<ImportBackupScreen> createState() => _ImportBackupScreenState();
}

class _ImportBackupScreenState extends State<ImportBackupScreen> {
  final _password = TextEditingController();
  Uint8List? _bytes;
  String? _fileName;
  OpenedBackup? _opened;
  var _obscure = true;
  var _working = false;
  String? _passwordError;
  String? _status;
  var _statusIsError = false;
  var _secretsReleased = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBytes;
    if (initial != null) {
      _bytes = initial;
      _fileName = widget.initialFileName ?? 'Backup file';
    }
  }

  @override
  void dispose() {
    _releaseSecrets();
    _password.dispose();
    super.dispose();
  }

  void _releaseSecrets() {
    if (_secretsReleased) {
      return;
    }
    _secretsReleased = true;
    _clearOpened();
    _password.clear();
    final bytes = _bytes;
    _bytes = null;
    if (bytes != null) {
      try {
        bytes.fillRange(0, bytes.length, 0);
      } on UnsupportedError {
        // Some picked buffers cannot be overwritten. The reference is gone.
      }
    }
    _fileName = null;
    _passwordError = null;
    _status = null;
  }

  void _clearOpened() {
    final opened = _opened;
    if (opened != null && !opened.consumed) {
      opened.wipeAttachments();
    }
    _opened = null;
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final files = RegistryDependencies.of(context).backupFiles;
    setState(() {
      _working = true;
      _status = null;
    });
    try {
      final bytes = await files.pickBackup();
      if (!mounted) {
        return;
      }
      if (bytes == null) {
        setState(() => _status = l10n.backupImportCancelled);
        return;
      }
      _clearOpened();
      setState(() {
        _bytes = bytes;
        _fileName = bytes.length > 1024
            ? '${l10n.backupSelectedFile} (${(bytes.length / 1024).toStringAsFixed(1)} KB)'
            : l10n.backupSelectedFile;
        _status = null;
        _statusIsError = false;
      });
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _message(l10n, error);
        _statusIsError = error is! BackupCancelled;
      });
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context);
    final bytes = _bytes;
    FocusManager.instance.primaryFocus?.unfocus();
    if (bytes == null) {
      setState(() {
        _status = l10n.backupNoFile;
        _statusIsError = true;
      });
      return;
    }
    final password = _password.text;
    if (password.length < BackupLimits.minPasswordLength || password.length > BackupLimits.maxPasswordLength) {
      setState(() => _passwordError = l10n.backupPasswordTooShort);
      return;
    }
    setState(() {
      _working = true;
      _passwordError = null;
      _status = null;
    });
    final backups = RegistryDependencies.of(context).backups;
    try {
      final opened = await runBackupTask<OpenedBackup>(
        context: context,
        label: (phase) => _phaseLabel(l10n, phase),
        task: (cancel, onProgress) {
          return backups.openBackup(bytes: bytes, password: password, cancel: cancel, onProgress: onProgress);
        },
      );
      if (!mounted) {
        if (!opened.consumed) {
          opened.wipeAttachments();
        }
        return;
      }
      _clearOpened();
      setState(() {
        _opened = opened;
        _status = null;
      });
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }
      _clearOpened();
      setState(() {
        _status = _message(l10n, error);
        _statusIsError = error is! BackupCancelled;
      });
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _replace() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final opened = _opened;
    if (opened == null || _working) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 36),
          title: Text(l10n.backupReplaceTitle, textAlign: TextAlign.center),
          content: Text(l10n.backupReplaceBody, textAlign: TextAlign.center),
          actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          actions: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey<String>('import-replace-cancel'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(l10n.backupCancel, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey<String>('import-replace-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Replace', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      if (mounted && confirmed == false) {
        setState(() {
          _status = l10n.backupImportCancelled;
          _statusIsError = false;
        });
      }
      return;
    }
    setState(() {
      _working = true;
      _status = null;
    });
    final backups = RegistryDependencies.of(context).backups;
    try {
      await runBackupTask<void>(
        context: context,
        label: (phase) => _phaseLabel(l10n, phase),
        task: (cancel, onProgress) {
          return backups.restoreBackup(opened: opened, cancel: cancel, onProgress: onProgress);
        },
      );
      if (!mounted) {
        return;
      }
      await RegistryDependencies.of(context).reminders.reconcile();
      if (!mounted) {
        return;
      }
      _releaseSecrets();
      Navigator.of(context).pop(true);
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _message(l10n, error);
        _statusIsError = error is! BackupCancelled;
      });
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  String _phaseLabel(AppLocalizations l10n, BackupPhase phase) {
    return switch (phase) {
      BackupPhase.protecting => l10n.backupPhaseProtecting,
      BackupPhase.writing => l10n.backupPhaseWriting,
      BackupPhase.checking => l10n.backupPhaseChecking,
      BackupPhase.restoring => l10n.backupPhaseRestoring,
    };
  }

  String _message(AppLocalizations l10n, BackupException error) {
    final detail = switch (error) {
      BackupCancelled() => l10n.backupImportCancelled,
      BackupWrongPassword() => l10n.backupWrongPassword,
      BackupUnsupportedVersion() => l10n.backupUnsupportedVersion,
      BackupTampered() => l10n.backupTampered,
      BackupOversized() => l10n.backupImportTooLarge,
      BackupInsufficientStorage() => l10n.backupImportStorage,
      BackupInvalid() => l10n.backupInvalidFile,
      BackupRestoreFailed() => l10n.backupImportFailed,
      _ => l10n.backupInvalidFile,
    };
    if (error is BackupCancelled) {
      return detail;
    }
    return '$detail ${l10n.backupImportUnchanged}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final opened = _opened;
    final status = _status;
    final hasFile = _bytes != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.backupImportTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
          children: [
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistryIconBadge(
                    icon: Icons.settings_backup_restore_rounded,
                    background: colorScheme.primaryContainer,
                    foreground: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Restore Registry', style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(l10n.backupImportIntro, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!hasFile)
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.folder_open_outlined, color: colorScheme.primary, size: 26),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No file selected', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Choose an encrypted .rgry backup file from this device',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      key: const ValueKey<String>('import-pick'),
                      onPressed: _working ? null : _pick,
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(l10n.backupChooseFile),
                    ),
                  ],
                ),
              )
            else
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColors.successContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: statusColors.success, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? l10n.backupSelectedFile,
                            key: const ValueKey<String>('import-file-name'),
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 13, color: statusColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Backup file loaded',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: statusColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton(
                      key: const ValueKey<String>('import-pick'),
                      onPressed: _working ? null : _pick,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup password', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Enter the password used when exporting this backup.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  RegistryTextField(
                    fieldKey: const ValueKey<String>('import-password'),
                    label: l10n.backupPasswordLabel,
                    controller: _password,
                    requiredField: true,
                    obscureText: _obscure,
                    enabled: !_working,
                    errorText: _passwordError,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    autofillHints: const [],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_working && _opened == null) {
                        _check();
                      }
                    },
                    onChanged: (_) {
                      if (_opened != null) {
                        _clearOpened();
                        setState(() {});
                      }
                    },
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.backupShowPassword : l10n.backupHidePassword,
                      onPressed: _working ? null : () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (opened == null) ...[
              RegistryPrimaryButton(
                key: const ValueKey<String>('import-check'),
                label: l10n.backupCheckAction,
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onPressed: _working ? null : _check,
              ),
            ],
            if (opened != null) ...[
              RegistrySurface(
                key: const ValueKey<String>('import-preview'),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: statusColors.successContainer, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, size: 16, color: statusColors.success),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backup verified',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: statusColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text('Review contents before restoring', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _BackupMetricTile(
                            icon: Icons.description_outlined,
                            count: opened.preview.documents,
                            label: opened.preview.documents == 1 ? 'Document' : 'Documents',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _BackupMetricTile(
                            icon: Icons.autorenew_rounded,
                            count: opened.preview.subscriptions,
                            label: opened.preview.subscriptions == 1 ? 'Subscription' : 'Subscriptions',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _BackupMetricTile(
                            icon: Icons.photo_library_outlined,
                            count: opened.preview.attachments,
                            label: opened.preview.attachments == 1 ? 'Image' : 'Images',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const RegistryCallout(
                      tone: RegistryCalloutTone.warning,
                      title: 'Replaces current registry',
                      message:
                          'Restoring will replace all documents and subscriptions on this device. Records cannot be merged.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryPrimaryButton(
                key: const ValueKey<String>('import-replace'),
                label: l10n.backupReplaceAction,
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                trailing: const Icon(Icons.warning_amber_rounded, size: 18),
                onPressed: _working ? null : _replace,
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _statusIsError ? statusColors.urgentContainer : statusColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _statusIsError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                        color: _statusIsError ? statusColors.urgent : statusColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          status,
                          key: const ValueKey<String>('import-status'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _statusIsError ? statusColors.onUrgentContainer : statusColors.onWarningContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackupMetricTile extends StatelessWidget {
  const _BackupMetricTile({required this.icon, required this.count, required this.label});

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.xxs),
          Text('$count', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
