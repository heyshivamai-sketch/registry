import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool expanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign ?? TextAlign.center,
    );
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

typedef RegistryAuraPrimaryButton = RegistryPrimaryButton;
