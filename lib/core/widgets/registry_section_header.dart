import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistrySectionHeader extends StatelessWidget {
  const RegistrySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final titleWidget = Text(title, style: textTheme.titleMedium);
    Widget? trailing;
    if (count != null) {
      final l10n = AppLocalizations.of(context);
      trailing = Text(
        l10n.sectionItemCount(count!),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.tertiary,
          letterSpacing: 0,
        ),
      );
    } else if (actionLabel != null) {
      trailing = onAction == null
          ? Text(
              actionLabel!,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.tertiary,
              ),
            )
          : TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.tertiary,
                minimumSize: const Size(
                  AppSpacing.minTapTarget,
                  AppSpacing.minTapTarget,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: Text(actionLabel!),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: colorScheme.primary, size: AppSpacing.iconMd),
            titleWidget,
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: textTheme.bodyMedium),
        ],
      ],
    );
  }
}

typedef RegistryAuraSectionHeader = RegistrySectionHeader;
