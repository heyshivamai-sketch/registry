import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight static engraved curves confined to one edge of a signature
/// deep-indigo Regiday document pass or priority card.
///
/// Wrapped in a [RepaintBoundary] so the vector strokes are rasterized once
/// and never cause per-frame overhead.
class PaperWalletEngraving extends StatelessWidget {
  const PaperWalletEngraving({
    super.key,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 0.12,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EngravingPainter(
            color: color.withValues(alpha: opacity),
            flipHorizontal: isRtl,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _EngravingPainter extends CustomPainter {
  const _EngravingPainter({
    required this.color,
    required this.flipHorizontal,
  });

  final Color color;
  final bool flipHorizontal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    canvas.save();
    if (flipHorizontal) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..isAntiAlias = true;

    // Anchor concentric engraved arcs off the trailing-right edge so text
    // on the leading side always sits over clean, unobstructed indigo.
    final center = Offset(size.width * 1.04, size.height * 0.42);
    final baseRadius = math.min(size.width, size.height) * 0.48;

    for (var i = 0; i < 8; i++) {
      final r = baseRadius + i * 11.5;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, math.pi * 0.62, math.pi * 0.86, false, paint);
    }

    // Subtle secondary counter-curves near the lower trailing corner.
    final accentPaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..isAntiAlias = true;

    final cornerCenter = Offset(size.width * 0.94, size.height * 1.12);
    for (var i = 0; i < 5; i++) {
      final r = baseRadius * 0.65 + i * 10.0;
      final rect = Rect.fromCircle(center: cornerCenter, radius: r);
      canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.52, false, accentPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EngravingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.flipHorizontal != flipHorizontal;
  }
}
