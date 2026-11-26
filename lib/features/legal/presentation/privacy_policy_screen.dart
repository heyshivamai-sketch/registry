import 'package:flutter/material.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_section_header.dart';
import '../../../core/widgets/registry_surface.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 720
        ? (screenWidth - 672) / 2
        : AppSpacing.screenPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            horizontalPadding,
            AppSpacing.md,
            horizontalPadding,
            AppSpacing.screenPadding,
          ),
          children: [
            _HeroHeader(
              icon: Icons.privacy_tip_outlined,
              title: l10n.privacyPolicyTitle,
              subtitle: l10n.privacyPolicySubtitle,
              lastUpdated: l10n.legalLastUpdated,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Highlight Cards
            _HighlightCard(
              icon: Icons.phonelink_lock_outlined,
              accentColor: const Color(0xFF10B981),
              title: l10n.privacyHighlightLocalTitle,
              body: l10n.privacyHighlightLocalBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.auto_awesome_rounded,
              accentColor: const Color(0xFF6366F1),
              title: l10n.privacyHighlightAiTitle,
              body: l10n.privacyHighlightAiBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.mark_email_read_outlined,
              accentColor: const Color(0xFF0EA5E9),
              title: l10n.privacyHighlightGmailTitle,
              body: l10n.privacyHighlightGmailBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.lock_outline_rounded,
              accentColor: const Color(0xFFF59E0B),
              title: l10n.privacyHighlightBackupTitle,
              body: l10n.privacyHighlightBackupBody,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Detailed Policy Sections
            const _LegalClauseCard(
              sectionNumber: '1',
              title: 'Local-First Data Architecture',
              icon: Icons.storage_outlined,
              content: [
                'Registry operates under a strict local-first architecture. All records you create—including personal identity documents, vehicle registrations, insurance policies, renewal notes, photos, and subscription details—are stored directly on your physical device in an SQLite database and protected application sandbox.',
                'Registry does not operate a central user database, remote document repository, user tracking server, or mandatory cloud account. Your data is not transmitted to, synchronized with, or backed up on Registry servers.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '2',
              title: 'AI Document Scanning (Gemini & Firebase AI Logic)',
              icon: Icons.document_scanner_outlined,
              content: [
                'Optional AI Scanning allows you to extract dates, document names, numbers, and issuing authorities from photos of your documents.',
                'Selective Transmission: Document images are only transmitted when you explicitly tap "Scan all images". Simply taking a photo, attaching an image, or saving a document never sends data over the network.',
                'Processing & Storage: Images are sent securely via Firebase AI Logic to Google Gemini models for the sole purpose of real-time structured field extraction. Registry never saves or logs your images or extracted text on external servers.',
                'User Review: Extracted fields are presented in a review interface. You retain full control to edit, correct, or discard any value before completing the save process.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '3',
              title: 'Gmail Subscription Detection (Optional)',
              icon: Icons.email_outlined,
              content: [
                'Registry provides an optional feature to detect recurring billing receipts from your Gmail account.',
                'Restricted Read-Only Access: Connecting your account requests Google OAuth permission strictly for read-only access to search for transaction and billing emails.',
                '100% On-Device Parsing: Email headers and text are scanned entirely on your device using local pattern matching and regular expressions. Your email contents are never uploaded to any cloud server, third-party AI, or external analytics service.',
                'Instant Revocation: You may disconnect Gmail at any time in the app, immediately clearing local auth tokens.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '4',
              title: 'Device Security & App Lock',
              icon: Icons.fingerprint_rounded,
              content: [
                'You can protect your registry with App Lock using your device biometric authentication (Face ID, Touch ID, Android Biometric Prompt) or device passcode.',
                'Authentication is handled entirely by your operating system security framework. Registry never accesses, captures, transmits, or stores your biometric data or PIN.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '5',
              title: 'Encrypted Backups & Data Custody',
              icon: Icons.enhanced_encryption_outlined,
              content: [
                'Because Registry has no remote cloud copy of your files, moving records to a new device is done through an encrypted backup (.rgry file).',
                'Backups are encrypted using industry-standard cryptography (Argon2 key derivation and AES-256-GCM authenticated encryption) with a password you define.',
                'You choose where to save or share your backup file (local files, Google Drive, iCloud, AirDrop, etc.). If you lose your device and do not have an encrypted backup, or if you forget your backup password, your records cannot be recovered by anyone.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '6',
              title: 'Third-Party Services & Stores',
              icon: Icons.hub_outlined,
              content: [
                'Google Play & Apple Store: In-app purchases for Registry Pro are processed entirely by the platform app stores under their respective privacy policies and payment terms.',
                'Firebase App Check: Used to verify device integrity and protect the AI Logic service against automated abuse.',
                'Advertisements (Free Tier): Free builds may include non-personalized or personalized advertising via Google Mobile Ads SDK, subject to your explicit consent choices under the User Messaging Platform (UMP). Registry never shares your documents or subscription records with advertisers. Registry Pro removes all ads.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '7',
              title: 'Data Deletion & Retention',
              icon: Icons.delete_outline_rounded,
              content: [
                'You maintain total ownership over your data. Deleting any document, subscription, or attachment in the app permanently erases it from your device.',
                'Uninstalling Registry immediately removes the local database and all associated application storage from your device.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '8',
              title: 'Contact & Updates',
              icon: Icons.contact_support_outlined,
              content: [
                'We may update this Privacy Policy from time to time. Continued use of the application signifies your acceptance of any revisions.',
                'If you have questions regarding this Privacy Policy or your data privacy, please contact support through the app store listing.',
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Navigation to Terms
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.termsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.termsSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => AppRoutes.openTermsAndConditions(context),
                    icon: const Icon(Icons.gavel_outlined),
                    label: Text(l10n.termsTitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RegistrySurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, size: 28, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadius.chipBorder,
                ),
                child: Text(
                  lastUpdated,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RegistrySurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 22, color: accentColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _LegalClauseCard extends StatelessWidget {
  const _LegalClauseCard({
    required this.sectionNumber,
    required this.title,
    required this.icon,
    required this.content,
  });

  final String sectionNumber;
  final String title;
  final IconData icon;
  final List<String> content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RegistrySurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  sectionNumber,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RegistrySectionHeader(
                  title: title,
                  icon: icon,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < content.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Text(
              content[i],
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
