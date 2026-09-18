import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class RegistryPrimaryButton extends StatelessWidget {
  const RegistryPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailing,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = trailing == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label)),
              trailing!,
            ],
          );
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
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
