import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/features/documents/domain/document_renewal.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class RecordRenewalSheet {
  static Future<void> show(BuildContext context, RegistryDocument document) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _RecordRenewalForm(document: document),
        );
      },
    );
  }
}

class _RecordRenewalForm extends StatefulWidget {
  const _RecordRenewalForm({required this.document});

  final RegistryDocument document;

  @override
  State<_RecordRenewalForm> createState() => _RecordRenewalFormState();
}

class _RecordRenewalFormState extends State<_RecordRenewalForm> {
  late DateTime _renewedOn;
  DateTime? _newExpiry;
  DateTime? _newActionDate;
  final TextEditingController _note = TextEditingController();
  String? _expiryError;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _renewedOn = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(String fieldId) async {
    final deps = RegistryDependencies.of(context);
    final initial = switch (fieldId) {
      'renewal' => _renewedOn,
      'new-expiry' => _newExpiry,
      'new-action' => _newActionDate,
      _ => null,
    };
    final picked = await deps.datePicker.pickDate(
      context,
      fieldId: fieldId,
      initialDate: initial,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      switch (fieldId) {
        case 'renewal':
          _renewedOn = picked;
        case 'new-expiry':
          _newExpiry = picked;
        case 'new-action':
          _newActionDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _expiryError = _newExpiry == null ? l10n.errorNewExpiryRequired : null;
      _actionError = null;
      if (_newExpiry != null &&
          !DocumentRenewal.isNewExpiryValid(
            previousExpiry: widget.document.expiryDate,
            newExpiry: _newExpiry!,
          )) {
        _expiryError = l10n.errorNewExpiryNotAfterPrevious;
      }
      if (_newExpiry != null &&
          !DocumentRenewal.isActionDateValid(
            newExpiry: _newExpiry!,
            actionDate: _newActionDate,
          )) {
        _actionError = l10n.errorActionAfterNewExpiry;
      }
    });
    if (_expiryError != null || _actionError != null) {
      return;
    }
    final updated = DocumentRenewal.record(
      document: widget.document,
      renewedOn: _renewedOn,
      newExpiryDate: _newExpiry!,
      newActionDate: _newActionDate,
      note: _note.text,
    );
    final saved = await RegistryDependencies.of(
      context,
    ).documents.update(updated);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    if (saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.renewalRecorded)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.recordRenewal,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.recordRenewalSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentDateField(
              fieldId: 'renewal',
              label: l10n.renewalDate,
              value: _renewedOn,
              requiredField: true,
              onTap: () => _pick('renewal'),
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentDateField(
              fieldId: 'previous-expiry',
              label: l10n.previousExpiry,
              value: widget.document.expiryDate,
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentDateField(
              fieldId: 'new-expiry',
              label: l10n.newExpiry,
              value: _newExpiry,
              requiredField: true,
              errorText: _expiryError,
              onTap: () => _pick('new-expiry'),
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentDateField(
              fieldId: 'new-action',
              label: l10n.optionalNewActionDate,
              value: _newActionDate,
              errorText: _actionError,
              onTap: () => _pick('new-action'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey<String>('renewal-note'),
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.renewalNoteOptional,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RegistryPrimaryButton(
              key: const ValueKey<String>('save-renewal'),
              label: l10n.saveRenewal,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
