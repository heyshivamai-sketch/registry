import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';

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
    this.onDark = false,
    this.compact = false,
  });

  final RegistryStatus status;
  final String label;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _palette(colors, colorScheme);
    final background = onDark
        ? colorScheme.onPrimary.withValues(alpha: 0.12)
        : palette.background;
    final foreground = onDark ? colorScheme.onPrimary : palette.foreground;

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.chipBorder,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 5 : 7,
          ),
          child: Wrap(
            spacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  letterSpacing: 0.2,
                  fontSize: compact ? 11 : 12,
                  height: 1.2,
                ),
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
      ),
      RegistryStatus.upcoming => _StatusPalette(
        background: colors.warningContainer,
        foreground: colors.onWarningContainer,
      ),
      RegistryStatus.active => _StatusPalette(
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
      ),
      RegistryStatus.expired => _StatusPalette(
        background: colors.urgentContainer,
        foreground: colors.onUrgentContainer,
      ),
      RegistryStatus.neutral => _StatusPalette(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
    };
  }
}

typedef RegistryAuraStatusPill = RegistryStatusChip;

class _StatusPalette {
  const _StatusPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
