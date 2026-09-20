import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/features/home/data/registry_read_model.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AttentionListScreen extends StatelessWidget {
  const AttentionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deps = RegistryDependencies.of(context);
    final now = deps.clock.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeAttentionListTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([deps.documents, deps.subscriptions]),
          builder: (context, _) {
            final items = RegistryReadModel.attentionItems(
              RegistryReadModel.fromRepositories(
                documents: deps.documents.documents,
                subscriptions: deps.subscriptions.subscriptions,
                l10n: l10n,
                now: now,
              ),
            );
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: RegistryEmptyState(
                  key: const ValueKey<String>('attention-empty'),
                  title: l10n.attentionEmpty,
                  message: l10n.homeCalmMessage,
                  icon: Icons.check_circle_outline,
                ),
              );
            }
            return ListView.separated(
              key: const ValueKey<String>('attention-list'),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                return HomeAttentionCard(
                  key: ValueKey<String>('attention-${item.id}'),
                  item: item,
                  now: now,
                  onTap: () => AppRoutes.openRegistryItem(context, item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
