import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/core/widgets/registry_metric.dart';

enum HomeMetricTone { documents, subscriptions, attention }

class HomeMetricCard extends StatelessWidget {
  const HomeMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    this.inline = false,
    this.supportingText,
  });

  final String title;
  final String value;
  final IconData icon;
  final HomeMetricTone tone;
  final bool inline;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);
    final color = switch (tone) {
      HomeMetricTone.documents => colorScheme.onPrimaryContainer,
      HomeMetricTone.subscriptions => colorScheme.onSecondaryContainer,
      HomeMetricTone.attention => status.onUrgentContainer,
    };

    return RegistryAuraMetricCard(
      label: title,
      value: value,
      icon: icon,
      color: color,
      inline: inline,
      supportingText: supportingText,
    );
  }
}
