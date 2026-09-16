import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/features/design_preview/presentation/design_preview_screen.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/widgets/onboarding_illustrations.dart';
import 'package:the_registry/features/onboarding/widgets/onboarding_page_content.dart';
import 'package:the_registry/features/onboarding/widgets/onboarding_page_indicator.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.repository});

  final OnboardingRepository repository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _pageDuration(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
  }

  Future<void> _goTo(int index) {
    return _controller.animateToPage(
      index,
      duration: _pageDuration(context),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await widget.repository.complete();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DesignPreviewScreen()),
    );
  }

  void _onSystemBack() {
    if (_index > 0) {
      _goTo(_index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLastPage = _index == _pageCount - 1;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onSystemBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: AppSpacing.minTapTarget,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: isLastPage
                      ? const SizedBox.shrink()
                      : TextButton(
                          key: const ValueKey<String>('onboarding-skip'),
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              AppSpacing.minTapTarget,
                              AppSpacing.minTapTarget,
                            ),
                          ),
                          child: Text(l10n.onboardingSkip),
                        ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: [
                    OnboardingPageContent(
                      illustration: DatesIllustration(l10n: l10n),
                      title: l10n.onboardingPage1Title,
                      subtitle: l10n.onboardingPage1Subtitle,
                    ),
                    OnboardingPageContent(
                      illustration: SubscriptionsIllustration(l10n: l10n),
                      title: l10n.onboardingPage2Title,
                      subtitle: l10n.onboardingPage2Subtitle,
                    ),
                    OnboardingPageContent(
                      illustration: PrivacyIllustration(l10n: l10n),
                      title: l10n.onboardingPage3Title,
                      subtitle: l10n.onboardingPage3Subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OnboardingPageIndicator(count: _pageCount, index: _index),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: RegistryPrimaryButton(
                    key: ValueKey<String>(
                      isLastPage
                          ? 'onboarding-get-started'
                          : 'onboarding-continue',
                    ),
                    label: isLastPage
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingContinue,
                    onPressed: isLastPage ? _complete : () => _goTo(_index + 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
