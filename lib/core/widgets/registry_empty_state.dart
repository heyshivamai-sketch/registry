import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';

class RegistryEmptyState extends StatelessWidget {
  const RegistryEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? illustration;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RegistrySurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          illustration ??
              RegistryIconBadge(
                icon: icon,
                size: AppSpacing.iconLg + AppSpacing.md,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class RegistryDocumentIllustration extends StatelessWidget {
  const RegistryDocumentIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 72,
      width: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const SizedBox(width: 52, height: 64),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SizedBox(
              width: 52,
              height: 64,
              child: Icon(Icons.badge_outlined, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrySubscriptionIllustration extends StatelessWidget {
  const RegistrySubscriptionIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Icon(
          Icons.subscriptions_outlined,
          color: colorScheme.onSecondaryContainer,
          size: AppSpacing.iconLg,
        ),
      ),
    );
  }
}
