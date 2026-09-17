import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_selectable_chip.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/add_document_controller.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_card.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final AddDocumentController _controller = AddDocumentController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.discardDraftTitle),
          content: Text(l10n.discardDraftMessage),
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

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<DocumentCategory>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.fieldDocumentType,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final category in DocumentCategory.values)
                ListTile(
                  key: ValueKey<String>('category-${category.name}'),
                  title: Text(DocumentCopy.category(l10n, category)),
                  selected: _controller.category == category,
                  onTap: () => Navigator.of(sheetContext).pop(category),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      _controller.setCategory(selected);
    }
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

  Future<void> _pickImage({required bool fromCamera}) async {
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
      case ImagePickStatus.cancelled:
        break;
      case ImagePickStatus.failed:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.attachmentPickerFailed)));
    }
  }

  Future<void> _replaceAttachment() async {
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
    await _pickImage(fromCamera: fromCamera);
  }

  Future<void> _save() async {
    final deps = RegistryDependencies.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await _controller.submit(
      l10n: l10n,
      save: deps.documents.save,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _confirmDiscard();
            }
          },
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.addDocumentTitle)),
            body: SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey<String>('add-document-scroll'),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.addDocumentHeadline,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.addDocumentSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    DocumentAttachmentCard(
                      bytes: _controller.attachmentBytes,
                      onTakePhoto: () => _pickImage(fromCamera: true),
                      onChooseGallery: () => _pickImage(fromCamera: false),
                      onReplace: _replaceAttachment,
                      onRemove: () => _controller.setAttachment(null),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    RegistrySectionHeader(title: l10n.sectionBasicInfo),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const ValueKey<String>('field-name'),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: '${l10n.fieldDocumentName} *',
                        errorText: _controller.nameError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      button: true,
                      label: l10n.fieldDocumentType,
                      child: InkWell(
                        key: const ValueKey<String>('field-category'),
                        onTap: _pickCategory,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          isEmpty: _controller.category == null,
                          decoration: InputDecoration(
                            labelText: '${l10n.fieldDocumentType} *',
                            errorText: _controller.categoryError,
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            _controller.category == null
                                ? l10n.fieldDocumentType
                                : DocumentCopy.category(
                                    l10n,
                                    _controller.category!,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-owner'),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.fieldOwnerName,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setOwnerName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-issuer'),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.fieldIssuingAuthority,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setIssuingAuthority,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-number'),
                      obscureText: _controller.obscureDocumentNumber,
                      decoration: InputDecoration(
                        labelText: l10n.fieldDocumentNumber,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          key: const ValueKey<String>('toggle-number'),
                          tooltip: _controller.obscureDocumentNumber
                              ? l10n.showDocumentNumber
                              : l10n.hideDocumentNumber,
                          onPressed: _controller.toggleDocumentNumberVisibility,
                          icon: Icon(
                            _controller.obscureDocumentNumber
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onChanged: _controller.setDocumentNumber,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    RegistrySectionHeader(title: l10n.sectionImportantDates),
                    const SizedBox(height: AppSpacing.sm),
                    DocumentDateField(
                      fieldId: 'issue',
                      label: l10n.fieldIssueDate,
                      value: _controller.issueDate,
                      errorText: _controller.issueDateError,
                      onTap: () => _pickDate('issue'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DocumentDateField(
                      fieldId: 'expiry',
                      label: l10n.fieldExpiryDate,
                      value: _controller.expiryDate,
                      requiredField: true,
                      errorText: _controller.expiryError,
                      onTap: () => _pickDate('expiry'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DocumentDateField(
                      fieldId: 'action',
                      label: l10n.fieldActionDate,
                      value: _controller.actionDate,
                      helperText: l10n.actionDateHelper,
                      errorText: _controller.actionDateError,
                      onTap: () => _pickDate('action'),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    RegistrySectionHeader(title: l10n.sectionPriorityRenewal),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${l10n.fieldImpact} *',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_controller.impactError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          _controller.impactError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                            selected: _controller.impact == value,
                            selectedColor: _impactContainer(context, value),
                            selectedForegroundColor: _impactForeground(
                              context,
                              value,
                            ),
                            checkmarkColor: _impactForeground(context, value),
                            onSelected: (_) => _controller.setImpact(value),
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
                            selected: _controller.renewalEffort == value,
                            onSelected: (selected) => _controller
                                .setRenewalEffort(selected ? value : null),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-cost'),
                      decoration: InputDecoration(
                        labelText: l10n.fieldCostOfLapsing,
                        helperText: l10n.fieldCostHelper,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setCostOfLapsing,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-dependency'),
                      decoration: InputDecoration(
                        labelText: l10n.fieldDependency,
                        helperText: l10n.fieldDependencyHelper,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setDependency,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-changes'),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.fieldExpectedChanges,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setExpectedChanges,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const ValueKey<String>('field-notes'),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.fieldNotes,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _controller.setNotes,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    RegistrySectionHeader(
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
                          selected: _controller.reminders.contains(
                            ReminderPreference.onActionDate,
                          ),
                          onSelected: (_) => _controller.toggleReminder(
                            ReminderPreference.onActionDate,
                          ),
                        ),
                        RegistrySelectableChip(
                          key: const ValueKey<String>('reminder-7'),
                          label: l10n.reminder7Days,
                          selected: _controller.reminders.contains(
                            ReminderPreference.sevenDaysBefore,
                          ),
                          onSelected: (_) => _controller.toggleReminder(
                            ReminderPreference.sevenDaysBefore,
                          ),
                        ),
                        RegistrySelectableChip(
                          key: const ValueKey<String>('reminder-30'),
                          label: l10n.reminder30Days,
                          selected: _controller.reminders.contains(
                            ReminderPreference.thirtyDaysBefore,
                          ),
                          onSelected: (_) => _controller.toggleReminder(
                            ReminderPreference.thirtyDaysBefore,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Material(
              elevation: 3,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: RegistryPrimaryButton(
                      key: const ValueKey<String>('save-document'),
                      label: l10n.saveDocument,
                      onPressed: _controller.saving ? null : _save,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
