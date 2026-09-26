import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/presentation/backup_task.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ExportBackupScreen extends StatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;
  var _working = false;
  String? _passwordError;
  String? _confirmError;
  String? _status;
  var _statusIsError = false;

  @override
  void dispose() {
    _password.clear();
    _confirm.clear();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final password = _password.text;
    final confirm = _confirm.text;
    String? passwordError;
    String? confirmError;
    if (password.length < BackupLimits.minPasswordLength ||
        password.length > BackupLimits.maxPasswordLength) {
      passwordError = l10n.backupPasswordTooShort;
    }
    if (password != confirm) {
      confirmError = l10n.backupPasswordMismatch;
    }
    if (passwordError != null || confirmError != null) {
      setState(() {
        _passwordError = passwordError;
        _confirmError = confirmError;
        _status = null;
      });
      return;
    }
    setState(() {
      _working = true;
      _passwordError = null;
      _confirmError = null;
      _status = null;
    });
    final backups = RegistryDependencies.of(context).backups;
    try {
      await runBackupTask<void>(
        context: context,
        label: (phase) => _phaseLabel(l10n, phase),
        task: (cancel, onProgress) {
          return backups.exportBackup(
            password: password,
            cancel: cancel,
            onProgress: onProgress,
          );
        },
      );
      if (!mounted) {
        return;
      }
      _password.clear();
      _confirm.clear();
      setState(() {
        _status = l10n.backupExportSaved;
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
    return switch (error) {
      BackupCancelled() => l10n.backupExportCancelled,
      BackupInsufficientStorage() => l10n.backupExportStorage,
      BackupOversized() => l10n.backupExportTooLarge,
      BackupDestinationException() => l10n.backupExportNotSaved,
      _ => l10n.backupExportFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = _status;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.backupExportTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.backupIncluded, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.backupPasswordWarning,
                    key: const ValueKey<String>('backup-password-warning'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RegistryTextField(
              fieldKey: const ValueKey<String>('export-password'),
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
              textInputAction: TextInputAction.next,
              suffixIcon: _visibilityButton(l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            RegistryTextField(
              fieldKey: const ValueKey<String>('export-confirm-password'),
              label: l10n.backupConfirmPasswordLabel,
              controller: _confirm,
              requiredField: true,
              obscureText: _obscure,
              enabled: !_working,
              errorText: _confirmError,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              autofillHints: const [],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _working ? null : _export(),
            ),
            const SizedBox(height: AppSpacing.lg),
            RegistryPrimaryButton(
              key: const ValueKey<String>('export-save'),
              label: l10n.backupChooseSave,
              onPressed: _working ? null : _export,
            ),
            if (status != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                status,
                key: const ValueKey<String>('export-status'),
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

  Widget _visibilityButton(AppLocalizations l10n) {
    return IconButton(
      key: const ValueKey<String>('export-password-visibility'),
      tooltip: _obscure ? l10n.backupShowPassword : l10n.backupHidePassword,
      onPressed: _working ? null : () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}
