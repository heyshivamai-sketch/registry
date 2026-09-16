import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

enum RegistryStatus { urgent, upcoming, active, expired }

class RegistryStatusChip extends StatelessWidget {
  const RegistryStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  final RegistryStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context);
    final palette = _palette(colors);

    return Semantics(
      label: label,
      child: Chip(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: palette.background,
        avatar: Icon(
          palette.icon,
          size: AppSpacing.md,
          color: palette.foreground,
        ),
        label: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: palette.foreground),
        ),
      ),
    );
  }

  _StatusPalette _palette(AppStatusColors colors) {
    return switch (status) {
      RegistryStatus.urgent => _StatusPalette(
        background: colors.urgentContainer,
        foreground: colors.onUrgentContainer,
        icon: Icons.priority_high_rounded,
      ),
      RegistryStatus.upcoming => _StatusPalette(
        background: colors.warningContainer,
        foreground: colors.onWarningContainer,
        icon: Icons.schedule_rounded,
      ),
      RegistryStatus.active => _StatusPalette(
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
        icon: Icons.check_circle_outline_rounded,
      ),
      RegistryStatus.expired => _StatusPalette(
        background: colors.expiredContainer,
        foreground: colors.onExpiredContainer,
        icon: Icons.event_busy_rounded,
      ),
    };
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
