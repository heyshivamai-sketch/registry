import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistrySurface extends StatelessWidget {
  const RegistrySurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color ?? colorScheme.surfaceContainerLowest,
      elevation: elevation,
      shadowColor: colorScheme.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(color: borderColor ?? colorScheme.outlineVariant),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

class RegistryIconBadge extends StatelessWidget {
  const RegistryIconBadge({
    super.key,
    required this.icon,
    this.foreground,
    this.background,
    this.size = AppSpacing.minTapTarget,
  });

  final IconData icon;
  final Color? foreground;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: foreground ?? colorScheme.onPrimaryContainer),
      ),
    );
  }
}
