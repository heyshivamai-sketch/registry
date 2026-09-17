import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/add_item_sheet.dart';
import 'package:the_registry/features/documents/presentation/documents_screen.dart';
import 'package:the_registry/features/home/presentation/home_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          DocumentsScreen(),
          SubscriptionsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey<String>('home-fab'),
        tooltip: l10n.addFabTooltip,
        onPressed: () => AddItemSheet.show(
          context,
          onDocumentSaved: () {
            if (mounted) {
              setState(() => _index = 1);
            }
          },
        ),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder_rounded),
            label: l10n.navDocuments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.subscriptions_outlined),
            selectedIcon: const Icon(Icons.subscriptions_rounded),
            label: l10n.navSubscriptions,
          ),
        ],
      ),
    );
  }
}
