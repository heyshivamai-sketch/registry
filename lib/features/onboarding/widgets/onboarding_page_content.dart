import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  final Widget illustration;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.48).clamp(
          160.0,
          280.0,
        );

        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                SizedBox(
                  height: illustrationHeight,
                  width: double.infinity,
                  child: illustration,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
