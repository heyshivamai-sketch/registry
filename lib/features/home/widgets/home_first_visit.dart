import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/home/widgets/registry_document_stack.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeFirstVisit extends StatelessWidget {
  const HomeFirstVisit({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = AppBrandColors.of(context);

    return Column(
      key: const ValueKey<String>('home-first-visit'),
      children: [
        const RegistryDocumentStack(
          size: RegistryDocumentStackSize.empty,
          showGlow: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.homeEmptyHeadline,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.homeEmptySupporting,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey<String>('home-add-first-document'),
            onPressed: () => AppRoutes.openAddDocument(context),
            style: FilledButton.styleFrom(
              backgroundColor: brand.dockSelected,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(
                AppSpacing.minTapTarget,
                AppSpacing.buttonHeight,
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.homeAddFirstDocument),
                  const SizedBox(width: 8),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const ValueKey<String>('home-add-first-subscription'),
            onPressed: () => AppRoutes.openAddSubscription(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              minimumSize: const Size(
                AppSpacing.minTapTarget,
                AppSpacing.buttonHeight,
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: colorScheme.outline),
              backgroundColor: colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.homeAddASubscription),
                  const SizedBox(width: 8),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BenefitRow(
          background: brand.mintSurface,
          icon: Icons.calendar_today_outlined,
          title: l10n.homeBenefitDatesTitle,
          message: l10n.homeBenefitDatesMessage,
        ),
        const SizedBox(height: AppSpacing.sm),
        _BenefitRow(
          background: brand.lavenderSurface,
          icon: Icons.view_list_outlined,
          title: l10n.homeBenefitPlansTitle,
          message: l10n.homeBenefitPlansMessage,
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.background,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color background;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(message, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
