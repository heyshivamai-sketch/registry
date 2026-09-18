import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistryMetric extends StatelessWidget {
  const RegistryMetric({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.supportingText,
    this.inline = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? supportingText;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueColor = color ?? colorScheme.onSurface;
    final valueStyle = theme.textTheme.headlineMedium?.copyWith(
      color: valueColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurface,
    );
    final supportStyle = theme.textTheme.bodySmall;

    final semantics = [label, value, ?supportingText].join(' ');

    final column = Column(
      crossAxisAlignment: inline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Icon(icon, color: valueColor, size: AppSpacing.iconMd),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Text(value, style: valueStyle),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
        if (supportingText != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            supportingText!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: supportStyle,
          ),
        ],
      ],
    );

    return Semantics(
      label: semantics,
      child: inline
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: valueColor, size: AppSpacing.iconMd),
                  const SizedBox(width: AppSpacing.sm),
                ],
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
                      if (supportingText != null)
                        Text(
                          supportingText!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: supportStyle,
                        ),
                    ],
                  ),
                ),
              ],
            )
          : column,
    );
  }
}

typedef RegistryAuraMetricCard = RegistryMetric;
