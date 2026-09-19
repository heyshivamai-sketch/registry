import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_summary_card.dart';

/// Temporary visual catalogue for the foundation design system.
/// This is not the product Home screen.
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Text('Registry', style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A calm place to track documents and subscriptions before they expire.',
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const RegistrySectionHeader(
              title: 'Overview',
              subtitle: 'Preview of summary information you will see on Home.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const RegistrySummaryCard(
              title: 'Upcoming actions',
              value: '3',
              subtitle: '1 urgent · 2 due this week',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const RegistrySectionHeader(
              title: 'Status',
              subtitle:
                  'Colour is never the only signal — each state has a label and icon.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                RegistryStatusChip(
                  status: RegistryStatus.urgent,
                  label: 'Action needed',
                ),
                RegistryStatusChip(
                  status: RegistryStatus.upcoming,
                  label: 'Upcoming',
                ),
                RegistryStatusChip(
                  status: RegistryStatus.active,
                  label: 'Active',
                ),
                RegistryStatusChip(
                  status: RegistryStatus.expired,
                  label: 'Expired',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const RegistrySectionHeader(title: 'Actions'),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(
              width: double.infinity,
              child: RegistryPrimaryButton(
                label: 'Review items',
                onPressed: _noop,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const SizedBox(
              width: double.infinity,
              child: RegistrySecondaryButton(
                label: 'View all records',
                onPressed: _noop,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const RegistrySectionHeader(
              title: 'Empty state',
              subtitle: 'Shown when a list has nothing that needs attention.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const RegistryEmptyState(
              title: 'Nothing to review',
              message:
                  'When documents or subscriptions need attention, they will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}
