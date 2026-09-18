import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistrySurface extends StatelessWidget {
  const RegistrySurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.elevation = 0,
    this.borderRadius,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double elevation;
  final BorderRadius? borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppRadius.cardBorder;

    return Material(
      color: color ?? colorScheme.surfaceContainerLowest,
      elevation: elevation,
      shadowColor: colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: showBorder
            ? BorderSide(color: borderColor ?? colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

typedef RegistryAuraSurface = RegistrySurface;

class RegistryIconBadge extends StatelessWidget {
  const RegistryIconBadge({
    super.key,
    required this.icon,
    this.foreground,
    this.background,
    this.size = AppSpacing.iconTile,
    this.semanticColor,
  });

  final IconData icon;
  final Color? foreground;
  final Color? background;
  final double size;
  final Color? semanticColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg =
        background ??
        semanticColor?.withValues(alpha: 0.14) ??
        colorScheme.primaryContainer;
    final fg = foreground ?? semanticColor ?? colorScheme.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.iconTile),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: fg),
      ),
    );
  }
}

typedef RegistryAuraIconTile = RegistryIconBadge;

enum RegistryCalloutTone { privacy, tip, warning }

class RegistryCallout extends StatelessWidget {
  const RegistryCallout({
    super.key,
    required this.message,
    this.title,
    this.tone = RegistryCalloutTone.privacy,
  });

  final String message;
  final String? title;
  final RegistryCalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      RegistryCalloutTone.privacy => (
        background: const Color(0xFFE9FAF6),
        foreground: const Color(0xFF146A5D),
        muted: const Color(0xFF146A5D),
      ),
      RegistryCalloutTone.tip => (
        background: const Color(0xFFF0EFFF),
        foreground: const Color(0xFF4B4594),
        muted: const Color(0xFF68708B),
      ),
      RegistryCalloutTone.warning => (
        background: const Color(0xFFFFF2EF),
        foreground: const Color(0xFF8E3934),
        muted: const Color(0xFF8E3934),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: title == null ? colors.foreground : colors.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistryInfoRow extends StatelessWidget {
  const RegistryInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistryElevatedSurface extends StatelessWidget {
  const RegistryElevatedSurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppRadius.cardBorder;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}
