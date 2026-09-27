import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/purchase_service.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class LocalProScreen extends StatefulWidget {
  const LocalProScreen({super.key});

  @override
  State<LocalProScreen> createState() => _LocalProScreenState();
}

class _LocalProScreenState extends State<LocalProScreen> {
  StoreListing? _listing;
  var _loading = true;
  var _buying = false;
  var _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) {
      return;
    }
    _loadStarted = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final listing = await RegistryDependencies.of(
      context,
    ).storeProducts.loadLocalPro();
    if (!mounted) {
      return;
    }
    setState(() {
      _listing = listing;
      _loading = false;
    });
  }

  Future<void> _buy() async {
    final listing = _listing;
    if (listing == null || _buying) {
      return;
    }
    final deps = RegistryDependencies.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _buying = true);
    try {
      final attempt = await deps.purchases.purchaseLocalPro();
      deps.entitlements.applyVerified(attempt.proof);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      if (deps.entitlements.plan == RegistryPlan.localPro) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.localProOwned)));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.localProPurchasePending)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = RegistryDependencies.of(context).entitlements.plan;
    final owned = plan == RegistryPlan.localPro;
    final listing = _listing;
    final canBuy = !_loading && !owned && listing != null && !_buying;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.localProTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardBorder,
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.localProEyebrow,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.localProHeadline,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.localProIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localProIncludedTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.localProIncludedDocuments(
                      EntitlementPolicy.freeDocumentLimit,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.localProIncludedSubscriptions(
                      EntitlementPolicy.freeSubscriptionLimit,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.localProTechnicalLimits,
                    style: theme.textTheme.bodyMedium,
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
                  Text(
                    l10n.localProNotIncludedTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.localProNotIncludedCloud,
                    style: theme.textTheme.bodyMedium,
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
                  Text(
                    l10n.localProFreeTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.localProFreeBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              owned ? l10n.localProCurrentPro : l10n.localProCurrentFree,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const LinearProgressIndicator()
            else if (owned)
              Text(l10n.localProOwned, style: theme.textTheme.bodyLarge)
            else if (listing == null)
              Text(
                key: const ValueKey<String>('local-pro-price-unavailable'),
                l10n.localProPriceUnavailable,
                style: theme.textTheme.bodyLarge,
              )
            else
              Text(
                key: const ValueKey<String>('local-pro-price'),
                listing.localizedPrice,
                style: theme.textTheme.headlineSmall,
              ),
            const SizedBox(height: AppSpacing.md),
            if (!owned)
              RegistryPrimaryButton(
                key: const ValueKey<String>('local-pro-buy'),
                label: l10n.localProBuy,
                onPressed: canBuy ? () => unawaited(_buy()) : null,
              ),
          ],
        ),
      ),
    );
  }
}
