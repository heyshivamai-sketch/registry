import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/presentation/record_renewal_sheet.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_preview_page.dart';
import 'package:the_registry/features/documents/widgets/document_digital_pass.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = RegistryDependencies.of(context).documents;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final document = repository.findById(documentId);
        if (document == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.documentDetailsTitle)),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: RegistryEmptyState(
                key: const ValueKey<String>('document-unavailable'),
                title: l10n.documentUnavailableTitle,
                message: l10n.documentUnavailableMessage,
              ),
            ),
          );
        }
        return _DocumentDetailBody(document: document);
      },
    );
  }
}

class _DocumentDetailBody extends StatelessWidget {
  const _DocumentDetailBody({required this.document});

  final RegistryDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final history = _sortedHistory(document.renewalHistory);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.xs,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.documentPassEyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
            Text(l10n.documentPassTitle, style: theme.textTheme.titleLarge),
          ],
        ),
        actions: [
          SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: PopupMenuButton<String>(
              key: const ValueKey<String>('document-actions'),
              tooltip: l10n.moreActions,
              onSelected: (value) {
                if (value == 'edit') {
                  AppRoutes.openEditDocument(context, document.id);
                } else if (value == 'delete') {
                  _confirmDelete(context, document);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const ValueKey<String>('action-edit'),
                  value: 'edit',
                  child: Text(l10n.editAction),
                ),
                PopupMenuItem(
                  key: const ValueKey<String>('action-delete'),
                  value: 'delete',
                  child: Text(l10n.deleteDocument),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocumentDigitalPass(document: document, large: true),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(document: document),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(
                      title: l10n.deadlineHealth,
                      actionLabel: DocumentStatus.remainingLabel(
                        l10n,
                        document,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DeadlineGrid(document: document),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.documentInformation),
                    const SizedBox(height: AppSpacing.md),
                    RegistryInfoRow(
                      label: l10n.fieldDocumentType,
                      value: DocumentCopy.schema(l10n, document.schemaId),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldCategory,
                      value: DocumentCopy.category(l10n, document.category),
                    ),
                    if (_present(document.ownerName))
                      RegistryInfoRow(
                        label: l10n.ownerLabel,
                        value: document.ownerName!,
                      ),
                    if (_present(document.issuingAuthority))
                      RegistryInfoRow(
                        label: l10n.issuedBy,
                        value: document.issuingAuthority!,
                      ),
                    if (document.maskedDocumentNumber.isNotEmpty)
                      RegistryInfoRow(
                        label: l10n.fieldDocumentNumber,
                        value: document.maskedDocumentNumber,
                      ),
                    if (document.issueDate != null)
                      RegistryInfoRow(
                        label: l10n.fieldIssueDate,
                        value: RegistryDateFormatter.dayMonthYear(
                          document.issueDate!,
                          locale,
                        ),
                      ),
                    if (_present(document.costOfLapsing))
                      RegistryInfoRow(
                        label: l10n.fieldCostOfLapsing,
                        value: document.costOfLapsing!,
                      ),
                    if (_present(document.dependency))
                      RegistryInfoRow(
                        label: l10n.fieldDependency,
                        value: document.dependency!,
                      ),
                    if (_present(document.expectedChanges))
                      RegistryInfoRow(
                        label: l10n.fieldExpectedChanges,
                        value: document.expectedChanges!,
                      ),
                    if (_present(document.notes))
                      RegistryInfoRow(
                        label: l10n.fieldNotes,
                        value: document.notes!,
                      ),
                    for (final field in document.visibleDynamicFields)
                      RegistryInfoRow(
                        label: DocumentCopy.fieldLabel(l10n, field),
                        value: field.sensitive
                            ? field.maskedValue
                            : field.value,
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
                    RegistrySectionHeader(title: l10n.remindersTitle),
                    const SizedBox(height: AppSpacing.sm),
                    if (document.reminders.isEmpty)
                      Text(
                        l10n.noRemindersSelected,
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final reminder in ReminderPreference.values)
                            if (document.reminders.contains(reminder))
                              Chip(
                                label: Text(
                                  DocumentCopy.reminder(l10n, reminder),
                                ),
                              ),
                        ],
                      ),
                  ],
                ),
              ),
              if (document.hasAttachment) ...[
                const SizedBox(height: AppSpacing.md),
                RegistrySurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegistrySectionHeader(title: l10n.attachmentSectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          key: const ValueKey<String>('attachment-thumbnail'),
                          document.attachmentBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        key: const ValueKey<String>('open-attachment'),
                        onPressed: () => _openAttachment(context),
                        child: Text(l10n.viewAttachment),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.renewalHistory),
                    const SizedBox(height: AppSpacing.sm),
                    if (history.isEmpty)
                      RegistryEmptyState(
                        key: const ValueKey<String>('renewal-history-empty'),
                        title: l10n.renewalHistoryEmptyTitle,
                        message: l10n.noRenewalHistory,
                        icon: Icons.history_toggle_off_outlined,
                      )
                    else
                      for (final entry in history) ...[
                        _HistoryItem(entry: entry),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: RegistryPrimaryButton(
                        key: const ValueKey<String>('record-renewal'),
                        label: l10n.recordRenewal,
                        onPressed: () =>
                            RecordRenewalSheet.show(context, document),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RenewalHistoryEntry> _sortedHistory(List<RenewalHistoryEntry> history) {
    return [...history]..sort((a, b) {
      final byDate = b.renewedOn.compareTo(a.renewedOn);
      if (byDate != 0) {
        return byDate;
      }
      return b.id.compareTo(a.id);
    });
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;

  void _openAttachment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DocumentAttachmentPreviewPage(bytes: document.attachmentBytes!),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RegistryDocument document,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteDocumentTitle),
          content: Text(l10n.deleteDocumentMessage(document.name)),
          actions: [
            TextButton(
              key: const ValueKey<String>('delete-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.deleteDocumentCancel),
            ),
            TextButton(
              key: const ValueKey<String>('delete-confirm'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteDocumentConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final deleted = await RegistryDependencies.of(
      context,
    ).documents.delete(document.id);
    if (!deleted) {
      return;
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.documentDeleted)));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.document});

  final RegistryDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <Widget>[
      if (document.hasAttachment)
        _QuickAction(
          key: const ValueKey<String>('quick-view-scan'),
          icon: Icons.photo_outlined,
          label: l10n.viewScan,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DocumentAttachmentPreviewPage(
                  bytes: document.attachmentBytes!,
                ),
              ),
            );
          },
        ),
      _QuickAction(
        key: const ValueKey<String>('quick-edit'),
        icon: Icons.edit_outlined,
        label: l10n.editAction,
        onPressed: () => AppRoutes.openEditDocument(context, document.id),
      ),
      _QuickAction(
        key: const ValueKey<String>('quick-renew'),
        icon: Icons.autorenew_rounded,
        label: l10n.recordRenewal,
        onPressed: () => RecordRenewalSheet.show(context, document),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i != 0) const SizedBox(width: 7),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 59),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlineGrid extends StatelessWidget {
  const _DeadlineGrid({required this.document});

  final RegistryDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final cells = <(String, String)>[
      if (document.hasDistinctActionDate)
        (
          l10n.pulseStartByEyebrow,
          RegistryDateFormatter.dayMonthYear(
            document.displayActionDate,
            locale,
          ),
        ),
      (
        l10n.pulseExpiresEyebrow,
        RegistryDateFormatter.dayMonthYear(document.expiryDate, locale),
      ),
      (l10n.fieldImpact, DocumentCopy.impact(l10n, document.impact)),
      if (document.renewalEffort != null)
        (
          l10n.fieldRenewalEffort,
          DocumentCopy.effort(l10n, document.renewalEffort!),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 280;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i != 0) const SizedBox(height: 8),
                _DeadlineCell(label: cells[i].$1, value: cells[i].$2),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cell in cells)
              SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: _DeadlineCell(label: cell.$1, value: cell.$2),
              ),
          ],
        );
      },
    );
  }
}

class _DeadlineCell extends StatelessWidget {
  const _DeadlineCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.entry});

  final RenewalHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final previous = RegistryDateFormatter.dayMonthYear(
      entry.previousExpiryDate,
      locale,
    );
    final next = RegistryDateFormatter.dayMonthYear(
      entry.newExpiryDate,
      locale,
    );
    final recorded = RegistryDateFormatter.dayMonthYear(
      entry.renewedOn,
      locale,
    );
    final note = entry.note?.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7FBFA),
        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
        border: Border(left: BorderSide(color: Color(0xFF42D8B7), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              children: [
                Text(
                  previous,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
                Text(
                  '→',
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
                Text(
                  next,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(recorded, style: theme.textTheme.bodySmall),
            if (note != null && note.isNotEmpty)
              Text(note, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
