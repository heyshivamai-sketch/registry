import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/data/registry_read_model.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Chronological 90-day Horizon. Not a full calendar engine.
class Horizon90DayScreen extends StatelessWidget {
  const Horizon90DayScreen({super.key, this.items, this.now});

  /// Injected catalog for tests. Defaults to live repository data.
  final List<RegistryItem>? items;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deps = items == null ? RegistryDependencies.of(context) : null;
    final clockNow = now ?? deps?.clock.now();

    Widget body(List<RegistryItem> source) {
      final ordered = MockRegistryCatalog.withinHorizonItems(
        source.where((item) => item.status != RegistryStatus.neutral),
        now: clockNow,
      );
      return ordered.isEmpty
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
                  onTap: () => AppRoutes.openRegistryItem(context, item),
                );
              },
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.snapshotNinetyDayView)),
      body: SafeArea(
        child: deps == null
            ? body(items!)
            : ListenableBuilder(
                listenable: Listenable.merge([
                  deps.documents,
                  deps.subscriptions,
                ]),
                builder: (context, _) {
                  return body(
                    RegistryReadModel.fromRepositories(
                      documents: deps.documents.documents,
                      subscriptions: deps.subscriptions.subscriptions,
                      l10n: l10n,
                      now: clockNow,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
