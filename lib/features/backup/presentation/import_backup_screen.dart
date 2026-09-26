import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/presentation/backup_task.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ImportBackupScreen extends StatefulWidget {
  const ImportBackupScreen({super.key});

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

  @override
  void dispose() {
    _clearOpened();
    _password.clear();
    _password.dispose();
    _bytes = null;
    super.dispose();
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
        _fileName = l10n.backupSelectedFile;
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
    if (password.length < BackupLimits.minPasswordLength ||
        password.length > BackupLimits.maxPasswordLength) {
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
          return backups.openBackup(
            bytes: bytes,
            password: password,
            cancel: cancel,
            onProgress: onProgress,
          );
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
    final opened = _opened;
    if (opened == null || _working) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.backupReplaceTitle),
          content: Text(l10n.backupReplaceBody),
          actions: [
            TextButton(
              key: const ValueKey<String>('import-replace-cancel'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTapTarget,
                  AppSpacing.minTapTarget,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.backupCancel),
            ),
            TextButton(
              key: const ValueKey<String>('import-replace-confirm'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTapTarget,
                  AppSpacing.minTapTarget,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.backupReplaceAction),
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
          return backups.restoreBackup(
            opened: opened,
            cancel: cancel,
            onProgress: onProgress,
          );
        },
      );
      if (!mounted) {
        return;
      }
      _password.clear();
      setState(() {
        _status = l10n.backupImportReplaced;
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
    final opened = _opened;
    final status = _status;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.backupImportTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(l10n.backupImportIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const ValueKey<String>('import-pick'),
              onPressed: _working ? null : _pick,
              child: Text(l10n.backupChooseFile, textAlign: TextAlign.center),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _fileName!,
                key: const ValueKey<String>('import-file-name'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
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
              onChanged: (_) {
                if (_opened != null) {
                  _clearOpened();
                  setState(() {});
                }
              },
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? l10n.backupShowPassword
                    : l10n.backupHidePassword,
                onPressed: _working
                    ? null
                    : () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RegistryPrimaryButton(
              key: const ValueKey<String>('import-check'),
              label: l10n.backupCheckAction,
              onPressed: _working ? null : _check,
            ),
            if (opened != null) ...[
              const SizedBox(height: AppSpacing.lg),
              RegistrySurface(
                key: const ValueKey<String>('import-preview'),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.backupPreview(
                    opened.preview.documents,
                    opened.preview.subscriptions,
                    opened.preview.attachments,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryPrimaryButton(
                key: const ValueKey<String>('import-replace'),
                label: l10n.backupReplaceAction,
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                onPressed: _working ? null : _replace,
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                status,
                key: const ValueKey<String>('import-status'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _statusIsError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
