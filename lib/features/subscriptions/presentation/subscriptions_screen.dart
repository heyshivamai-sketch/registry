import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.scrollFabClearance,
        ),
        children: [
          Text(
            l10n.subscriptionsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          RegistryEmptyState(
            title: l10n.subscriptionsEmptyTitle,
            message: l10n.subscriptionsEmptyMessage,
            illustration: const RegistrySubscriptionIllustration(),
            action: SizedBox(
              width: double.infinity,
              child: RegistryPrimaryButton(
                key: const ValueKey<String>('subscriptions-add'),
                label: l10n.addSubscription,
                onPressed: () => AppRoutes.openAddSubscription(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
