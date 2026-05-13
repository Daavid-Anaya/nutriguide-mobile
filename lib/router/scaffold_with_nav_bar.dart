import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell widget that wraps all tab-based screens with a shared [NavigationBar]
/// and a [FloatingActionButton] for quick access to the scanner tab.
///
/// Receives the [StatefulNavigationShell] from [StatefulShellRoute.indexedStack]
/// and delegates all navigation state to it.
///
/// Spec: NAVIGATION-001 — shell scaffold with 4 branches + FAB
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  /// The navigation shell provided by GoRouter's [StatefulShellRoute].
  ///
  /// Manages branch state and exposes [currentIndex] + [goBranch].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigationShell.goBranch(1), // branch 1 = Scanner tab
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Lists',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
