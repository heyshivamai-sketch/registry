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
    final brandViolet = colorScheme.tertiary;

    return Material(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(AppRadius.sheetAction),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sheetAction),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                RegistryAuraIconTile(
                  icon: icon,
                  size: 42,
                  background: const Color(0xFFEAE8FF),
                  foreground: brandViolet,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 3),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF737B91),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef RegistryAuraBottomSheetAction = RegistryBottomSheetAction;
