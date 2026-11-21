import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_search_field.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_wallet.dart';
import 'package:the_registry/features/subscriptions/widgets/subscription_list_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class CancelledSubscriptionsScreen extends StatefulWidget {
  const CancelledSubscriptionsScreen({super.key});

  @override
  State<CancelledSubscriptionsScreen> createState() =>
      _CancelledSubscriptionsScreenState();
}

class _CancelledSubscriptionsScreenState
    extends State<CancelledSubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final deps = RegistryDependencies.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cancelledSubscriptionsTitle),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: deps.subscriptions,
          builder: (context, _) {
            final cancelled = deps.subscriptions.subscriptions
                .where((sub) => sub.isCancelled)
                .toList()
              ..sort((a, b) {
                final dateA = a.updatedAt ?? a.createdAt;
                final dateB = b.updatedAt ?? b.createdAt;
                return dateB.compareTo(dateA);
              });

            final query = _searchController.text;
            final visible = query.trim().isEmpty
                ? cancelled
                : cancelled
                    .where((s) => SubscriptionWallet.matchesQuery(s, query, l10n))
                    .toList();

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              children: [
                if (cancelled.isNotEmpty) ...[
                  RegistryAuraSearchField(
                    controller: _searchController,
                    hintText: l10n.cancelledSubscriptionsSearchPlaceholder,
                    fieldKey: const ValueKey<String>('cancelled-search'),
                    clearKey: const ValueKey<String>('cancelled-search-clear'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RegistrySurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: statusColors.urgentContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.event_busy_outlined,
                            color: statusColors.urgent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.cancelledSubscriptionsCount(cancelled.length),
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap any plan to view details or reactivate tracking.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (cancelled.isEmpty)
                  RegistryEmptyState(
                    key: const ValueKey<String>('cancelled-subscriptions-empty'),
                    icon: Icons.event_busy_outlined,
                    title: l10n.cancelledSubscriptionsEmptyTitle,
                    message: l10n.cancelledSubscriptionsEmptyMessage,
                  )
                else if (visible.isEmpty)
                  RegistryEmptyState(
                    key: const ValueKey<String>(
                      'cancelled-subscriptions-search-empty',
                    ),
                    icon: Icons.search_off_rounded,
                    title: l10n.subscriptionsSearchEmptyTitle,
                    message: l10n.subscriptionsSearchEmptyMessage,
                  )
                else
                  for (final subscription in visible) ...[
                    SubscriptionListCard(
                      key: ValueKey<String>('cancelled-${subscription.id}'),
                      subscription: subscription,
                      onTap: () => AppRoutes.openSubscriptionDetail(
                        context,
                        subscription.id,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
