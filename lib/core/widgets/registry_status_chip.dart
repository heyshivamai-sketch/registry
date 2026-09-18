import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

enum RegistryStatus { urgent, upcoming, active, expired, neutral }

extension RegistryStatusVisuals on RegistryStatus {
  Color accent(AppStatusColors colors) {
    return switch (this) {
      RegistryStatus.urgent || RegistryStatus.expired => colors.urgent,
      RegistryStatus.upcoming => colors.warning,
      RegistryStatus.active => colors.success,
      RegistryStatus.neutral => colors.expired,
    };
  }

  Color container(AppStatusColors colors, ColorScheme colorScheme) {
    return switch (this) {
      RegistryStatus.urgent || RegistryStatus.expired => colors.urgentContainer,
      RegistryStatus.upcoming => colors.warningContainer,
      RegistryStatus.active => colors.successContainer,
      RegistryStatus.neutral => colorScheme.surfaceContainer,
    };
  }

  Color onContainer(AppStatusColors colors, ColorScheme colorScheme) {
    return switch (this) {
      RegistryStatus.urgent ||
      RegistryStatus.expired => colors.onUrgentContainer,
      RegistryStatus.upcoming => colors.onWarningContainer,
      RegistryStatus.active => colors.onSuccessContainer,
      RegistryStatus.neutral => colorScheme.onSurfaceVariant,
    };
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _palette(colors, colorScheme);

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: AppRadius.chipBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Wrap(
            spacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                palette.icon,
                size: AppSpacing.md,
                color: palette.foreground,
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: palette.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusPalette _palette(AppStatusColors colors, ColorScheme colorScheme) {
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
        background: colors.urgentContainer,
        foreground: colors.onUrgentContainer,
        icon: Icons.event_busy_rounded,
      ),
      RegistryStatus.neutral => _StatusPalette(
        background: colorScheme.surfaceContainer,
        foreground: colorScheme.onSurfaceVariant,
        icon: Icons.info_outline_rounded,
      ),
    };
  }
}

typedef RegistryAuraStatusPill = RegistryStatusChip;

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
