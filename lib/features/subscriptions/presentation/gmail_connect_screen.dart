import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/data/detected_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/gmail_subscription_detection_service.dart';
import 'package:the_registry/features/subscriptions/presentation/detected_subscriptions_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class GmailConnectScreen extends StatefulWidget {
  const GmailConnectScreen({super.key});

  @override
  State<GmailConnectScreen> createState() => _GmailConnectScreenState();
}

class _GmailConnectScreenState extends State<GmailConnectScreen> {
  bool _connecting = false;
  bool _scanning = false;
  String? _errorMessage;

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _errorMessage = null;
    });
    final deps = RegistryDependencies.of(context);
    try {
      final email = await deps.gmailClient.signIn();
      if (email != null && mounted) {
        final metadata = GmailSyncMetadata(
          emailAddress: email,
          connectedAt: deps.clock.now(),
        );
        await deps.discovery.detectedRepository.saveGmailMetadata(metadata);
        // Allow the Google Sign-In activity dismissal and Android UI thread to settle
        // before requesting tokens or starting scans.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _scanEmails(silent: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _formatGmailError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    final deps = RegistryDependencies.of(context);
    await deps.gmailClient.signOut();
    await deps.discovery.detectedRepository.clearGmailMetadata();
    setState(() {});
  }

  Future<void> _scanEmails({bool silent = false}) async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    final l10n = AppLocalizations.of(context);
    final deps = RegistryDependencies.of(context);
    try {
      final currentMeta = deps.discovery.gmailMetadata;
      // Search the full billing period to catch all monthly & yearly receipts
      final messages = await deps.gmailClient.searchBillingEmails();

      final service = GmailSubscriptionDetectionService();
      final candidates = service.processMessages(
        messages: messages,
        existingSubscriptions: deps.subscriptions.subscriptions,
        ignoredMerchants: deps.discovery.ignoredMerchants,
        now: () => deps.clock.now(),
      );

      await deps.discovery.mergeAndIngestCandidates(
        candidates,
        now: () => deps.clock.now(),
      );

      if (currentMeta != null) {
        final updatedMeta = currentMeta.copyWith(
          lastSuccessfulScan: deps.clock.now(),
        );
        await deps.discovery.detectedRepository.saveGmailMetadata(updatedMeta);
      }

      if (mounted && !silent) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.gmailScanSuccess(candidates.length)),
              action: candidates.isNotEmpty
                  ? SnackBarAction(
                      label: 'View',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DetectedSubscriptionsScreen(),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _formatGmailError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  static const _gmailApiEnableUrl =
      'https://console.developers.google.com/apis/api/gmail.googleapis.com/overview?project=359772476439';

  String _formatGmailError(dynamic error) {
    final str = error.toString();
    if (str.contains('deadlock') || str.contains('main thread')) {
      return 'Google Play Services was busy authenticating. Please tap "Scan New Emails" to retry.';
    }
    if (str.contains('failed_to_recover_auth') ||
        str.contains('Failed attempt to recover authentication')) {
      return 'Google authorization could not be completed. Please tap "Connect Gmail", select your account, and grant permission to search billing receipts.';
    }
    if (str.contains('sign_in_canceled') ||
        str.contains('sign_in_failed') ||
        str.contains('CANCELED')) {
      return 'Sign-in was canceled. Please tap "Connect Gmail" to try again.';
    }
    if (str.contains('network_error') ||
        str.contains('SocketException') ||
        str.contains('Failed host lookup')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    if (str.contains('Gmail API has not been used') ||
        str.contains('gmail.googleapis.com') ||
        str.contains('DetailedApiRequestError(status: 403') ||
        str.contains('is disabled')) {
      return 'Gmail API is disabled in Google Cloud project 359772476439.\n\nEnable the Gmail API in Google Cloud Console, wait 1-2 minutes for propagation, then tap "Scan New Emails".';
    }
    if (str.contains('access_denied')) {
      return 'Permission was denied. Regiday requires read-only Gmail access to detect billing receipts.';
    }
    if (error is PlatformException &&
        error.message != null &&
        error.message!.isNotEmpty) {
      return error.message!;
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deps = RegistryDependencies.of(context);
    final metadata = deps.discovery.gmailMetadata;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectGmailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: AppShadows.card(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 28,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.connectGmailTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.gmailPrivacyNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage!.contains('Gmail API is disabled') ||
                          _errorMessage!.contains('359772476439')) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: _gmailApiEnableUrl),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Copied Gmail API Enable link to clipboard!',
                                  ),
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Enable Link'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onErrorContainer,
                              side: BorderSide(
                                color: colorScheme.onErrorContainer.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (metadata == null) ...[
                const SizedBox(height: AppSpacing.xl),
                RegistryPrimaryButton(
                  key: const ValueKey<String>('gmail-connect-button'),
                  label: _connecting ? 'Connecting...' : l10n.connectGmailButton,
                  trailing: _connecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  onPressed: _connecting ? null : _connect,
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: AppRadius.cardBorder,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n.gmailConnectedAs(metadata.emailAddress),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (metadata.lastSuccessfulScan != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.lastScan(
                              RegistryDateFormatter.dayMonthYear(
                                metadata.lastSuccessfulScan!,
                                l10n.localeName,
                              ),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                RegistryPrimaryButton(
                  key: const ValueKey<String>('gmail-scan-button'),
                  label: _scanning ? l10n.scanningEmails : l10n.scanNewEmails,
                  trailing: _scanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  onPressed: _scanning || _connecting ? null : () => _scanEmails(),
                ),
                if (_scanning) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                if (!_scanning && !_connecting) ...[
                  if (deps.discovery.pendingCandidates.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    RegistrySecondaryButton(
                      key: const ValueKey<String>('gmail-view-detected-button'),
                      label:
                          'View Detected Subscriptions (${deps.discovery.pendingCandidates.length})',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const DetectedSubscriptionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  RegistrySecondaryButton(
                    key: const ValueKey<String>('gmail-disconnect-button'),
                    label: l10n.disconnectGmailButton,
                    onPressed: _disconnect,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

