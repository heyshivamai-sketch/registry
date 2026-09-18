import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistrySectionHeader extends StatelessWidget {
  const RegistrySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final titleWidget = Text(title, style: textTheme.titleMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon == null)
          titleWidget
        else
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: titleWidget),
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
