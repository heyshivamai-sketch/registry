import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_icons.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/presentation/record_renewal_sheet.dart';
import 'package:the_registry/features/documents/widgets/document_attachment_preview_page.dart';
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
    final status = DocumentStatus.resolve(document);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentDetailsTitle),
        actions: [
          PopupMenuButton<String>(
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            _DocumentPassCard(document: document, status: status),
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
                    label: l10n.deadlineRemaining,
                    value: DocumentStatus.remainingLabel(l10n, document),
                  ),
                  _InfoRow(
                    label: l10n.fieldImpact,
                    value: DocumentCopy.impact(l10n, document.impact),
                  ),
                  if (document.renewalEffort != null)
                    _InfoRow(
                      label: l10n.fieldRenewalEffort,
                      value: DocumentCopy.effort(l10n, document.renewalEffort!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_hasInformation(document))
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
                    if (_present(document.issuingAuthority))
                      _InfoRow(
                        label: l10n.issuedBy,
                        value: document.issuingAuthority!,
                      ),
                    if (_present(document.dependency))
                      _InfoRow(
                        label: l10n.fieldDependency,
                        value: document.dependency!,
                      ),
                    if (_present(document.costOfLapsing))
                      _InfoRow(
                        label: l10n.fieldCostOfLapsing,
                        value: document.costOfLapsing!,
                      ),
                    if (_present(document.expectedChanges))
                      _InfoRow(
                        label: l10n.fieldExpectedChanges,
                        value: document.expectedChanges!,
                      ),
                    if (_present(document.notes))
                      _InfoRow(label: l10n.fieldNotes, value: document.notes!),
                    if (document.issueDate != null)
                      _InfoRow(
                        label: l10n.fieldIssueDate,
                        value: RegistryDateFormatter.dayMonthYear(
                          document.issueDate!,
                          locale,
                        ),
                      ),
                  ],
                ),
              ),
            if (_hasInformation(document))
              const SizedBox(height: AppSpacing.md),
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistrySectionHeader(
                    icon: Icons.notifications_outlined,
                    title: l10n.sectionReminders,
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
                  if (!document.hasAttachment)
                    Text(
                      l10n.noPhotoAttached,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.cardBorder,
                          child: Image.memory(
                            document.attachmentBytes!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          key: const ValueKey<String>('open-attachment'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DocumentAttachmentPreviewPage(
                                  bytes: document.attachmentBytes!,
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.viewAttachment),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistrySectionHeader(
                    icon: Icons.history_outlined,
                    title: l10n.renewalHistory,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (document.renewalHistory.isEmpty)
                    Text(
                      key: const ValueKey<String>('renewal-history-empty'),
                      l10n.noRenewalHistory,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    for (final entry in document.renewalHistory) ...[
                      _InfoRow(
                        label: l10n.renewalDate,
                        value: RegistryDateFormatter.dayMonthYear(
                          entry.renewedOn,
                          locale,
                        ),
                      ),
                      Text(
                        '${RegistryDateFormatter.dayMonthYear(entry.previousExpiryDate, locale)} → ${RegistryDateFormatter.dayMonthYear(entry.newExpiryDate, locale)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_present(entry.note))
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            entry.note!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const ValueKey<String>('record-renewal'),
                      onPressed: () =>
                          RecordRenewalSheet.show(context, document),
                      child: Text(l10n.recordRenewal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasInformation(RegistryDocument document) {
    return _present(document.issuingAuthority) ||
        _present(document.dependency) ||
        _present(document.costOfLapsing) ||
        _present(document.expectedChanges) ||
        _present(document.notes) ||
        document.issueDate != null;
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;

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

class _DocumentPassCard extends StatelessWidget {
  const _DocumentPassCard({required this.document, required this.status});

  final RegistryDocument document;
  final RegistryStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = Theme.of(context).extension<AppBrandColors>()!;

    return Semantics(
      container: true,
      label: l10n.documentPassLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardBorder,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [brand.heroStart, brand.heroEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RegistryIconBadge(
                    icon: DocumentIcons.forCategory(document.category),
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DocumentCopy.category(l10n, document.category),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          document.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_present(document.ownerName)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.ownerLabel}: ${document.ownerName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RegistryStatusChip(
                    status: status,
                    label: DocumentStatus.label(l10n, status),
                  ),
                  if (document.hasAttachment)
                    Semantics(
                      label: l10n.hasAttachment,
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: Colors.white,
                        size: AppSpacing.iconMd,
                      ),
                    ),
                ],
              ),
              if (document.maskedDocumentNumber.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  label: l10n.maskedDocumentNumberLabel(
                    document.maskedDocumentNumber,
                  ),
                  child: Text(
                    document.maskedDocumentNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
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
