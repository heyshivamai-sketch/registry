import 'package:flutter/material.dart';

/// Angled insurance pass with translucent backing cards. Decorative only.
class RegistryHeroPassStack extends StatelessWidget {
  const RegistryHeroPassStack({super.key, this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon ?? Icons.directions_car_outlined;
    return ExcludeSemantics(
      child: SizedBox(
        width: 132,
        height: 118,
        child: IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 2,
                top: 0,
                child: Transform.rotate(
                  angle: 0.32,
                  child: const _GhostCard(
                    width: 76,
                    height: 100,
                    color: Color(0x66FFFFFF),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 8,
                child: Transform.rotate(
                  angle: 0.22,
                  child: const _GhostCard(
                    width: 82,
                    height: 106,
                    color: Color(0x8CFFFFFF),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 14,
                child: Transform.rotate(
                  angle: 0.2,
                  child: _InsurancePass(icon: glyph),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _InsurancePass extends StatelessWidget {
  const _InsurancePass({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF7), Color(0xFFE8EEF8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xD9FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10183A).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(4, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: 92,
        height: 118,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2A5C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(icon, color: const Color(0xFFE8EEF8), size: 18),
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 4; i++) ...[
                if (i != 0) const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DCE8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: SizedBox(height: 5, width: i == 3 ? 28 : 52),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
