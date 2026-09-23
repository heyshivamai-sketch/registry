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
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool expanded;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: trailing == null ? TextAlign.center : TextAlign.start,
    );
    final child = trailing == null
        ? labelText
        : Row(
            children: [
              Expanded(child: labelText),
              const SizedBox(width: AppSpacing.xs),
              trailing!,
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
