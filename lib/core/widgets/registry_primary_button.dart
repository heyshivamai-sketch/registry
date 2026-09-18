import 'package:flutter/material.dart';

class RegistryPrimaryButton extends StatelessWidget {
  const RegistryPrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

typedef RegistryAuraPrimaryButton = RegistryPrimaryButton;
