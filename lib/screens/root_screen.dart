import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';

class RootScreen extends StatefulWidget {
  final StatefulNavigationShell child;

  const RootScreen({super.key, required this.child});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  // List of destinations for the bottom navigation bar and navigation rail
  final destinations = const [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Transaction'),
    NavigationDestination(icon: Icon(Icons.wallet), label: 'Budget'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AdaptiveLayout for responsive layout.
      body: AdaptiveLayout(
        bottomNavigation: SlotLayout(
          config: {
            Breakpoints.smallMobile: SlotLayout.from(
              key: const Key('bottom_navigation_bar_small_mobile'),
              builder: (_) => rootBottomNavigationBar(),
            ),
          },
        ),
        primaryNavigation: SlotLayout(
          config: {
            Breakpoints.mediumMobile: SlotLayout.from(
              key: const Key('navigation_rail_medium_mobile'),
              builder: (_) => rootNavigationRailSmall(),
            ),
            Breakpoints.mediumLargeMobile: SlotLayout.from(
              key: const Key('navigation_rail_large_mobile'),
              builder: (_) => rootNavigationRailLarge(),
            ),
          },
        ),
        body: SlotLayout(
          config: {
            Breakpoints.smallAndUp: SlotLayout.from(
              key: const Key('primary_body'),
              builder: (_) => SafeArea(child: widget.child),
            ),
          },
        ),
      ),
    );
  }

  /// Creates a bottom navigation bar for the root screen.
  Builder rootBottomNavigationBar() {
    final currentIndex = widget.child.currentIndex;

    return AdaptiveScaffold.standardBottomNavigationBar(
      onDestinationSelected: (int index) {
        widget.child.goBranch(index, initialLocation: index == currentIndex);
      },
      currentIndex: currentIndex,
      destinations: destinations,
    );
  }

  /// Creates a navigation rail for the root screen.
  Builder rootNavigationRailSmall() {
    return AdaptiveScaffold.standardNavigationRail(
      onDestinationSelected: (int index) {
        widget.child.goBranch(
          index,
          initialLocation: index == widget.child.currentIndex,
        );
      },
      selectedIndex: widget.child.currentIndex,
      destinations:
          destinations
              .map((d) => AdaptiveScaffold.toRailDestination(d))
              .toList(),
    );
  }

  /// Creates a extended navigation rail for bigger root screen.
  Builder rootNavigationRailLarge() {
    return AdaptiveScaffold.standardNavigationRail(
      onDestinationSelected: (int index) {
        widget.child.goBranch(
          index,
          initialLocation: index == widget.child.currentIndex,
        );
      },
      selectedIndex: widget.child.currentIndex,
      extended: true,
      destinations:
          destinations
              .map((d) => AdaptiveScaffold.toRailDestination(d))
              .toList(),
    );
  }
}
