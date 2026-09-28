import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/entitlements/pro_account.dart';
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
  String? _recoveryCode;
  final _restoreCode = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  ProAccountSession? _account;
  String? _accountMessage;
  var _accountBusy = false;

  @override
  void dispose() {
    _restoreCode.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

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
    final deps = RegistryDependencies.of(context);
    final listing = await deps.storeProducts.loadLocalPro();
    final account = await deps.proAccounts?.readSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _listing = listing;
      _account = account;
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
      _showAttempt(deps, l10n, attempt);
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  Future<void> _restore() async {
    if (_buying) {
      return;
    }
    final deps = RegistryDependencies.of(context);
    final l10n = AppLocalizations.of(context);
    final code = _restoreCode.text.trim();
    setState(() => _buying = true);
    try {
      final attempt = await deps.purchases.restoreLocalPro(
        recoveryCode: code.isEmpty ? null : code,
      );
      _showAttempt(deps, l10n, attempt);
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  void _showAttempt(
    RegistryDependencies deps,
    AppLocalizations l10n,
    PurchaseAttempt attempt,
  ) {
    if (attempt.outcome != PurchaseFlowOutcome.unchanged &&
        attempt.proof != null) {
      deps.entitlements.applyVerified(attempt.proof);
    }
    if (!mounted) {
      return;
    }
    if (attempt.recoveryCode != null) {
      setState(() => _recoveryCode = attempt.recoveryCode);
    }
    final owned = deps.entitlements.plan == RegistryPlan.localPro;
    final message = switch (attempt.accountLink) {
      'unchanged' => l10n.localProAccountUnchanged,
      'linked' => l10n.localProAccountLinked,
      _ => switch (attempt.outcome) {
        PurchaseFlowOutcome.cancelled => l10n.localProPurchaseCancelled,
        PurchaseFlowOutcome.failed => l10n.localProPurchaseFailed,
        PurchaseFlowOutcome.pending => l10n.localProPendingStore,
        PurchaseFlowOutcome.bindingMismatch => l10n.localProBindingMismatch,
        PurchaseFlowOutcome.recoveryCodeRequired =>
          l10n.localProRecoveryCodeRequired,
        PurchaseFlowOutcome.accountSignInRequired =>
          l10n.localProAccountSignInRequired,
        PurchaseFlowOutcome.unchanged => l10n.localProNetworkUnchanged,
        PurchaseFlowOutcome.revoked => l10n.localProRevoked,
        PurchaseFlowOutcome.verified || PurchaseFlowOutcome.restored =>
          owned ? l10n.localProOwned : l10n.localProPurchasePending,
        PurchaseFlowOutcome.unavailable => l10n.localProPurchasePending,
      },
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() async {
    final accounts = RegistryDependencies.of(context).proAccounts;
    final email = _email.text.trim();
    if (accounts == null || email.isEmpty || _accountBusy) {
      return;
    }
    setState(() => _accountBusy = true);
    try {
      final attempt = await accounts.startVerification(email);
      if (!mounted) {
        return;
      }
      setState(() => _accountMessage = _accountText(attempt));
    } finally {
      if (mounted) {
        setState(() => _accountBusy = false);
      }
    }
  }

  Future<void> _confirmCode() async {
    final accounts = RegistryDependencies.of(context).proAccounts;
    if (accounts == null || _accountBusy) {
      return;
    }
    setState(() => _accountBusy = true);
    try {
      final attempt = await accounts.confirmVerification(
        _email.text.trim(),
        _code.text.trim(),
      );
      if (!mounted) {
        return;
      }
      final session = await accounts.readSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = session;
        _accountMessage = _accountText(attempt);
      });
    } finally {
      if (mounted) {
        setState(() => _accountBusy = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final accounts = RegistryDependencies.of(context).proAccounts;
    if (accounts == null || _accountBusy) {
      return;
    }
    setState(() => _accountBusy = true);
    try {
      final attempt = await accounts.deleteAccount();
      if (!mounted) {
        return;
      }
      final session = await accounts.readSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = session;
        _accountMessage = _accountText(attempt);
      });
    } finally {
      if (mounted) {
        setState(() => _accountBusy = false);
      }
    }
  }

  String _accountText(AccountAttempt attempt) {
    final l10n = AppLocalizations.of(context);
    return switch (attempt.outcome) {
      AccountAttemptOutcome.verificationPending => l10n.localProAccountCodeSent,
      AccountAttemptOutcome.signedIn => l10n.localProAccountSignedIn(
        attempt.email ?? _account?.email ?? '',
      ),
      AccountAttemptOutcome.invalidCode => l10n.localProAccountInvalidCode,
      AccountAttemptOutcome.emailNotConfigured =>
        l10n.localProAccountNotConfigured,
      AccountAttemptOutcome.deliveryFailed =>
        l10n.localProAccountDeliveryFailed,
      AccountAttemptOutcome.offline => l10n.localProAccountOffline,
      AccountAttemptOutcome.deleted => l10n.localProAccountDeleted,
      AccountAttemptOutcome.unauthorized ||
      AccountAttemptOutcome.failed => l10n.localProAccountOffline,
    };
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.localProNotIncludedTransfer,
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
            const SizedBox(height: AppSpacing.md),
            _AccountSection(
              account: _account,
              message: _accountMessage,
              busy: _accountBusy || _buying,
              email: _email,
              code: _code,
              onSend: _sendCode,
              onConfirm: _confirmCode,
              onDelete: _deleteAccount,
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
            if (_recoveryCode != null) ...[
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.localProRecoveryTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _recoveryCode!,
                      key: const ValueKey<String>('local-pro-recovery-code'),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.localProRecoveryBody,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!owned)
              RegistryPrimaryButton(
                key: const ValueKey<String>('local-pro-buy'),
                label: l10n.localProBuy,
                onPressed: canBuy ? () => unawaited(_buy()) : null,
              ),
            if (listing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              RegistryTextField(
                fieldKey: const ValueKey<String>('local-pro-restore-code'),
                label: l10n.localProRecoveryPrompt,
                controller: _restoreCode,
                enabled: !_buying,
              ),
              const SizedBox(height: AppSpacing.sm),
              RegistryPrimaryButton(
                key: const ValueKey<String>('local-pro-restore'),
                label: l10n.localProRestore,
                onPressed: _buying ? null : () => unawaited(_restore()),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.localProRecoverySubmit,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
    required this.message,
    required this.busy,
    required this.email,
    required this.code,
    required this.onSend,
    required this.onConfirm,
    required this.onDelete,
  });

  final ProAccountSession? account;
  final String? message;
  final bool busy;
  final TextEditingController email;
  final TextEditingController code;
  final Future<void> Function() onSend;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accounts = RegistryDependencies.of(context).proAccounts;
    return RegistrySurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.localProAccountTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.localProAccountBody,
            key: const ValueKey<String>('local-pro-account-explanation'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.localProAccountBeforeBuy,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (accounts == null)
            Text(
              l10n.localProAccountUnavailable,
              key: const ValueKey<String>('local-pro-account-unavailable'),
              style: theme.textTheme.bodyMedium,
            )
          else if (account != null) ...[
            Text(
              l10n.localProAccountSignedIn(account!.email),
              key: const ValueKey<String>('local-pro-account-signed-in'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.localProAccountDeleteBody,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const ValueKey<String>('local-pro-account-delete'),
              onPressed: busy ? null : () => unawaited(onDelete()),
              child: Text(l10n.localProAccountDelete),
            ),
          ] else ...[
            RegistryTextField(
              fieldKey: const ValueKey<String>('local-pro-account-email'),
              label: l10n.localProAccountEmailLabel,
              controller: email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            RegistryPrimaryButton(
              key: const ValueKey<String>('local-pro-account-send'),
              label: l10n.localProAccountSendCode,
              onPressed: busy ? null : () => unawaited(onSend()),
            ),
            const SizedBox(height: AppSpacing.sm),
            RegistryTextField(
              fieldKey: const ValueKey<String>('local-pro-account-code'),
              label: l10n.localProAccountCodeLabel,
              controller: code,
              enabled: !busy,
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            RegistryPrimaryButton(
              key: const ValueKey<String>('local-pro-account-confirm'),
              label: l10n.localProAccountConfirm,
              onPressed: busy ? null : () => unawaited(onConfirm()),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              key: const ValueKey<String>('local-pro-account-status'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
