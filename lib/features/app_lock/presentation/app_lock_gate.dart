import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/features/app_lock/app_lock_controller.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lock = RegistryDependencies.of(context).appLock;
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        final locked = lock.sessionLocked;
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              excluding: locked || lock.obscured,
              child: IgnorePointer(
                ignoring: locked || lock.obscured,
                child: TickerMode(
                  enabled: !locked && !lock.obscured,
                  child: Offstage(offstage: locked, child: child),
                ),
              ),
            ),
            if (locked) const AppLockScreen(),
            if (lock.obscured && !locked) const AppPrivacyCover(),
          ],
        );
      },
    );
  }
}

class AppPrivacyCover extends StatelessWidget {
  const AppPrivacyCover({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ColoredBox(
      key: const ValueKey<String>('app-privacy-cover'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Text(
            l10n.appLockPrivacyCover,
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

class AppLockScreen extends StatelessWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lock = RegistryDependencies.of(context).appLock;
    final block = lock.block;
    final detail = switch (block) {
      AppLockBlock.cancelled => l10n.appLockUnlockCancelled,
      AppLockBlock.failed => l10n.appLockUnlockFailed,
      AppLockBlock.unavailable => l10n.appLockUnlockUnavailable,
      AppLockBlock.platformError => l10n.appLockUnlockPlatformError,
      null => l10n.appLockLockedBody,
    };
    return ColoredBox(
      key: const ValueKey<String>('app-lock-screen'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: AppSpacing.iconLg,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.appLockLockedTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RegistryPrimaryButton(
                        key: const ValueKey<String>('app-lock-unlock'),
                        label: l10n.appLockUnlock,
                        expanded: false,
                        onPressed: lock.authenticating
                            ? null
                            : () => lock.unlock(
                                localizedReason: l10n.appLockReason,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
