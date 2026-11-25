import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

class RegistrySecondaryButton extends StatelessWidget {
  const RegistrySecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.padding,
    this.maxLines = 1,
    this.fitText = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final int maxLines;
  final bool fitText;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      softWrap: maxLines > 1,
    );
    final textChild = fitText
        ? FittedBox(fit: BoxFit.scaleDown, child: textWidget)
        : textWidget;

    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: textChild),
            ],
          )
        : textChild;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      child: child,
    );
  }
}

typedef RegistryAuraSecondaryButton = RegistrySecondaryButton;
