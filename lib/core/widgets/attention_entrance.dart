import 'package:flutter/material.dart';

/// A single gentle entrance, disabled by the system's reduced-motion setting.
class AttentionEntrance extends StatelessWidget {
  const AttentionEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translateByDouble(0, 16 * (1 - value), 0, 1)
            ..rotateX(0.06 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
