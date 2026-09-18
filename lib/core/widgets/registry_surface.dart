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
