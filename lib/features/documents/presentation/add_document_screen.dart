import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_searchable_sheet.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_selectable_chip.dart';
import 'package:the_registry/core/widgets/registry_selector_field.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_icons.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_schema.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_card.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/features/documents/widgets/document_digital_pass.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key, this.documentId});

  final String? documentId;

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final AddDocumentController _controller = AddDocumentController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _owner = TextEditingController();
  final TextEditingController _issuer = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _dependency = TextEditingController();
  final TextEditingController _changes = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final Map<String, TextEditingController> _dynamicInputs = {};
  bool _loaded = false;
  bool _missing = false;

  bool get _isEditing => widget.documentId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final id = widget.documentId;
    if (id == null) {
      return;
    }
    final document = RegistryDependencies.of(context).documents.findById(id);
    if (document == null) {
      _missing = true;
      return;
    }
    _controller.loadDocument(document);
    _syncTextControllers();
  }

  void _syncTextControllers() {
    _name.text = _controller.name;
    _owner.text = _controller.ownerName;
    _issuer.text = _controller.issuingAuthority;
    _number.text = _controller.documentNumber;
    _cost.text = _controller.costOfLapsing;
    _dependency.text = _controller.dependency;
    _changes.text = _controller.expectedChanges;
    _notes.text = _controller.notes;
    _syncDynamicControllers();
  }

  void _flushEditors() {
    _controller.setName(_name.text);
    _controller.setOwnerName(_owner.text);
    _controller.setIssuingAuthority(_issuer.text);
    _controller.setDocumentNumber(_number.text);
    _controller.setCostOfLapsing(_cost.text);
    _controller.setDependency(_dependency.text);
    _controller.setExpectedChanges(_changes.text);
    _controller.setNotes(_notes.text);
    for (final entry in _dynamicInputs.entries) {
      _controller.setDynamicFieldValue(entry.key, entry.value.text);
    }
  }

  void _syncDynamicControllers() {
    final ids = {for (final field in _controller.dynamicFields) field.id};
    for (final id in _dynamicInputs.keys.toList()) {
      if (!ids.contains(id)) {
        _dynamicInputs.remove(id)?.dispose();
      }
    }
    for (final field in _controller.dynamicFields) {
      final existing = _dynamicInputs[field.id];
      if (existing == null) {
        _dynamicInputs[field.id] = TextEditingController(text: field.value);
      } else if (existing.text != field.value) {
        existing.text = field.value;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _owner.dispose();
    _issuer.dispose();
    _number.dispose();
    _cost.dispose();
    _dependency.dispose();
    _changes.dispose();
    _notes.dispose();
    for (final controller in _dynamicInputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _isEditing ? l10n.discardChangesTitle : l10n.discardDraftTitle,
          ),
          content: Text(
            _isEditing ? l10n.discardChangesMessage : l10n.discardDraftMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.discardDraftKeep),
            ),
            TextButton(
              key: const ValueKey<String>('discard-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.discardDraftConfirm),
            ),
          ],
        );
      },
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _pickCountry() async {
    final l10n = AppLocalizations.of(context);
    final selected = await RegistrySearchableSheet.show<String>(
      context: context,
      title: l10n.fieldCountry,
      selected: _controller.countryCode,
      options: [
        for (final code in DocumentCountryCodes.all)
          RegistrySearchableOption(
            value: code,
            label: DocumentCopy.country(l10n, code),
            itemKey: 'country-$code',
          ),
      ],
    );
    if (selected != null) {
      if (_controller.ocrStatus == OcrUiStatus.review) {
        _controller.setOcrCountry(selected);
        return;
      }
      _controller.setCountryCode(selected);
      _syncDynamicControllers();
    }
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);
    final selected = await RegistrySearchableSheet.show<DocumentCategory>(
      context: context,
      title: l10n.fieldCategory,
      selected: _controller.category,
      options: [
        for (final category in DocumentCategory.values)
          RegistrySearchableOption(
            value: category,
            label: DocumentCopy.category(l10n, category),
            itemKey: 'category-${category.name}',
          ),
      ],
    );
    if (selected != null) {
      await _applySchema(
        AddDocumentController.schemaIdFor(selected, _controller.countryCode),
        category: selected,
      );
    }
  }

  Future<void> _pickSchema() async {
    final l10n = AppLocalizations.of(context);
    final schemas = AddDocumentController.schemaRegistry.byCountry(
      _controller.countryCode,
    );
    final selected = await RegistrySearchableSheet.show<String>(
      context: context,
      title: l10n.fieldDocumentType,
      selected: _controller.schemaId,
      options: [
        for (final schema in schemas)
          RegistrySearchableOption(
            value: schema.id,
            label: DocumentCopy.schema(l10n, schema.id),
            itemKey: 'schema-${schema.id}',
          ),
      ],
    );
    if (selected != null) {
      if (_controller.ocrStatus == OcrUiStatus.review) {
        _controller.changeOcrSchema(selected);
        return;
      }
      await _applySchema(selected);
    }
  }

  Future<void> _applySchema(
    String schemaId, {
    DocumentCategory? category,
  }) async {
    if (schemaId == _controller.schemaId) {
      if (category != null) {
        _controller.setCategory(category);
      }
      return;
    }
    final l10n = AppLocalizations.of(context);
    var discard = true;
    if (_controller.wouldDiscardDynamicFields(schemaId)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.schemaChangeTitle),
            content: Text(l10n.schemaChangeMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.schemaChangeCancel),
              ),
              TextButton(
                key: const ValueKey<String>('schema-change-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.schemaChangeConfirm),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
    }
    _controller.setSchemaId(schemaId, discardIncompatible: discard);
    if (category != null) {
      _controller.assignCategory(category);
    }
    _controller.upsertUnboundSchemaValues();
    _syncDynamicControllers();
  }

  Future<void> _pickDate(String fieldId) async {
    final deps = RegistryDependencies.of(context);
    final initial = switch (fieldId) {
      'issue' => _controller.issueDate,
      'expiry' => _controller.expiryDate,
      'action' => _controller.actionDate,
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
    switch (fieldId) {
      case 'issue':
        _controller.setIssueDate(picked);
      case 'expiry':
        _controller.setExpiryDate(picked);
      case 'action':
        _controller.setActionDate(picked);
    }
  }

  Future<void> _pickImage({
    required bool fromCamera,
    bool runOcr = true,
  }) async {
    final deps = RegistryDependencies.of(context);
    final l10n = AppLocalizations.of(context);
    final result = fromCamera
        ? await deps.imagePicker.pickFromCamera()
        : await deps.imagePicker.pickFromGallery();
    if (!mounted) {
      return;
    }
    switch (result.status) {
      case ImagePickStatus.success:
        _controller.setAttachment(result.bytes);
        if (runOcr) {
          await _controller.recognizeAttachment(deps.documentOcr);
        }
      case ImagePickStatus.cancelled:
        break;
      case ImagePickStatus.failed:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.attachmentPickerFailed)));
    }
  }

  Future<void> _replaceAttachment({bool runOcr = false}) async {
    final l10n = AppLocalizations.of(context);
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            key: const ValueKey<String>('replace-source-sheet'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.replaceAttachmentTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey<String>('replace-source-camera'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.attachmentTakePhoto),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              ListTile(
                key: const ValueKey<String>('replace-source-gallery'),
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.attachmentChooseGallery),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (fromCamera == null || !mounted) {
      return;
    }
    await _pickImage(fromCamera: fromCamera, runOcr: runOcr);
  }

  Future<void> _save() async {
    _flushEditors();
    final deps = RegistryDependencies.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await _controller.submit(
      l10n: l10n,
      save: deps.documents.save,
      update: deps.documents.update,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  bool _dismissKeyboardIfOpen() {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final editing = FocusManager.instance.primaryFocus is EditableTextState;
    if (insets <= 0 && !editing) {
      return false;
    }
    FocusScope.of(context).unfocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editDocumentTitle)),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: RegistryEmptyState(
            title: l10n.documentUnavailableTitle,
            message: l10n.documentUnavailableMessage,
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        _syncDynamicControllers();
        final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
        return PopScope(
          canPop: !_controller.isDirty && viewInsets <= 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              return;
            }
            if (_dismissKeyboardIfOpen()) {
              return;
            }
            _confirmDiscard();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              titleSpacing: AppSpacing.xs,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_controller.ocrStatus == OcrUiStatus.review
                        ? l10n.ocrOnDeviceEyebrow
                        : l10n.guidedSetup),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _controller.ocrStatus == OcrUiStatus.review
                        ? l10n.ocrReviewTitle
                        : (_isEditing
                              ? l10n.editDocumentTitle
                              : l10n.addDocumentTitle),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    child: _ProgressHeader(controller: _controller),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey<String>('add-document-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                        AppSpacing.screenPadding,
                        AppSpacing.xl,
                      ),
                      child: _body(l10n),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _ActionBar(
              controller: _controller,
              isEditing: _isEditing,
              onBack: () {
                if (_dismissKeyboardIfOpen()) {
                  return;
                }
                if (_controller.step == AddDocumentStep.source &&
                    _controller.ocrStatus != OcrUiStatus.review) {
                  if (_controller.isDirty) {
                    _confirmDiscard();
                  } else {
                    Navigator.of(context).pop(false);
                  }
                  return;
                }
                _controller.backStep();
              },
              onContinue: () {
                _flushEditors();
                if (_controller.ocrStatus == OcrUiStatus.review) {
                  _controller.confirmOcr();
                  _syncTextControllers();
                  return;
                }
                if (_controller.step == AddDocumentStep.review) {
                  _save();
                  return;
                }
                _controller.continueStep(l10n);
                _syncDynamicControllers();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_controller.ocrStatus == OcrUiStatus.processing) {
      return _OcrProcessing(onCancel: _controller.cancelOcr);
    }
    if (_controller.ocrStatus == OcrUiStatus.review) {
      return _OcrReview(
        controller: _controller,
        onSchema: _pickSchema,
        onCategory: _pickCategory,
        onCountry: _pickCountry,
        onRetake: () => _replaceAttachment(runOcr: true),
      );
    }
    return switch (_controller.step) {
      AddDocumentStep.source => _SourceStep(
        controller: _controller,
        onManual: () {
          _controller.goToStep(AddDocumentStep.identity);
          _controller.upsertUnboundSchemaValues();
          _syncDynamicControllers();
        },
        onTakePhoto: () => _pickImage(fromCamera: true, runOcr: true),
        onChooseGallery: () => _pickImage(fromCamera: false, runOcr: true),
        onReplace: () => _replaceAttachment(runOcr: !_controller.isEditing),
        onScanAgain: () => _replaceAttachment(runOcr: true),
        onRemove: () => _controller.setAttachment(null),
        onRetry: () {
          final ocr = RegistryDependencies.of(context).documentOcr;
          _controller.retryOcr(ocr);
        },
      ),
      AddDocumentStep.identity => _IdentityStep(
        controller: _controller,
        name: _name,
        owner: _owner,
        issuer: _issuer,
        number: _number,
        dynamicInputs: _dynamicInputs,
        onPickCountry: _pickCountry,
        onPickCategory: _pickCategory,
        onPickSchema: _pickSchema,
      ),
      AddDocumentStep.dates => _DatesStep(
        controller: _controller,
        onPick: _pickDate,
      ),
      AddDocumentStep.renewal => _RenewalStep(
        controller: _controller,
        cost: _cost,
        dependency: _dependency,
        changes: _changes,
        notes: _notes,
      ),
      AddDocumentStep.review => _ReviewStep(
        controller: _controller,
        onJump: _controller.goToStep,
      ),
    };
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.controller});

  final AddDocumentController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = controller.ocrStatus == OcrUiStatus.review
        ? 1
        : controller.stepIndex + 1;
    return RegistryWizardProgress(
      current: current,
      total: controller.stepCount,
      label: l10n.wizardStepOf(current, controller.stepCount),
      labelKey: const ValueKey<String>('wizard-progress'),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.controller,
    required this.isEditing,
    required this.onBack,
    required this.onContinue,
  });

  final AddDocumentController controller;
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final processing = controller.ocrStatus == OcrUiStatus.processing;
    final reviewing = controller.ocrStatus == OcrUiStatus.review;
    final onReview = controller.step == AddDocumentStep.review && !reviewing;
    final showBack =
        !reviewing && (controller.canGoBack || controller.stepIndex > 0);
    final continueLabel = reviewing
        ? l10n.ocrConfirmContinue
        : onReview
        ? (isEditing ? l10n.saveChanges : l10n.saveDocument)
        : l10n.wizardContinue;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (showBack)
                Expanded(
                  child: RegistrySecondaryButton(
                    key: const ValueKey<String>('wizard-back'),
                    label: l10n.wizardBack,
                    onPressed: processing ? null : onBack,
                  ),
                ),
              if (showBack) const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: RegistryPrimaryButton(
                  key: ValueKey<String>(
                    reviewing
                        ? 'ocr-confirm'
                        : onReview
                        ? 'save-document'
                        : 'wizard-continue',
                  ),
                  label: continueLabel,
                  backgroundColor: scheme.tertiary,
                  foregroundColor: scheme.onTertiary,
                  trailing: reviewing || onReview
                      ? null
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          key: ValueKey<String>('wizard-continue-arrow'),
                          size: 18,
                        ),
                  onPressed: processing || controller.saving
                      ? null
                      : onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceStep extends StatelessWidget {
  const _SourceStep({
    required this.controller,
    required this.onManual,
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.onReplace,
    required this.onScanAgain,
    required this.onRemove,
    required this.onRetry,
  });

  final AddDocumentController controller;
  final VoidCallback onManual;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final VoidCallback onReplace;
  final VoidCallback onScanAgain;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardIntro(
          icon: Icons.document_scanner_outlined,
          title: controller.isEditing
              ? l10n.editDocumentHeadline
              : l10n.addDocumentHeadline,
          body: l10n.howToAddTitle,
        ),
        Text(
          l10n.addDocumentSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (controller.ocrStatus == OcrUiStatus.failed) ...[
          Text(
            key: const ValueKey<String>('ocr-failed'),
            l10n.ocrFailedTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.ocrFailedMessage, style: theme.textTheme.bodyMedium),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey<String>('ocr-retry'),
              onPressed: onRetry,
              child: Text(l10n.ocrRetry),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!controller.hasAttachment) ...[
          _ChoiceCard(
            key: const ValueKey<String>('entry-scan'),
            icon: Icons.document_scanner_outlined,
            title: l10n.scanDocumentTitle,
            subtitle: l10n.scanDocumentSubtitle,
            badge: l10n.scanDocumentRecommended,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                RegistrySecondaryButton(
                  key: const ValueKey<String>('attach-camera'),
                  label: l10n.attachmentTakePhoto,
                  onPressed: onTakePhoto,
                ),
                RegistrySecondaryButton(
                  key: const ValueKey<String>('attach-gallery'),
                  label: l10n.attachmentChooseGallery,
                  onPressed: onChooseGallery,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChoiceCard(
            key: const ValueKey<String>('entry-manual'),
            icon: Icons.edit_outlined,
            title: l10n.enterManuallyTitle,
            subtitle: l10n.enterManuallySubtitle,
            onTap: onManual,
          ),
        ] else
          DocumentAttachmentCard(
            bytes: controller.attachmentBytes,
            onTakePhoto: onTakePhoto,
            onChooseGallery: onChooseGallery,
            onReplace: onReplace,
            onRemove: onRemove,
          ),
        if (controller.hasAttachment) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey<String>('scan-again'),
              onPressed: onScanAgain,
              child: Text(l10n.scanAgain),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        RegistryCallout(message: l10n.ocrPrivacy),
      ],
    );
  }
}

class _WizardIntro extends StatelessWidget {
  const _WizardIntro({required this.title, required this.body, this.icon});

  final IconData? icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDEAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, color: theme.colorScheme.tertiary, size: 22),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.child,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = badge != null;
    return RegistrySurface(
      color: featured ? const Color(0xFFF7F5FF) : null,
      borderColor: featured ? const Color(0xFFBCB6FF) : null,
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RegistryAuraIconTile(
                  icon: icon,
                  size: 45,
                  background: const Color(0xFFEDEBFF),
                  foreground: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (badge != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E6FF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          letterSpacing: 0,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: AppSpacing.md),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.controller,
    required this.name,
    required this.owner,
    required this.issuer,
    required this.number,
    required this.dynamicInputs,
    required this.onPickCountry,
    required this.onPickCategory,
    required this.onPickSchema,
  });

  final AddDocumentController controller;
  final TextEditingController name;
  final TextEditingController owner;
  final TextEditingController issuer;
  final TextEditingController number;
  final Map<String, TextEditingController> dynamicInputs;
  final VoidCallback onPickCountry;
  final VoidCallback onPickCategory;
  final VoidCallback onPickSchema;

  Widget _editorFor(DocumentFieldValue field) {
    return _DynamicFieldEditor(
      key: ValueKey<String>('dynamic-editor-${field.id}'),
      field: field,
      controller:
          dynamicInputs[field.id] ?? TextEditingController(text: field.value),
      onChanged: (value) => controller.setDynamicFieldValue(field.id, value),
      onLabelChanged: field.isCustom
          ? (value) => controller.setDynamicFieldLabel(field.id, value)
          : null,
      onToggleSensitive: () => controller.toggleDynamicFieldSensitive(field.id),
      onRemove: field.isCustom
          ? () => controller.removeDynamicField(field.id)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final extrasOpen = controller.identityExtrasOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardIntro(title: l10n.stepIdentityTitle, body: l10n.identityIntro),
        _SelectedTypeTile(
          schemaLabel: DocumentCopy.schema(l10n, controller.schemaId),
          icon: DocumentIcons.forCategory(
            controller.category ?? DocumentCategory.other,
          ),
          typeLabel: l10n.fieldDocumentType,
          changeLabel: l10n.changeSelection,
          onChange: onPickSchema,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'field-country',
          label: l10n.fieldCountry,
          value: DocumentCopy.country(l10n, controller.countryCode),
          empty: controller.countryCode == null,
          placeholder: l10n.chooseOption,
          onTap: onPickCountry,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'field-category',
          label: l10n.fieldCategory,
          value: controller.category == null
              ? ''
              : DocumentCopy.category(l10n, controller.category!),
          empty: controller.category == null,
          requiredField: true,
          errorText: controller.categoryError,
          placeholder: l10n.chooseOption,
          onTap: onPickCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryTextField(
          label: l10n.fieldDocumentName,
          controller: name,
          fieldKey: const ValueKey<String>('field-name'),
          requiredField: true,
          errorText: controller.nameError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: controller.setName,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryTextField(
          label: l10n.fieldOwnerName,
          controller: owner,
          fieldKey: const ValueKey<String>('field-owner'),
          textCapitalization: TextCapitalization.words,
          onChanged: controller.setOwnerName,
        ),
        for (final field in controller.requiredDynamicFields) ...[
          const SizedBox(height: AppSpacing.md),
          _editorFor(field),
        ],
        const SizedBox(height: AppSpacing.md),
        RegistryExpandableSection(
          toggleKey: const ValueKey<String>('section-identity-extras'),
          title: l10n.identityExtrasTitle,
          subtitle: l10n.identityExtrasSubtitle,
          expanded: extrasOpen,
          onToggle: controller.toggleIdentityExtras,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              RegistryTextField(
                label: l10n.fieldDocumentNumber,
                controller: number,
                fieldKey: const ValueKey<String>('field-number'),
                obscureText: controller.obscureDocumentNumber,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  key: const ValueKey<String>('toggle-number'),
                  tooltip: controller.obscureDocumentNumber
                      ? l10n.showDocumentNumber
                      : l10n.hideDocumentNumber,
                  onPressed: controller.toggleDocumentNumberVisibility,
                  icon: Icon(
                    controller.obscureDocumentNumber
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                onChanged: controller.setDocumentNumber,
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryTextField(
                label: l10n.fieldIssuingAuthority,
                controller: issuer,
                fieldKey: const ValueKey<String>('field-issuer'),
                textCapitalization: TextCapitalization.words,
                onChanged: controller.setIssuingAuthority,
              ),
              for (final field in controller.optionalDynamicFields) ...[
                const SizedBox(height: AppSpacing.md),
                _editorFor(field),
              ],
              const SizedBox(height: AppSpacing.md),
              RegistrySecondaryButton(
                key: const ValueKey<String>('add-custom-field'),
                label: l10n.addCustomField,
                onPressed: () => controller.addCustomField(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.requiredFieldsHint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SelectedTypeTile extends StatelessWidget {
  const _SelectedTypeTile({
    required this.schemaLabel,
    required this.icon,
    required this.typeLabel,
    required this.changeLabel,
    required this.onChange,
  });

  final String schemaLabel;
  final IconData icon;
  final String typeLabel;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RegistryLabeledField(
      key: const ValueKey<String>('field-schema'),
      label: typeLabel,
      child: RegistryFieldSurface(
        onTap: onChange,
        child: Row(
          children: [
            RegistryIconBadge(
              icon: icon,
              size: 40,
              background: const Color(0xFFEDEBFF),
              foreground: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                schemaLabel,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTapTarget,
                  AppSpacing.minTapTarget,
                ),
              ),
              child: Text(changeLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicFieldEditor extends StatefulWidget {
  const _DynamicFieldEditor({
    super.key,
    required this.field,
    required this.controller,
    required this.onChanged,
    required this.onToggleSensitive,
    this.onLabelChanged,
    this.onRemove,
  });

  final DocumentFieldValue field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleSensitive;
  final ValueChanged<String>? onLabelChanged;
  final VoidCallback? onRemove;

  @override
  State<_DynamicFieldEditor> createState() => _DynamicFieldEditorState();
}

class _DynamicFieldEditorState extends State<_DynamicFieldEditor> {
  TextEditingController? _label;
  final FocusNode _labelFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.onLabelChanged != null) {
      _label = TextEditingController(text: widget.field.customLabel ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant _DynamicFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final label = _label;
    final next = widget.field.customLabel ?? '';
    if (label != null && !_labelFocus.hasFocus && label.text != next) {
      label.text = next;
    }
  }

  @override
  void dispose() {
    _label?.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onLabelChanged != null && _label != null)
          RegistryTextField(
            label: l10n.customFieldLabel,
            fieldKey: ValueKey<String>('custom-label-${field.id}'),
            controller: _label,
            focusNode: _labelFocus,
            onChanged: widget.onLabelChanged,
          ),
        if (widget.onLabelChanged != null)
          const SizedBox(height: AppSpacing.sm),
        RegistryTextField(
          label: DocumentCopy.fieldLabel(l10n, field),
          fieldKey: ValueKey<String>('dynamic-${field.id}'),
          controller: widget.controller,
          obscureText: field.sensitive,
          keyboardType: field.isDate
              ? TextInputType.datetime
              : TextInputType.text,
          maxLines: field.isDate || field.sensitive ? 1 : null,
          suffixIcon: IconButton(
            tooltip: l10n.markFieldSensitive,
            onPressed: widget.onToggleSensitive,
            icon: Icon(
              field.sensitive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          onChanged: widget.onChanged,
        ),
        if (widget.onRemove != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: ValueKey<String>('remove-custom-${field.id}'),
              onPressed: widget.onRemove,
              child: Text(l10n.removeCustomField),
            ),
          ),
      ],
    );
  }
}

class _DatesStep extends StatelessWidget {
  const _DatesStep({required this.controller, required this.onPick});

  final AddDocumentController controller;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardIntro(title: l10n.sectionImportantDates, body: l10n.datesIntro),
        DocumentDateField(
          fieldId: 'issue',
          label: l10n.fieldIssueDate,
          value: controller.issueDate,
          errorText: controller.issueDateError,
          onTap: () => onPick('issue'),
        ),
        const SizedBox(height: AppSpacing.md),
        DocumentDateField(
          fieldId: 'expiry',
          label: l10n.fieldExpiryDate,
          value: controller.expiryDate,
          requiredField: true,
          errorText: controller.expiryError,
          onTap: () => onPick('expiry'),
        ),
        const SizedBox(height: AppSpacing.md),
        DocumentDateField(
          fieldId: 'action',
          label: l10n.fieldActionDate,
          value: controller.actionDate,
          helperText: l10n.actionDateHelper,
          errorText: controller.actionDateError,
          onTap: () => onPick('action'),
        ),
        if (controller.suggestedActionDate != null &&
            !controller.actionDateUserSet) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.suggestedActionDate(
              RegistryDateFormatter.dayMonthYear(
                controller.suggestedActionDate!,
                locale,
              ),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey<String>('use-suggested-action'),
              onPressed: controller.applySuggestedActionDate,
              child: Text(l10n.useSuggestedActionDate),
            ),
          ),
        ],
      ],
    );
  }
}

class _RenewalStep extends StatelessWidget {
  const _RenewalStep({
    required this.controller,
    required this.cost,
    required this.dependency,
    required this.changes,
    required this.notes,
  });

  final AddDocumentController controller;
  final TextEditingController cost;
  final TextEditingController dependency;
  final TextEditingController changes;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardIntro(title: l10n.stepRenewalTitle, body: l10n.planningIntro),
        RegistrySurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrySectionHeader(
                icon: Icons.flag_outlined,
                title: l10n.sectionPriorityRenewal,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${l10n.fieldImpact} *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (controller.impactError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    controller.impactError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in DocumentImpact.values)
                    RegistrySelectableChip(
                      key: ValueKey<String>('impact-${value.name}'),
                      label: DocumentCopy.impact(l10n, value),
                      selected: controller.impact == value,
                      selectedColor: _impactContainer(context, value),
                      selectedForegroundColor: _impactForeground(
                        context,
                        value,
                      ),
                      checkmarkColor: _impactForeground(context, value),
                      onSelected: (_) => controller.setImpact(value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.fieldRenewalEffort,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in RenewalEffort.values)
                    RegistrySelectableChip(
                      key: ValueKey<String>('effort-${value.name}'),
                      label: DocumentCopy.effort(l10n, value),
                      selected: controller.renewalEffort == value,
                      onSelected: (selected) =>
                          controller.setRenewalEffort(selected ? value : null),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const ValueKey<String>('section-additional'),
                onTap: controller.toggleAdditional,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: RegistrySectionHeader(
                          icon: Icons.notes_outlined,
                          title: l10n.sectionAdditional,
                        ),
                      ),
                      Icon(
                        controller.additionalOpen
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.additionalOpen) ...[
                const SizedBox(height: AppSpacing.md),
                RegistryTextField(
                  label: l10n.fieldCostOfLapsing,
                  controller: cost,
                  fieldKey: const ValueKey<String>('field-cost'),
                  helperText: l10n.fieldCostHelper,
                  onChanged: controller.setCostOfLapsing,
                ),
                const SizedBox(height: AppSpacing.md),
                RegistryTextField(
                  label: l10n.fieldDependency,
                  controller: dependency,
                  fieldKey: const ValueKey<String>('field-dependency'),
                  helperText: l10n.fieldDependencyHelper,
                  onChanged: controller.setDependency,
                ),
                const SizedBox(height: AppSpacing.md),
                RegistryTextField(
                  label: l10n.fieldExpectedChanges,
                  controller: changes,
                  fieldKey: const ValueKey<String>('field-changes'),
                  maxLines: 3,
                  minLines: 3,
                  onChanged: controller.setExpectedChanges,
                ),
                const SizedBox(height: AppSpacing.md),
                RegistryTextField(
                  label: l10n.fieldNotes,
                  controller: notes,
                  fieldKey: const ValueKey<String>('field-notes'),
                  maxLines: 4,
                  minLines: 3,
                  onChanged: controller.setNotes,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrySectionHeader(
                icon: Icons.notifications_outlined,
                title: l10n.sectionReminders,
                subtitle: l10n.remindersHelper,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                key: const ValueKey<String>('reminder-chips'),
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  RegistrySelectableChip(
                    key: const ValueKey<String>('reminder-action'),
                    label: l10n.reminderOnActionDate,
                    selected: controller.reminders.contains(
                      ReminderPreference.onActionDate,
                    ),
                    onSelected: (_) => controller.toggleReminder(
                      ReminderPreference.onActionDate,
                    ),
                  ),
                  RegistrySelectableChip(
                    key: const ValueKey<String>('reminder-7'),
                    label: l10n.reminder7Days,
                    selected: controller.reminders.contains(
                      ReminderPreference.sevenDaysBefore,
                    ),
                    onSelected: (_) => controller.toggleReminder(
                      ReminderPreference.sevenDaysBefore,
                    ),
                  ),
                  RegistrySelectableChip(
                    key: const ValueKey<String>('reminder-30'),
                    label: l10n.reminder30Days,
                    selected: controller.reminders.contains(
                      ReminderPreference.thirtyDaysBefore,
                    ),
                    onSelected: (_) => controller.toggleReminder(
                      ReminderPreference.thirtyDaysBefore,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _impactContainer(BuildContext context, DocumentImpact impact) {
    final colors = AppStatusColors.of(context);
    return switch (impact) {
      DocumentImpact.low => colors.successContainer,
      DocumentImpact.medium => colors.warningContainer,
      DocumentImpact.high || DocumentImpact.critical => colors.urgentContainer,
    };
  }

  Color _impactForeground(BuildContext context, DocumentImpact impact) {
    final colors = AppStatusColors.of(context);
    return switch (impact) {
      DocumentImpact.low => colors.onSuccessContainer,
      DocumentImpact.medium => colors.onWarningContainer,
      DocumentImpact.high ||
      DocumentImpact.critical => colors.onUrgentContainer,
    };
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller, required this.onJump});

  final AddDocumentController controller;
  final ValueChanged<AddDocumentStep> onJump;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    RegistryDocument? preview;
    try {
      if (controller.category != null &&
          controller.expiryDate != null &&
          controller.impact != null &&
          controller.name.trim().isNotEmpty) {
        preview = controller.toDocument();
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardIntro(
          icon: Icons.check_rounded,
          title: l10n.readyToSave,
          body: l10n.reviewIntro,
        ),
        if (preview != null) DocumentDigitalPass(document: preview),
        const SizedBox(height: AppSpacing.md),
        RegistrySurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(
                label: l10n.fieldDocumentType,
                value: DocumentCopy.schema(l10n, controller.schemaId),
              ),
              _ReviewRow(
                label: l10n.fieldCategory,
                value: controller.category == null
                    ? ''
                    : DocumentCopy.category(l10n, controller.category!),
              ),
              _ReviewRow(
                label: l10n.fieldCountry,
                value: DocumentCopy.country(l10n, controller.countryCode),
              ),
              _ReviewRow(label: l10n.fieldDocumentName, value: controller.name),
              _ReviewRow(label: l10n.ownerLabel, value: controller.ownerName),
              _ReviewRow(
                label: l10n.fieldDocumentNumber,
                value: _mask(controller.documentNumber),
              ),
              _ReviewRow(
                label: l10n.fieldIssueDate,
                value: controller.issueDate == null
                    ? ''
                    : RegistryDateFormatter.dayMonthYear(
                        controller.issueDate!,
                        locale,
                      ),
              ),
              _ReviewRow(
                label: l10n.fieldActionDate,
                value: controller.actionDate == null
                    ? ''
                    : RegistryDateFormatter.dayMonthYear(
                        controller.actionDate!,
                        locale,
                      ),
              ),
              _ReviewRow(
                label: l10n.fieldExpiryDate,
                value: controller.expiryDate == null
                    ? ''
                    : RegistryDateFormatter.dayMonthYear(
                        controller.expiryDate!,
                        locale,
                      ),
              ),
              _ReviewRow(
                label: l10n.fieldImpact,
                value: controller.impact == null
                    ? ''
                    : DocumentCopy.impact(l10n, controller.impact!),
              ),
              if (controller.renewalEffort != null)
                _ReviewRow(
                  label: l10n.fieldRenewalEffort,
                  value: DocumentCopy.effort(l10n, controller.renewalEffort!),
                ),
              _ReviewRow(
                label: l10n.remindersTitle,
                value: controller.reminders.isEmpty
                    ? l10n.noRemindersSelected
                    : controller.reminders
                          .map((item) => DocumentCopy.reminder(l10n, item))
                          .join(', '),
              ),
              _ReviewRow(
                label: l10n.attachmentSectionTitle,
                value: controller.hasAttachment
                    ? l10n.reviewAttachmentYes
                    : l10n.reviewAttachmentNo,
              ),
              _ReviewRow(
                label: l10n.addCustomField,
                value: l10n.reviewDynamicCount(
                  controller.dynamicFields
                      .where((field) => !field.isEmpty)
                      .length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              key: const ValueKey<String>('review-jump-scan'),
              onPressed: () => onJump(AddDocumentStep.source),
              child: Text(l10n.reviewJumpScan),
            ),
            TextButton(
              key: const ValueKey<String>('review-jump-identity'),
              onPressed: () => onJump(AddDocumentStep.identity),
              child: Text(l10n.reviewJumpIdentity),
            ),
            TextButton(
              key: const ValueKey<String>('review-jump-dates'),
              onPressed: () => onJump(AddDocumentStep.dates),
              child: Text(l10n.reviewJumpDates),
            ),
            TextButton(
              key: const ValueKey<String>('review-jump-renewal'),
              onPressed: () => onJump(AddDocumentStep.renewal),
              child: Text(l10n.reviewJumpRenewal),
            ),
          ],
        ),
      ],
    );
  }

  String _mask(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.length <= 4) {
      return '•' * trimmed.length;
    }
    return '${'•' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 4)}';
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _OcrProcessing extends StatelessWidget {
  const _OcrProcessing({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey<String>('ocr-processing'),
      children: [
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD9F5ED), Color(0xFFE9EDFF)],
            ),
          ),
          child: SizedBox(
            height: 145,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.ocrProcessingTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.ocrProcessingMessage,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          key: const ValueKey<String>('ocr-cancel'),
          onPressed: onCancel,
          child: Text(l10n.ocrCancel),
        ),
      ],
    );
  }
}

class _OcrReview extends StatelessWidget {
  const _OcrReview({
    required this.controller,
    required this.onSchema,
    required this.onCategory,
    required this.onCountry,
    required this.onRetake,
  });

  final AddDocumentController controller;
  final VoidCallback onSchema;
  final VoidCallback onCategory;
  final VoidCallback onCountry;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = controller.ocrResult;
    final typeLabel = DocumentCopy.schema(
      l10n,
      result?.classification.schemaId ?? DocumentSchemaIds.genericOther,
    );
    return Column(
      key: const ValueKey<String>('ocr-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ocrReviewTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(l10n.ocrReviewSubtitle, style: theme.textTheme.bodyMedium),
        if (controller.hasAttachment) ...[
          const SizedBox(height: AppSpacing.md),
          RegistrySurface(
            padding: const EdgeInsets.all(AppSpacing.sm),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    controller.attachmentBytes!,
                    height: 72,
                    width: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(typeLabel, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        l10n.ocrFieldsFound(result?.detectedFieldCount ?? 0),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!controller.hasAttachment) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.ocrFieldsFound(result?.detectedFieldCount ?? 0),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'ocr-country',
          label: l10n.fieldCountry,
          value: DocumentCopy.country(l10n, result?.classification.countryCode),
          empty: result == null,
          placeholder: l10n.chooseOption,
          onTap: onCountry,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'ocr-schema',
          label: l10n.fieldDocumentType,
          value: DocumentCopy.schema(
            l10n,
            result?.classification.schemaId ?? DocumentSchemaIds.genericOther,
          ),
          empty: result == null,
          placeholder: l10n.chooseOption,
          onTap: onSchema,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'ocr-category',
          label: l10n.fieldCategory,
          value: DocumentCopy.category(
            l10n,
            result?.classification.category ?? DocumentCategory.other,
          ),
          empty: result == null,
          placeholder: l10n.chooseOption,
          onTap: onCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final field in controller.ocrFields) ...[
          _OcrFieldCard(
            key: ValueKey<String>('ocr-card-${field.id}'),
            field: field,
            onChanged: (value) => controller.setOcrFieldValue(field.id, value),
            onRemove: field.removable
                ? () => controller.removeOcrField(field.id)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        RegistrySecondaryButton(
          key: const ValueKey<String>('ocr-add-field'),
          label: l10n.ocrAddMissingField,
          onPressed: () => controller.addOcrCustomField(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            key: const ValueKey<String>('ocr-retake'),
            style: TextButton.styleFrom(
              minimumSize: const Size(
                AppSpacing.minTapTarget,
                AppSpacing.minTapTarget,
              ),
              foregroundColor: theme.colorScheme.tertiary,
            ),
            onPressed: onRetake,
            child: Text(l10n.ocrRetake),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.ocrNothingSavedHint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _OcrFieldCard extends StatefulWidget {
  const _OcrFieldCard({
    super.key,
    required this.field,
    required this.onChanged,
    this.onRemove,
  });

  final ExtractedDocumentField field;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_OcrFieldCard> createState() => _OcrFieldCardState();
}

class _OcrFieldCardState extends State<_OcrFieldCard> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  var _revealSensitive = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value);
    _focus = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDisplay(force: !_focus.hasFocus);
  }

  @override
  void didUpdateWidget(covariant _OcrFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.value != widget.field.value ||
        oldWidget.field.isDate != widget.field.isDate) {
      _syncDisplay(force: !_focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _displayValue() {
    final field = widget.field;
    if (!field.isDate) {
      return field.value;
    }
    final parsed = AddDocumentController.tryParseLooseDate(field.value);
    if (parsed == null) {
      return field.value;
    }
    return RegistryDateFormatter.dayMonthYear(
      parsed,
      Localizations.localeOf(context).toString(),
    );
  }

  void _syncDisplay({required bool force}) {
    if (!force) {
      return;
    }
    final display = _displayValue();
    if (_controller.text == display) {
      return;
    }
    _controller.value = TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = widget.field;
    final label = field.isCustom
        ? (field.customLabel?.trim().isNotEmpty == true
              ? field.customLabel!
              : l10n.customFieldValue)
        : DocumentCopy.schemaFieldLabel(l10n, field.fieldKey);
    final status = switch (field.confidence) {
      OcrConfidence.high => l10n.fromScan,
      OcrConfidence.review =>
        field.isDate ? l10n.checkThisDate : l10n.ocrReviewField,
      OcrConfidence.notDetected => l10n.ocrConfidenceMissing,
    };
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final inlineChip = !field.sensitive && scale < 1.4;
    final chip = _OcrStatusChip(
      label: status,
      review: field.confidence == OcrConfidence.review,
    );
    return Semantics(
      label: '$label. $status',
      child: RegistryTextField(
        label: label,
        fieldKey: ValueKey<String>('ocr-field-${field.id}'),
        controller: _controller,
        focusNode: _focus,
        obscureText: field.sensitive && !_revealSensitive,
        keyboardType: field.isDate
            ? TextInputType.datetime
            : TextInputType.text,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: AppSpacing.minTapTarget,
        ),
        suffixIcon: inlineChip || field.sensitive
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inlineChip)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: chip,
                    ),
                  if (field.sensitive)
                    IconButton(
                      tooltip: _revealSensitive
                          ? l10n.hideDocumentNumber
                          : l10n.showDocumentNumber,
                      onPressed: () =>
                          setState(() => _revealSensitive = !_revealSensitive),
                      icon: Icon(
                        _revealSensitive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                ],
              )
            : null,
        onChanged: widget.onChanged,
        footer: !inlineChip || widget.onRemove != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!inlineChip) chip,
                    if (widget.onRemove != null)
                      TextButton(
                        onPressed: widget.onRemove,
                        child: Text(l10n.removeCustomField),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _OcrStatusChip extends StatelessWidget {
  const _OcrStatusChip({required this.label, required this.review});

  final String label;
  final bool review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = review
        ? AppColors.warningContainer
        : AppColors.lavenderSurface;
    final foreground = review
        ? const Color(0xFF8A5A00)
        : theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
