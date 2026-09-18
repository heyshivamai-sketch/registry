import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';

class RegistryCountdownRing extends StatelessWidget {
  const RegistryCountdownRing({
    super.key,
    required this.daysUntil,
    required this.valueLabel,
    required this.unitLabel,
    required this.semanticLabel,
    required this.status,
  });

  final int daysUntil;
  final String valueLabel;
  final String unitLabel;
  final String semanticLabel;
  final RegistryStatus status;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrandColors.of(context);
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.75);
    final size = AppSpacing.countdownSize * textScale;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand.countdownFill,
          shape: BoxShape.circle,
          border: Border.all(color: brand.countdownRing, width: 5),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    valueLabel,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    unitLabel,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 9,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
