import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';

enum RegistryDocumentStackSize { hero, tile, empty }

/// Layered passport / document / ID artwork. Decorative only.
class RegistryDocumentStack extends StatelessWidget {
  const RegistryDocumentStack({
    super.key,
    this.size = RegistryDocumentStackSize.empty,
    this.showGlow = false,
    this.heroGlyph,
  });

  final RegistryDocumentStackSize size;
  final bool showGlow;
  final IconData? heroGlyph;

  @override
  Widget build(BuildContext context) {
    final dims = switch (size) {
      RegistryDocumentStackSize.hero => const Size(128, 108),
      RegistryDocumentStackSize.tile => const Size(78, 62),
      RegistryDocumentStackSize.empty => const Size(252, 152),
    };
    final empty = size == RegistryDocumentStackSize.empty;
    final mint = AppBrandColors.of(context).mintSurface;
    final halo = Color.alphaBlend(
      const Color(0xFF6ED9C3).withValues(alpha: 0.55),
      mint,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: dims.width,
        height: dims.height,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (showGlow)
              Positioned(
                left: empty ? -18 : 4,
                right: empty ? -18 : 4,
                top: empty ? -22 : 0,
                bottom: empty ? -4 : 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        halo,
                        halo.withValues(alpha: 0.78),
                        halo.withValues(alpha: 0.28),
                        halo.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.42, 0.68, 1.0],
                    ),
                  ),
                ),
              ),
            if (showGlow)
              Positioned(
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B2758).withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 108, height: 10),
                ),
              ),
            PositionedDirectional(
              end: empty ? 18 : -2,
              top: empty ? 42 : 10,
              child: Transform.rotate(
                angle: empty ? 0.34 : 0.22,
                child: _IdCard(scale: empty ? 1.12 : 0.46),
              ),
            ),
            Positioned(
              top: empty ? 22 : 2,
              child: Transform.rotate(
                angle: empty ? 0.1 : 0.06,
                child: _PaperCard(scale: empty ? 1.08 : 0.5),
              ),
            ),
            if (!empty)
              PositionedDirectional(
                end: 10,
                top: 0,
                child: Transform.rotate(
                  angle: 0.16,
                  child: _PaperCard(scale: 0.42, faint: true),
                ),
              ),
            PositionedDirectional(
              start: empty ? 16 : 0,
              bottom: empty ? 16 : 0,
              child: Transform.rotate(
                angle: empty ? -0.22 : -0.12,
                child: _PassportCard(
                  scale: empty ? 1.12 : 0.52,
                  glyph: heroGlyph,
                  detailed: empty,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.scale, this.glyph, this.detailed = false});

  final double scale;
  final IconData? glyph;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final width = 92.0 * scale;
    final height = 124.0 * scale;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24356A), Color(0xFF16224A)],
        ),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: const Color(0xFF3B4C86).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15204A).withValues(alpha: 0.34),
            blurRadius: 22 * scale,
            offset: Offset(0, 14 * scale),
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18 * scale,
            vertical: 20 * scale,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 48 * scale,
                    height: 48 * scale,
                    child: glyph == null
                        ? CustomPaint(
                            painter: _GlobePainter(strokeWidth: 1.7 * scale),
                          )
                        : Icon(
                            glyph,
                            color: const Color(0xFFD7DEF7),
                            size: 30 * scale,
                          ),
                  ),
                ),
              ),
              if (detailed) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEF7).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                  child: SizedBox(height: 3.2 * scale, width: 36 * scale),
                ),
                SizedBox(height: 7 * scale),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEF7).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                  child: SizedBox(height: 3.2 * scale, width: 26 * scale),
                ),
                SizedBox(height: 10 * scale),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.scale, this.faint = false});

  final double scale;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: faint ? const Color(0xFFF3F0EA) : const Color(0xFFFBF9F4),
        borderRadius: BorderRadius.circular(13 * scale),
        border: Border.all(color: const Color(0xFFE4DFD6)),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF1B2758,
            ).withValues(alpha: faint ? 0.08 : 0.14),
            blurRadius: 16 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: SizedBox(
        width: 98 * scale,
        height: 126 * scale,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            18 * scale,
            16 * scale,
            16 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i != 0) SizedBox(height: 8 * scale),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(faint ? 0xFFE4DFD6 : 0xFFD8D2C8),
                    borderRadius: BorderRadius.circular(3 * scale),
                  ),
                  child: SizedBox(
                    height: 4.5 * scale,
                    width: (i == 4 ? 30 : (i.isOdd ? 46 : 58)) * scale,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE8FB), Color(0xFFDDD7F4)],
        ),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A4F9A).withValues(alpha: 0.18),
            blurRadius: 14 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: SizedBox(
        width: 108 * scale,
        height: 70 * scale,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 12 * scale,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: SizedBox(width: 28 * scale, height: 36 * scale),
              ),
              const Spacer(),
              Icon(
                Icons.person_rounded,
                color: const Color(0xFF7A73A8),
                size: 22 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final paint = Paint()
      ..color = const Color(0xFFD5DEF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 0.72, height: radius * 2),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}
