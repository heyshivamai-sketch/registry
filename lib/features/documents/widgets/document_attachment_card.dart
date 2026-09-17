import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
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
  });

  final Uint8List? bytes;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = bytes != null && bytes!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.attachmentSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SizedBox(
                height: 180,
                child: hasImage
                    ? ClipRRect(
                        borderRadius: AppRadius.cardBorder,
                        child: Image.memory(
                          bytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: AppSpacing.iconLg,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.attachmentEmptyLabel,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (!hasImage) ...[
                  RegistrySecondaryButton(
                    key: const ValueKey<String>('attach-camera'),
                    label: l10n.attachmentTakePhoto,
                    onPressed: onTakePhoto,
                  ),
                  RegistrySecondaryButton(
                    key: const ValueKey<String>('attach-gallery'),
                    label: l10n.attachmentChooseGallery,
                    onPressed: onChooseGallery,
                  ),
                ] else ...[
                  RegistrySecondaryButton(
                    key: const ValueKey<String>('attach-replace'),
                    label: l10n.attachmentReplace,
                    onPressed: onReplace,
                  ),
                  TextButton(
                    key: const ValueKey<String>('attach-remove'),
                    onPressed: onRemove,
                    child: Text(l10n.attachmentRemove),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.attachmentPrivacy, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
