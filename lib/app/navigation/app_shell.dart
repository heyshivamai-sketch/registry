import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/add_item_sheet.dart';
import 'package:the_registry/app/theme/app_motion.dart';
import 'package:the_registry/core/widgets/registry_navigation_dock.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';

class RegistryTabScope extends InheritedWidget {
  const RegistryTabScope({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required super.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static RegistryTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RegistryTabScope>();
  }

  @override
  bool updateShouldNotify(RegistryTabScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 0;

  int get selectedIndex => _index;

  void selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return RegistryTabScope(
      selectedIndex: _index,
      onSelect: selectTab,
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _index != 0) {
            selectTab(0);
          }
        },
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              DocumentsScreen(),
              SubscriptionsScreen(),
              ProfilePlaceholderScreen(embedded: true),
            ],
          ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: AppMotion.short,
            child: RegistryAuraNavigationDock(
              key: const ValueKey<String>('nav-dock'),
              selectedIndex: _index,
              onDestinationSelected: selectTab,
              onAddPressed: _openAdd,
            ),
          ),
        ),
      ),
    );
  }

  void _openAdd() {
    AddItemSheet.show(
      context,
      onDocumentSaved: () {
        if (mounted) {
          selectTab(1);
        }
      },
    );
  }
}
