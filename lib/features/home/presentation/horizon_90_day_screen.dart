import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Chronological 90-day Horizon. Not a full calendar engine.
class Horizon90DayScreen extends StatelessWidget {
  const Horizon90DayScreen({super.key, this.items, this.now});

  /// Injected catalog for tests. Defaults to the mock Home catalog.
  final List<RegistryItem>? items;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final source = items ?? MockRegistryCatalog.items;
    final ordered = MockRegistryCatalog.withinHorizonItems(source, now: now);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.snapshotNinetyDayView)),
      body: SafeArea(
        child: ordered.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: RegistryEmptyState(
                  key: const ValueKey<String>('horizon-90-empty'),
                  title: l10n.horizon90EmptyTitle,
                  message: l10n.horizon90EmptyMessage,
                  icon: Icons.calendar_today_outlined,
                ),
              )
            : ListView.builder(
                key: const ValueKey<String>('horizon-90-day'),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                itemCount: ordered.length,
                itemBuilder: (context, index) {
                  final item = ordered[index];
                  return HomeUpcomingItem(
                    key: ValueKey<String>('horizon-${item.id}'),
                    item: item,
                    isLast: index == ordered.length - 1,
                    showStatus: true,
                    onTap: () =>
                        AppRoutes.openCatalogItemReview(context, item.id),
                  );
                },
              ),
      ),
    );
  }
}
