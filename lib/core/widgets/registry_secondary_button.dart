import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

class RegistrySecondaryButton extends StatelessWidget {
  const RegistrySecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding,
    this.maxLines = 1,
    this.fitText = true,
  });

  final String label;
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
    final child = fitText
        ? FittedBox(fit: BoxFit.scaleDown, child: textWidget)
        : textWidget;

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
