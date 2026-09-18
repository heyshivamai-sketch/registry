import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistryMetric extends StatelessWidget {
  const RegistryMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.inline = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: color);

    return Semantics(
      label: '$label $value',
      child: inline
          ? Row(
              children: [
                Icon(icon, color: color, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: valueStyle),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: color, size: AppSpacing.iconMd),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: valueStyle),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ],
            ),
    );
  }
}
