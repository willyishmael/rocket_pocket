import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/router/get_page.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/screens.dart';

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
  final GlobalKey<NavigatorState> loanNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'loanNavigationKey');

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
              GoRoute(
                path: Paths.createPocket,
                pageBuilder: (context, state) {
                  return getPage(child: CreatePocketScreen(), state: state);
                },
              ),
              GoRoute(
                path: Paths.pocketDetails,
                pageBuilder: (context, state) {
                  final pocketId = int.parse(
                    state.pathParameters['pocketId']!,
                  );
                  return getPage(
                    child: PocketDetailScreen(pocketId: pocketId),
                    state: state,
                  );
                },
              ),
              GoRoute(
                path: Paths.editPocket,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  if (extra is Pocket) {
                    return getPage(
                      child: EditPocketScreen(pocket: extra),
                      state: state,
                    );
                  }

                  // Fallback: try to get pocketId from the path and show details instead.
                  final pocketIdParam = state.pathParameters['pocketId'];
                  final pocketId = pocketIdParam != null ? int.tryParse(pocketIdParam) : null;
                  if (pocketId != null) {
                    return getPage(
                      child: PocketDetailScreen(pocketId: pocketId),
                      state: state,
                    );
                  }

                  // Final fallback: navigate to dashboard if we cannot determine the pocket.
                  return getPage(
                    child: DashboardScreen(),
                    state: state,
                  );
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
              GoRoute(
                path: Paths.addTransaction,
                pageBuilder: (context, state) {
                  return getPage(child: AddTransactionScreen(), state: state);
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

          // Loan Branch
          StatefulShellBranch(
            navigatorKey: loanNavigationKey,
            routes: [
              GoRoute(
                path: Paths.loan,
                pageBuilder: (context, state) {
                  return getPage(child: LoanScreen(), state: state);
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
