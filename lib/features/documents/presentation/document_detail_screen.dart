import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_empty_state.dart';
import '../../../core/widgets/registry_section_header.dart';
import '../../../core/widgets/registry_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/registry_date_formatter.dart';
import '../../reminders/presentation/reminder_status_line.dart';
import '../domain/document_status.dart';
import '../domain/registry_document.dart';
import '../domain/renewal_history_entry.dart';
import '../widgets/document_attachment_preview_page.dart';
import '../widgets/document_digital_pass.dart';
import 'document_copy.dart';
import 'record_renewal_sheet.dart';

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
    final colorScheme = theme.colorScheme;
    final locale = l10n.localeName;
    final history = _sortedHistory(document.renewalHistory);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.xs,
        title: Text(document.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: PopupMenuButton<String>(
              key: const ValueKey<String>('document-actions'),
              tooltip: l10n.moreActions,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
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
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSurface),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.editAction),
                    ],
                  ),
                ),
                PopupMenuItem(
                  key: const ValueKey<String>('action-delete'),
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.deleteDocument, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ),
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
              DocumentDigitalPass(document: document, large: true, compact: true),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(document: document),
              const SizedBox(height: AppSpacing.md),
              if (document.hasImportantDates) ...[
                RegistrySurface(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegistrySectionHeader(
                        title: l10n.sectionImportantDates,
                        actionLabel: DocumentStatus.remainingLabel(l10n, document),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DeadlineGrid(document: document),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.documentInformation),
                    const SizedBox(height: AppSpacing.sm),
                    if (document.countryCode != null)
                      RegistryInfoRow(
                        label: l10n.fieldCountry,
                        value: DocumentCopy.country(l10n, document.countryCode),
                      ),
                    RegistryInfoRow(label: l10n.fieldDocumentType, value: DocumentCopy.schema(l10n, document.schemaId)),
                    RegistryInfoRow(
                      label: l10n.fieldCategory,
                      value: document.categoryLabel?.isNotEmpty == true
                          ? document.categoryLabel!
                          : DocumentCopy.category(l10n, document.category),
                    ),
                    if (_present(document.ownerName))
                      RegistryInfoRow(label: l10n.ownerLabel, value: document.ownerName!),
                    if (_present(document.issuingAuthority))
                      RegistryInfoRow(label: l10n.issuedBy, value: document.issuingAuthority!),
                    if (document.maskedDocumentNumber.isNotEmpty)
                      _DocumentNumberRow(
                        label: l10n.fieldDocumentNumber,
                        maskedValue: document.maskedDocumentNumber,
                        rawValue: document.documentNumber,
                      ),
                    if (document.issueDate != null && !document.hasImportantDates)
                      RegistryInfoRow(
                        label: l10n.fieldIssueDate,
                        value: RegistryDateFormatter.dayMonthYear(document.issueDate!, locale),
                      ),
                    RegistryInfoRow(label: l10n.fieldImpact, value: DocumentCopy.impact(l10n, document.impact)),
                    if (document.renewalEffort != null)
                      RegistryInfoRow(
                        label: l10n.fieldRenewalEffort,
                        value: DocumentCopy.effort(l10n, document.renewalEffort!),
                      ),
                    if (_present(document.costOfLapsing))
                      RegistryInfoRow(label: l10n.fieldCostOfLapsing, value: document.costOfLapsing!),
                    if (_present(document.dependency))
                      RegistryInfoRow(label: l10n.fieldDependency, value: document.dependency!),
                    if (_present(document.expectedChanges))
                      RegistryInfoRow(label: l10n.fieldExpectedChanges, value: document.expectedChanges!),
                    if (_present(document.notes)) RegistryInfoRow(label: l10n.fieldNotes, value: document.notes!),
                    for (final field in document.visibleDynamicFields)
                      RegistryInfoRow(
                        label: DocumentCopy.fieldLabel(l10n, field),
                        value: (field.sensitive && field.canBeSensitive) ? field.maskedValue : field.value,
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
                    RegistrySectionHeader(title: l10n.reminderPreferencesTitle),
                    const SizedBox(height: AppSpacing.xs),
                    if (document.reminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.noRemindersSelected, style: theme.textTheme.bodyMedium),
                      )
                    else ...[
                      RegistryInfoRow(
                        label: l10n.remindMePrefix,
                        value: document.reminders.map((reminder) => DocumentCopy.reminder(l10n, reminder)).join(', '),
                      ),
                      ListenableBuilder(
                        listenable: RegistryDependencies.of(context).reminders,
                        builder: (context, _) {
                          return ReminderStatusLine(
                            status: RegistryDependencies.of(context).reminders.statusForDocument(document),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (document.hasAttachment) ...[
                const SizedBox(height: AppSpacing.md),
                RegistrySurface(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
                  child: _AttachmentRow(
                    bytes: document.attachmentBytes!,
                    count: document.attachmentCount,
                    title: l10n.attachmentSectionTitle,
                    subtitle: l10n.attachmentAddedOn(RegistryDateFormatter.dayMonthYear(document.createdAt, locale)),
                    actionLabel: l10n.viewScan,
                    onView: () => _openAttachment(context),
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
                      _InlineActionRow(
                        key: const ValueKey<String>('renewal-history-empty'),
                        label: l10n.renewalHistoryEmptyTitle,
                        actionKey: const ValueKey<String>('record-renewal'),
                        actionLabel: l10n.recordRenewal,
                        onPressed: () => RecordRenewalSheet.show(context, document),
                      )
                    else ...[
                      for (final entry in history) ...[_HistoryItem(entry: entry), const SizedBox(height: 6)],
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.tonalIcon(
                          key: const ValueKey<String>('record-renewal'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                            minimumSize: const Size(AppSpacing.minTapTarget, 40),
                            elevation: 0,
                          ),
                          onPressed: () => RecordRenewalSheet.show(context, document),
                          icon: const Icon(Icons.autorenew_rounded, size: 18),
                          label: Text(l10n.recordRenewal, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
        builder: (_) => DocumentAttachmentPreviewPage(
          bytes: document.attachmentBytes!,
          additionalImages: document.additionalImages,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RegistryDocument document) async {
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
              style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
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
    final deleted = await RegistryDependencies.of(context).documents.delete(document.id);
    if (!deleted) {
      return;
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.documentDeleted)));
  }
}

class _DocumentNumberRow extends StatelessWidget {
  const _DocumentNumberRow({required this.label, required this.maskedValue, this.rawValue});

  final String label;
  final String maskedValue;
  final String? rawValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    maskedValue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 1.1,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: colorScheme.primary),
              tooltip: 'Copy document number',
              onPressed: () {
                final textToCopy = (rawValue != null && rawValue!.isNotEmpty) ? rawValue! : maskedValue;
                Clipboard.setData(ClipboardData(text: textToCopy));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Document number copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.bytes,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onView,
    this.count = 1,
  });

  final Uint8List bytes;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onView;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final preview = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.memory(
              key: const ValueKey<String>('attachment-thumbnail'),
              bytes,
              height: 52,
              width: 44,
              fit: BoxFit.cover,
            ),
          ),
          if (count > 1)
            PositionedDirectional(
              bottom: 2,
              end: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 9, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    final copy = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                key: const ValueKey<String>('attachment-count-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.attachmentCount(count),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    final action = OutlinedButton.icon(
      key: const ValueKey<String>('open-attachment'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: onView,
      icon: const Icon(Icons.visibility_outlined, size: 16),
      label: Text(actionLabel),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (scale >= 1.3 || constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  preview,
                  const SizedBox(width: AppSpacing.sm),
                  copy,
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }
        return Row(
          children: [
            preview,
            const SizedBox(width: AppSpacing.sm),
            copy,
            const SizedBox(width: AppSpacing.xs),
            action,
          ],
        );
      },
    );
  }
}

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({
    super.key,
    required this.label,
    required this.actionKey,
    required this.actionLabel,
    required this.onPressed,
  });

  final String label;
  final Key actionKey;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final action = FilledButton.tonalIcon(
      key: actionKey,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        minimumSize: const Size(AppSpacing.minTapTarget, 38),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.autorenew_rounded, size: 16),
      label: Text(
        actionLabel,
        style: const TextStyle(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        action,
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.document});

  final RegistryDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <Widget>[
      _QuickAction(
        key: const ValueKey<String>('quick-edit'),
        icon: Icons.edit_outlined,
        label: l10n.editAction,
        onPressed: () => AppRoutes.openEditDocument(context, document.id),
      ),
      if (document.hasAttachment)
        _QuickAction(
          key: const ValueKey<String>('quick-view-scan'),
          icon: Icons.photo_outlined,
          label: document.attachmentCount > 1 ? '${l10n.viewScan} (${document.attachmentCount})' : l10n.viewScan,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DocumentAttachmentPreviewPage(
                  bytes: document.attachmentBytes!,
                  additionalImages: document.additionalImages,
                ),
              ),
            );
          },
        ),
      _QuickAction(
        key: const ValueKey<String>('quick-renew'),
        icon: Icons.autorenew_rounded,
        label: l10n.renewAction,
        onPressed: () => RecordRenewalSheet.show(context, document),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stacked = constraints.maxWidth < 360 || scale >= 1.3;
        if (stacked) {
          return Row(
            spacing: 8,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i != 0) const SizedBox(height: AppSpacing.xs),
                Expanded(child: actions[i]),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i != 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: actions[i]),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 8),
            child: scale >= 1.3
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 19, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colorScheme.onSurface,
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
    final cells = <(String, String, IconData)>[
      if (document.issueDate != null)
        (
          l10n.fieldIssueDate,
          RegistryDateFormatter.dayMonthYear(document.issueDate!, locale),
          Icons.event_available_outlined,
        ),
      if (document.hasDistinctActionDate)
        (
          l10n.homeStartRenewal,
          RegistryDateFormatter.dayMonthYear(document.displayActionDate, locale),
          Icons.event_repeat_outlined,
        ),
      if (document.hasExpiry)
        (
          l10n.pulseExpiresEyebrow,
          RegistryDateFormatter.dayMonthYear(document.expiryDate, locale),
          Icons.event_busy_outlined,
        ),
    ];

    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < cells.length; i++)
          RegistryInfoRow(label: cells[i].$1, value: cells[i].$2, icon: cells[i].$3),
      ],
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
    final previous = RegistryDateFormatter.dayMonthYear(entry.previousExpiryDate, locale);
    final next = RegistryDateFormatter.dayMonthYear(entry.newExpiryDate, locale);
    final recorded = RegistryDateFormatter.dayMonthYear(entry.renewedOn, locale);
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
                Text(previous, style: theme.textTheme.titleSmall),
                Text('→', style: theme.textTheme.titleSmall),
                Text(next, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 3),
            Text(recorded, style: theme.textTheme.bodySmall),
            if (note != null && note.isNotEmpty) Text(note, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
