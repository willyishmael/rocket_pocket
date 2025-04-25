import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/router/get_page.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/budget_screen.dart';
import 'package:rocket_pocket/screens/dashboard_screen.dart';
import 'package:rocket_pocket/screens/root_screen.dart';
import 'package:rocket_pocket/screens/settings_screen.dart';
import 'package:rocket_pocket/screens/transaction_screen.dart';

/// NavigationHelper is a singleton class that manages the navigation for the app.
/// This class is responsible for managing the navigation in the app.
class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();
  static NavigationHelper get instance => _instance;

  static late final GoRouter router;

  final GlobalKey<NavigatorState> rootNavigationKey = GlobalKey<NavigatorState>(
    debugLabel: 'rootNavigationKey',
  );
  final GlobalKey<NavigatorState> dashboardNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboardNavigationKey');
  final GlobalKey<NavigatorState> transactionNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'transactionNavigationKey');
  final GlobalKey<NavigatorState> budgetNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'budgetNavigationKey');
  final GlobalKey<NavigatorState> settingsNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'settingsNavigationKey');

  factory NavigationHelper() {
    return _instance;
  }

  NavigationHelper._internal() {
    final routes = <RouteBase>[
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) {
          return getPage(
            child: RootScreen(child: navigationShell),
            state: state,
          );
        },
        branches: [
          // Dashboard Branch
          StatefulShellBranch(
            navigatorKey: dashboardNavigationKey,
            routes: [
              GoRoute(
                path: Paths.dashboard,
                pageBuilder: (context, state) {
                  return getPage(child: DashboardScreen(), state: state);
                },
              ),
            ],
          ),

          // Transaction Branch
          StatefulShellBranch(
            navigatorKey: transactionNavigationKey,
            routes: [
              GoRoute(
                path: Paths.transaction,
                pageBuilder: (context, state) {
                  return getPage(child: TransactionScreen(), state: state);
                },
              ),
            ],
          ),

          // Budget Branch
          StatefulShellBranch(
            navigatorKey: budgetNavigationKey,
            routes: [
              GoRoute(
                path: Paths.budget,
                pageBuilder: (context, state) {
                  return getPage(child: BudgetScreen(), state: state);
                },
              ),
            ],
          ),

          // Settings Branch
          StatefulShellBranch(
            navigatorKey: settingsNavigationKey,
            routes: [
              GoRoute(
                path: Paths.settings,
                pageBuilder: (context, state) {
                  return getPage(child: SettingsScreen(), state: state);
                },
              ),
            ],
          ),
        ],
      ),
    ];

    router = GoRouter(
      navigatorKey: rootNavigationKey,
      initialLocation: Paths.dashboard,
      routes: routes,
    );
  }
}
