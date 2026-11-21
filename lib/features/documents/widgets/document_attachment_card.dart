import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentAttachmentCard extends StatelessWidget {
  const DocumentAttachmentCard({
    super.key,
    required this.bytes,
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.onReplace,
    required this.onRemove,
    this.badgeLabel,
    this.isSecondary = false,
  });

  final Uint8List? bytes;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final VoidCallback? onReplace;
  final VoidCallback onRemove;
  final String? badgeLabel;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasImage = bytes != null && bytes!.isNotEmpty;

    if (!hasImage) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E0D8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111936).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrySectionTitleRow(
              icon: Icons.photo_camera_outlined,
              title: badgeLabel ?? l10n.attachmentSectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6E2F6)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECE8FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          size: 22,
                          color: Color(0xFF6558F5),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.attachmentEmptyLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: RegistrySecondaryButton(
                    key: const ValueKey<String>('attach-camera'),
                    label: l10n.attachmentTakePhoto,
                    onPressed: onTakePhoto,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: RegistrySecondaryButton(
                    key: const ValueKey<String>('attach-gallery'),
                    label: l10n.attachmentChooseGallery,
                    onPressed: onChooseGallery,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E2DA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6558F5).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF111936).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDED8FA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              badgeLabel ?? l10n.attachmentSectionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4338CA),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onReplace != null)
                      TextButton.icon(
                        key: const ValueKey<String>('attach-replace'),
                        onPressed: onReplace,
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: Text(
                          l10n.attachmentReplace,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF23366C),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    IconButton(
                      key: const ValueKey<String>('attach-remove'),
                      tooltip: l10n.attachmentRemove,
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Color(0xFFDC2626),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 205,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1523),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF232C42)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(
                      bytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: _ViewfinderCorner(corner: _Corner.topLeft),
                    ),
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: _ViewfinderCorner(corner: _Corner.topRight),
                    ),
                    const Positioned(
                      bottom: 10,
                      left: 10,
                      child: _ViewfinderCorner(corner: _Corner.bottomLeft),
                    ),
                    const Positioned(
                      bottom: 10,
                      right: 10,
                      child: _ViewfinderCorner(corner: _Corner.bottomRight),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xDD0D1424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF42D8B7).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF42D8B7)),
                            SizedBox(width: 4),
                            Text(
                              "Captured",
                              style: TextStyle(
                                color: Color(0xFFE0FAF3),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: Color(0xFF8C95A8),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    l10n.attachmentPrivacy,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8293),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _ViewfinderCorner extends StatelessWidget {
  const _ViewfinderCorner({required this.corner});

  final _Corner corner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _CornerPainter(corner),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.corner);

  final _Corner corner;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF42D8B7).withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 4);
        path.quadraticBezierTo(0, 0, 4, 0);
        path.lineTo(size.width, 0);
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width - 4, 0);
        path.quadraticBezierTo(size.width, 0, size.width, 4);
        path.lineTo(size.width, size.height);
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height - 4);
        path.quadraticBezierTo(0, size.height, 4, size.height);
        path.lineTo(size.width, size.height);
      case _Corner.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width - 4, size.height);
        path.quadraticBezierTo(size.width, size.height, size.width, size.height - 4);
        path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => oldDelegate.corner != corner;
}


class RegistrySectionTitleRow extends StatelessWidget {
  const RegistrySectionTitleRow({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}
