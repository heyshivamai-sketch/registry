import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return Semantics(
      label: '${index + 1} / $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: i == index ? AppSpacing.lg : AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: i == index
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: AppRadius.chipBorder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
