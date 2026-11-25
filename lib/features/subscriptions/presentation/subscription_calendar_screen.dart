import 'package:flutter/material.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_spacing.dart';
import 'subscription_calendar_view.dart';

class SubscriptionCalendarScreen extends StatelessWidget {
  const SubscriptionCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = RegistryDependencies.of(context);
    final now = deps.clock.now();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.xs,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscriptions',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const Text(
              'Subscription Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
