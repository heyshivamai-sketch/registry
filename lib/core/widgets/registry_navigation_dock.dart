import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_motion.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryAuraNavigationDock extends StatelessWidget {
  const RegistryAuraNavigationDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  /// 0 Home, 1 Documents, 2 Subscriptions, 3 Profile.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = AppBrandColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final compact = AppSpacing.compactNavigation(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget destination({
      required int index,
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required Key key,
    }) {
      final selected = selectedIndex == index;
      final color = selected ? brand.dockSelected : brand.dockForeground;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            key: key,
            onTap: () => onDestinationSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTapTarget,
                minHeight: AppSpacing.minTapTarget,
              ),
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppMotion.short,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: AppSpacing.xxs,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        size: 20,
                        color: color,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: color,
                                fontSize: 10,
                                letterSpacing: 0,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final addButton = Semantics(
      button: true,
      label: l10n.addFabTooltip,
      child: Tooltip(
        message: l10n.addFabTooltip,
        child: SizedBox(
          width: AppSpacing.addButtonSize,
          height: AppSpacing.addButtonSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand.addStart, brand.addEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: brand.dockSelected.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.circle,
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                key: const ValueKey<String>('home-fab'),
                customBorder: const CircleBorder(),
                onTap: onAddPressed,
                child: Icon(Icons.add, color: colorScheme.onPrimary, size: 26),
              ),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.dockInset,
        0,
        AppSpacing.dockInset,
        AppSpacing.dockBottom,
      ),
      child: SizedBox(
        height: AppSpacing.dockHeight + AppSpacing.addButtonLift,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: AppRadius.dockBorder,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brand.dock,
                    borderRadius: AppRadius.dockBorder,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                    boxShadow: AppShadows.dock(context),
                  ),
                  child: SizedBox(
                    height: AppSpacing.dockHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: destination(
                              index: 0,
                              icon: Icons.home_outlined,
                              selectedIcon: Icons.home_rounded,
                              label: l10n.navHome,
                              key: const ValueKey<String>('nav-home'),
                            ),
                          ),
                          Expanded(
                            child: destination(
                              index: 1,
                              icon: Icons.description_outlined,
                              selectedIcon: Icons.description_rounded,
                              label: l10n.navDocuments,
                              key: const ValueKey<String>('nav-documents'),
                            ),
                          ),
                          const SizedBox(width: 58),
                          Expanded(
                            child: destination(
                              index: 2,
                              icon: Icons.account_balance_wallet_outlined,
                              selectedIcon: Icons.account_balance_wallet,
                              label: l10n.navSubscriptions,
                              key: const ValueKey<String>('nav-subscriptions'),
                            ),
                          ),
                          Expanded(
                            child: destination(
                              index: 3,
                              icon: Icons.person_outline,
                              selectedIcon: Icons.person,
                              label: l10n.navProfile,
                              key: const ValueKey<String>('nav-profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: -AppSpacing.addButtonLift, child: addButton),
          ],
        ),
      ),
    );
  }
}
