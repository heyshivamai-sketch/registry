import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_motion.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';

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
    final colors = AppStatusColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final progress = RegistryDateFormatter.horizonProgress(daysUntil);
    final accent = switch (status) {
      RegistryStatus.urgent => colors.urgent,
      RegistryStatus.upcoming => colors.warning,
      RegistryStatus.active => colors.success,
      RegistryStatus.expired => colors.expired,
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.75);
    final size = AppSpacing.countdownSize * textScale;

    Widget labels() {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
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
                  color: colorScheme.onPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                unitLabel,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget ring(double animatedProgress) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: CustomPaint(
                size: Size.square(size),
                painter: _CountdownPainter(
                  progress: animatedProgress,
                  trackColor: colorScheme.onPrimary.withValues(alpha: 0.18),
                  progressColor: accent,
                ),
              ),
            ),
            labels(),
          ],
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: reduceMotion
          ? ring(progress)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.short,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => ring(value),
            ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  const _CountdownPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = progressColor;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
