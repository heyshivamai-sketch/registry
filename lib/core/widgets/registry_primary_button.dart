import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

class RegistryPrimaryButton extends StatelessWidget {
  const RegistryPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailing,
    this.expanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textAlign,
    this.maxLines = 1,
    this.fitText = true,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool expanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextAlign? textAlign;
  final int maxLines;
  final bool fitText;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign ?? TextAlign.center,
      softWrap: maxLines > 1,
    );
    final labelText = fitText
        ? FittedBox(fit: BoxFit.scaleDown, child: textWidget)
        : textWidget;
    final double? trailingWidth;
    final trailingWidget = trailing;
    if (trailingWidget is Icon) {
      trailingWidth = trailingWidget.size ?? 24.0;
    } else if (trailingWidget != null) {
      trailingWidth = 18.0;
    } else {
      trailingWidth = null;
    }
    final child = trailingWidget == null
        ? labelText
        : Row(
            children: [
              SizedBox(width: trailingWidth! + AppSpacing.xs),
              Expanded(child: labelText),
              const SizedBox(width: AppSpacing.xs),
              trailingWidget,
            ],
          );
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: Size(
          expanded ? double.infinity : AppSpacing.minTapTarget,
          AppSpacing.buttonHeight,
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

typedef RegistryAuraPrimaryButton = RegistryPrimaryButton;
