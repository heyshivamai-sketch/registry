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
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
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
              DocumentDigitalPass(document: document),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(document: document),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(
                      icon: Icons.timelapse_outlined,
                      title: l10n.deadlineHealth,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      DocumentStatus.remainingLabel(l10n, document),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (document.hasDistinctActionDate)
                      _InfoRow(
                        label: l10n.fieldActionDate,
                        value: RegistryDateFormatter.dayMonthYear(
                          document.displayActionDate,
                          locale,
                        ),
                      ),
                    _InfoRow(
                      label: l10n.fieldExpiryDate,
                      value: RegistryDateFormatter.dayMonthYear(
                        document.expiryDate,
                        locale,
                      ),
                    ),
                    _InfoRow(
                      label: l10n.fieldImpact,
                      value: DocumentCopy.impact(l10n, document.impact),
                    ),
                    if (document.renewalEffort != null)
                      _InfoRow(
                        label: l10n.fieldRenewalEffort,
                        value: DocumentCopy.effort(
                          l10n,
                          document.renewalEffort!,
                        ),
                      ),
                  ],
                ),
              ),
              if (_hasInformation(document)) ...[
                const SizedBox(height: AppSpacing.md),
                RegistrySurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegistrySectionHeader(
                        icon: Icons.info_outline,
                        title: l10n.documentInformation,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_present(document.ownerName))
                        _InfoRow(
                          label: l10n.ownerLabel,
                          value: document.ownerName!,
                        ),
                      if (_present(document.issuingAuthority))
                        _InfoRow(
                          label: l10n.issuedBy,
                          value: document.issuingAuthority!,
                        ),
                      if (document.maskedDocumentNumber.isNotEmpty)
                        _InfoRow(
                          label: l10n.fieldDocumentNumber,
                          value: document.maskedDocumentNumber,
                        ),
                      if (document.issueDate != null)
                        _InfoRow(
                          label: l10n.fieldIssueDate,
                          value: RegistryDateFormatter.dayMonthYear(
                            document.issueDate!,
                            locale,
                          ),
                        ),
                      if (_present(document.costOfLapsing))
                        _InfoRow(
                          label: l10n.fieldCostOfLapsing,
                          value: document.costOfLapsing!,
                        ),
                      if (_present(document.dependency))
                        _InfoRow(
                          label: l10n.fieldDependency,
                          value: document.dependency!,
                        ),
                      if (_present(document.expectedChanges))
                        _InfoRow(
                          label: l10n.fieldExpectedChanges,
                          value: document.expectedChanges!,
                        ),
                      if (_present(document.notes))
                        _InfoRow(
                          label: l10n.fieldNotes,
                          value: document.notes!,
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
                    RegistrySectionHeader(
                      icon: Icons.notifications_outlined,
                      title: l10n.remindersTitle,
                    ),
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
                      RegistrySectionHeader(
                        icon: Icons.photo_outlined,
                        title: l10n.attachmentSectionTitle,
                      ),
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
                    RegistrySectionHeader(
                      icon: Icons.history_outlined,
                      title: l10n.renewalHistory,
                    ),
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
                        _InfoRow(
                          label: l10n.previousExpiry,
                          value: RegistryDateFormatter.dayMonthYear(
                            entry.previousExpiryDate,
                            locale,
                          ),
                        ),
                        _InfoRow(
                          label: l10n.newExpiry,
                          value: RegistryDateFormatter.dayMonthYear(
                            entry.newExpiryDate,
                            locale,
                          ),
                        ),
                        _InfoRow(
                          label: l10n.renewalDate,
                          value: RegistryDateFormatter.dayMonthYear(
                            entry.renewedOn,
                            locale,
                          ),
                        ),
                        if (_present(entry.note))
                          _InfoRow(label: l10n.fieldNotes, value: entry.note!),
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

  bool _hasInformation(RegistryDocument document) {
    return _present(document.ownerName) ||
        _present(document.issuingAuthority) ||
        document.maskedDocumentNumber.isNotEmpty ||
        document.issueDate != null ||
        _present(document.dependency) ||
        _present(document.costOfLapsing) ||
        _present(document.expectedChanges) ||
        _present(document.notes);
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

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions
          .map(
            (action) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: action,
            ),
          )
          .toList(growable: false),
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
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTapTarget,
            minWidth: AppSpacing.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
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
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
