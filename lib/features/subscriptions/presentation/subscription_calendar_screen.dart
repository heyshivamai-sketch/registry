import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_calendar_view.dart';

class SubscriptionCalendarScreen extends StatelessWidget {
  const SubscriptionCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = RegistryDependencies.of(context);
    final now = deps.clock.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Calendar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: ListenableBuilder(
            listenable: deps.subscriptions,
            builder: (context, _) {
              return SubscriptionCalendarView(
                subscriptions: deps.subscriptions.subscriptions
                    .where((sub) => sub.isActive)
                    .toList(),
                now: now,
              );
            },
          ),
        ),
      ),
    );
  }
}
