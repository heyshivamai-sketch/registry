import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';

class RegistryBottomSheetAction extends StatelessWidget {
  const RegistryBottomSheetAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: AppRadius.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                RegistryIconBadge(icon: icon),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
