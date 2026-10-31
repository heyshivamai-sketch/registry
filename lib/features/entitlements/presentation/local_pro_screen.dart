import 'dart:async';
import 'package:the_registry/core/widgets/attention_entrance.dart';
import 'package:the_registry/features/home/widgets/registry_hero_pass_stack.dart';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/entitlements/local_pro_store.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class LocalProScreen extends StatefulWidget {
  const LocalProScreen({super.key});

  @override
  State<LocalProScreen> createState() => _LocalProScreenState();
}

class _LocalProScreenState extends State<LocalProScreen> {
  var _loadStarted = false;
  var _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) {
      return;
    }
    _loadStarted = true;
    final localPro = RegistryDependencies.of(context).localPro;
    if (localPro.restoreAvailable) {
      unawaited(localPro.loadProduct());
    }
  }

  Future<void> _run(
    Future<LocalProActionResult> Function(LocalProEntitlement localPro) action,
  ) async {
    if (_busy) {
      return;
    }
    final localPro = RegistryDependencies.of(context).localPro;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result = await action(localPro);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_resultText(l10n, result))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _resultText(AppLocalizations l10n, LocalProActionResult result) {
    return switch (result) {
      LocalProActionResult.active => l10n.localProResultActive,
      LocalProActionResult.pending => l10n.localProPendingStore,
      LocalProActionResult.cancelled => l10n.localProPurchaseCancelled,
      LocalProActionResult.notFound => l10n.localProRestoreNotFound,
      LocalProActionResult.storeUnavailable => l10n.localProStoreUnavailable,
      LocalProActionResult.storeError => l10n.localProStoreError,
      LocalProActionResult.failed => l10n.localProPurchaseFailed,
      LocalProActionResult.unavailable => l10n.localProStatusDisabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deps = RegistryDependencies.of(context);
    final localPro = deps.localPro;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.localProTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: localPro,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                MediaQuery.sizeOf(context).width > 720
                    ? (MediaQuery.sizeOf(context).width - 672) / 2
                    : AppSpacing.screenPadding,
                AppSpacing.md,
                MediaQuery.sizeOf(context).width > 720
                    ? (MediaQuery.sizeOf(context).width - 672) / 2
                    : AppSpacing.screenPadding,
                AppSpacing.screenPadding,
              ),
              children: [
                AttentionEntrance(
                  child: _Hero(theme: theme, l10n: l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.localProIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: l10n.localProIncludedTitle,
                  lines: [
                    l10n.localProIncludedDocuments(
                      EntitlementPolicy.freeDocumentLimit,
                    ),
                    l10n.localProIncludedSubscriptions(
                      EntitlementPolicy.freeSubscriptionLimit,
                    ),
                    deps.ads.enabled
                        ? l10n.localProIncludedAdsOn
                        : l10n.localProIncludedAds,
                    l10n.localProTechnicalLimits,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: l10n.localProNotIncludedTitle,
                  lines: [
                    l10n.localProNotIncludedCloud,
                    l10n.localProNotIncludedTransfer,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: l10n.localProFreeTitle,
                  lines: [l10n.localProFreeBody],
                ),
                const SizedBox(height: AppSpacing.lg),
                _StatusBlock(localPro: localPro),
                const SizedBox(height: AppSpacing.md),
                ..._purchaseControls(context, l10n, theme, localPro),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _purchaseControls(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    LocalProEntitlement localPro,
  ) {
    if (!localPro.restoreAvailable) {
      return [
        Text(
          l10n.localProStatusDisabled,
          key: const ValueKey<String>('local-pro-purchases-disabled'),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryPrimaryButton(
          key: const ValueKey<String>('local-pro-buy'),
          label: l10n.localProBuy,
          onPressed: null,
        ),
      ];
    }
    final owned = localPro.status == LocalProStatus.active;
    final product = localPro.product;
    return [
      if (!owned) ...[
        if (product == null)
          const LinearProgressIndicator()
        else if (product.isAvailable)
          Text(
            product.localizedPrice!,
            key: const ValueKey<String>('local-pro-price'),
            style: theme.textTheme.headlineSmall,
          )
        else ...[
          Text(
            _productText(l10n, product.status),
            key: const ValueKey<String>('local-pro-price-unavailable'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey<String>('local-pro-retry'),
              onPressed: _busy
                  ? null
                  : () => unawaited(localPro.loadProduct(force: true)),
              child: Text(l10n.localProRetry),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        RegistryPrimaryButton(
          key: const ValueKey<String>('local-pro-buy'),
          label: l10n.localProBuy,
          onPressed:
              !_busy &&
                  product != null &&
                  product.isAvailable &&
                  localPro.plan == RegistryPlan.free
              ? () => unawaited(_run((localPro) => localPro.buy()))
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      Text(l10n.localProRestoreRequirements, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton(
        key: const ValueKey<String>('local-pro-restore'),
        onPressed: _busy
            ? null
            : () => unawaited(_run((localPro) => localPro.restore())),
        child: Text(l10n.localProRestore, textAlign: TextAlign.center),
      ),
    ];
  }

  String _productText(AppLocalizations l10n, StoreProductStatus status) {
    return switch (status) {
      StoreProductStatus.missing => l10n.localProProductMissing,
      StoreProductStatus.unavailable => l10n.localProStoreUnavailable,
      StoreProductStatus.error ||
      StoreProductStatus.available => l10n.localProStoreError,
    };
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardBorder,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [const Color(0xFF171D49), theme.colorScheme.tertiary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE8AD),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: Color(0xFF6A4510),
                    ),
                  ),
                ),
                Spacer(),
                ExcludeSemantics(
                  child: RegistryHeroPassStack(
                    icon: Icons.verified_user_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RegistrySurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          for (final line in lines) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.localPro});

  final LocalProEntitlement localPro;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = localPro.status;
    final detail = switch (status) {
      LocalProStatus.disabled => null,
      LocalProStatus.checking => l10n.localProStatusChecking,
      LocalProStatus.active => l10n.localProStatusActive,
      LocalProStatus.activeUnconfirmed => l10n.localProStatusActiveUnconfirmed,
      LocalProStatus.free => null,
      LocalProStatus.unknown => l10n.localProStatusUnknown,
    };
    return Column(
      key: const ValueKey<String>('local-pro-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localPro.plan == RegistryPlan.localPro
              ? l10n.localProCurrentPro
              : l10n.localProCurrentFree,
          style: theme.textTheme.titleSmall,
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            key: ValueKey<String>('local-pro-status-${status.name}'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (localPro.revokedThisSession) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.localProRevoked,
            key: const ValueKey<String>('local-pro-revoked'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (localPro.pendingPurchase) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.localProPendingStore,
            key: const ValueKey<String>('local-pro-pending'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
