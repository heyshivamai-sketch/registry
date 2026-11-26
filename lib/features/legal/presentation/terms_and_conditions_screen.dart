import 'package:flutter/material.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_section_header.dart';
import '../../../core/widgets/registry_surface.dart';
import '../../../l10n/app_localizations.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
        title: Text(l10n.termsTitle),
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
              icon: Icons.gavel_outlined,
              title: l10n.termsTitle,
              subtitle: l10n.termsSubtitle,
              lastUpdated: l10n.legalLastUpdated,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Highlight Cards
            _HighlightCard(
              icon: Icons.person_outline_rounded,
              accentColor: const Color(0xFF6366F1),
              title: l10n.termsHighlightPersonalTitle,
              body: l10n.termsHighlightPersonalBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.vpn_key_outlined,
              accentColor: const Color(0xFFEF4444),
              title: l10n.termsHighlightResponsibilityTitle,
              body: l10n.termsHighlightResponsibilityBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.auto_awesome_rounded,
              accentColor: const Color(0xFFF59E0B),
              title: l10n.termsHighlightAiDisclaimerTitle,
              body: l10n.termsHighlightAiDisclaimerBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HighlightCard(
              icon: Icons.info_outline_rounded,
              accentColor: const Color(0xFF0EA5E9),
              title: l10n.termsHighlightAsIsTitle,
              body: l10n.termsHighlightAsIsBody,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Detailed Terms Sections
            const _LegalClauseCard(
              sectionNumber: '1',
              title: 'Acceptance of Terms',
              icon: Icons.handshake_outlined,
              content: [
                'By downloading, installing, accessing, or using Registry ("the Application"), you agree to be bound by these Terms and Conditions. If you do not agree to all terms, do not download, install, or use the Application.',
                'These terms form a binding legal agreement between you ("User") and the operators of Registry.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '2',
              title: 'Description of Service & Local-First Philosophy',
              icon: Icons.phonelink_setup_outlined,
              content: [
                'Registry is a personal document vault, reminder manager, and subscription tracking utility designed with a local-first philosophy.',
                'The application provides offline storage for document metadata, identification dates, warranty records, recurring financial subscriptions, and encrypted attachments.',
                'No Central Server: Registry does not maintain user accounts, remote databases, or cloud synchronization servers. You retain complete ownership and physical custody of your data on your device.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '3',
              title: 'User Custody & Backup Responsibilities',
              icon: Icons.shield_outlined,
              content: [
                'Sole Responsibility for Backups: Because Registry does not store copies of your data on any server, you are solely responsible for creating regular encrypted backups (.rgry files) and safely preserving them.',
                'Loss of Data: If your device is lost, stolen, damaged, reset to factory settings, or if application data is deleted, Registry cannot restore your records. There is no account recovery or password reset mechanism.',
                'Password Preservation: Backups are encrypted with a password of your choosing using Argon2 and AES-256-GCM. If you forget or lose your backup password, your backup file cannot be decrypted or recovered by anyone, including the developers of Registry.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '4',
              title: 'Assisted AI Scanning & Verification Requirement',
              icon: Icons.document_scanner_outlined,
              content: [
                'The AI document scanning feature uses Google Gemini models via Firebase AI Logic to assist in parsing text from document photos.',
                'Optical character recognition and machine learning outputs are inherently probabilistic and may contain inaccuracies, omissions, or misinterpretations.',
                'Mandatory User Verification: You are strictly required to inspect and verify all extracted fields—especially identification numbers, holder names, date of birth, issue dates, and expiry dates—before confirming and saving any record.',
                'Registry is not responsible or liable for any consequences resulting from reliance on unverified or inaccurate AI-extracted information.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '5',
              title: 'Reminders & Notifications Disclaimer',
              icon: Icons.notifications_active_outlined,
              content: [
                'Registry schedules reminders using the operating system local notification mechanisms.',
                'Notification delivery depends upon device state, battery optimization settings, operating system permission policies (such as Do Not Disturb or low-power modes), and background task limits.',
                'Registry does not guarantee that reminders will trigger without error in all conditions. You should not rely exclusively on Registry for critical statutory renewals, passport expirations, visa deadlines, or financial obligations.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '6',
              title: 'In-App Purchases & Registry Pro',
              icon: Icons.workspace_premium_outlined,
              content: [
                'Registry offers an optional paid upgrade ("Registry Pro") providing expanded limits for documents and subscriptions.',
                'One-Time Purchase: Registry Pro is sold as a one-time purchase, not a recurring subscription.',
                'Platform Store Terms: All purchases, payments, tax assessments, and refund requests are handled exclusively by Google Play or Apple App Store according to their applicable store policies.',
                'Restoring Purchases: Registry Pro purchases can be restored on devices sharing the same platform store account. Cross-platform transfer between Android and iOS is subject to platform store rules.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '7',
              title: 'Acceptable Use & Restrictions',
              icon: Icons.rule_folder_outlined,
              content: [
                'You agree to use Registry only for lawful, personal purposes.',
                'You may not reverse-engineer, decompile, disassemble, or attempt to derive the source code of the application, except as permitted by applicable law.',
                'You may not use Registry to store or process fraudulent, infringing, or illegal materials.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '8',
              title: 'Disclaimer of Warranties',
              icon: Icons.gavel_rounded,
              content: [
                'REGISTRY IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, OR NON-INFRINGEMENT.',
                'WE DO NOT WARRANT THAT THE APPLICATION WILL BE UNINTERRUPTED, TIMELY, SECURE, OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '9',
              title: 'Limitation of Liability',
              icon: Icons.warning_amber_rounded,
              content: [
                'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL REGISTRY, ITS DEVELOPERS, AFFILIATES, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION LOSS OF DATA, DEVICE DAMAGE, FINANCIAL LOSS, MISSED RENEWAL PENALTIES, OR COST OF SUBSTITUTE GOODS.',
                'OUR TOTAL AGGREGATE LIABILITY ARISING OUT OF OR IN CONNECTION WITH THESE TERMS OR THE USE OF REGISTRY SHALL NOT EXCEED THE AMOUNT PAID BY YOU FOR REGISTRY PRO, OR TEN UNITED STATES DOLLARS (\$10.00), WHICHEVER IS GREATER.',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const _LegalClauseCard(
              sectionNumber: '10',
              title: 'Changes to Terms & Governing Law',
              icon: Icons.history_edu_outlined,
              content: [
                'We reserve the right to modify these Terms and Conditions at any time. Updated terms will be reflected within the application with a revised "Last updated" date.',
                'Your continued use of Registry after any such changes constitutes your acceptance of the new Terms and Conditions.',
                'These Terms are governed by and construed in accordance with applicable laws, excluding conflict of law principles.',
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Navigation to Privacy Policy
            RegistrySurface(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.privacyPolicyTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.privacyPolicySubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => AppRoutes.openPrivacyPolicy(context),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: Text(l10n.privacyPolicyTitle),
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
