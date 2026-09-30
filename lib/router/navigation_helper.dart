import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/budget.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/router/get_page.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/screens.dart';

// NavigationHelper is a singleton class that manages app navigation.
// This class configures and exposes the application's route tree.
class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();
  static NavigationHelper get instance => _instance;

  static late final GoRouter router;

  final GlobalKey<NavigatorState> rootNavigationKey = GlobalKey<NavigatorState>(
    debugLabel: 'rootNavigationKey',
  );
  final GlobalKey<NavigatorState> transactionNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'transactionNavigationKey');
  final GlobalKey<NavigatorState> settingsNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'settingsNavigationKey');
  final GlobalKey<NavigatorState> ledgerNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'ledgerNavigationKey');
  final GlobalKey<NavigatorState> statisticsNavigationKey =
      GlobalKey<NavigatorState>(debugLabel: 'statisticsNavigationKey');

  factory NavigationHelper() {
    return _instance;
  }

  NavigationHelper._internal() {
    final routes = <RouteBase>[
      GoRoute(path: Paths.dashboard, redirect: (_, _) => Paths.ledger),
      GoRoute(
        path: '${Paths.dashboard}/create-pocket',
        redirect: (_, _) => Paths.createPocket,
      ),
      GoRoute(
        path: '${Paths.dashboard}/pocket/:pocketId/edit',
        redirect: (_, state) {
          final pocketId = int.tryParse(state.pathParameters['pocketId'] ?? '');
          return pocketId == null
              ? Paths.ledger
              : Paths.editPocketRoute(pocketId);
        },
      ),
      GoRoute(
        path: '${Paths.dashboard}/pocket/:pocketId/pocket-transactions',
        redirect: (_, state) {
          final pocketId = int.tryParse(state.pathParameters['pocketId'] ?? '');
          return pocketId == null
              ? Paths.ledger
              : Paths.pocketTransactionsRoute(pocketId);
        },
      ),
      GoRoute(
        path: '${Paths.dashboard}/pocket/:pocketId',
        redirect: (_, state) {
          final pocketId = int.tryParse(state.pathParameters['pocketId'] ?? '');
          return pocketId == null
              ? Paths.ledger
              : Paths.pocketDetailsRoute(pocketId);
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) {
          return getPage(
            child: RootScreen(child: navigationShell),
            state: state,
          );
        },
        branches: [
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
              GoRoute(
                path: Paths.transactionDetails,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  if (extra is Transaction) {
                    return getPage(
                      child: TransactionDetailScreen(transaction: extra),
                      state: state,
                    );
                  }

                  final txIdParam = state.pathParameters['transactionId'];
                  final txId =
                      txIdParam != null ? int.tryParse(txIdParam) : null;
                  if (txId != null) {
                    return getPage(
                      child: TransactionDetailScreen(transactionId: txId),
                      state: state,
                    );
                  }

                  return getPage(child: TransactionScreen(), state: state);
                },
              ),
              GoRoute(
                path: Paths.editTransaction,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  if (extra is Transaction) {
                    return getPage(
                      child: EditTransactionScreen(transaction: extra),
                      state: state,
                    );
                  }

                  final txIdParam = state.pathParameters['transactionId'];
                  final txId =
                      txIdParam != null ? int.tryParse(txIdParam) : null;
                  if (txId != null) {
                    return getPage(
                      child: EditTransactionScreen(transactionId: txId),
                      state: state,
                    );
                  }

                  return getPage(child: TransactionScreen(), state: state);
                },
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: ledgerNavigationKey,
            routes: [
              GoRoute(
                path: Paths.ledger,
                pageBuilder: (context, state) {
                  return getPage(child: LedgerScreen(), state: state);
                },
                routes: [
                  GoRoute(
                    path: 'pockets',
                    pageBuilder:
                        (context, state) =>
                            getPage(child: PocketListScreen(), state: state),
                    routes: [
                      GoRoute(
                        path: 'create',
                        pageBuilder:
                            (context, state) => getPage(
                              child: CreatePocketScreen(),
                              state: state,
                            ),
                      ),
                      GoRoute(
                        path: ':pocketId',
                        pageBuilder: (context, state) {
                          final pocketId = int.parse(
                            state.pathParameters['pocketId']!,
                          );
                          return getPage(
                            child: PocketDetailScreen(pocketId: pocketId),
                            state: state,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'edit',
                            pageBuilder: (context, state) {
                              final pocketId = int.parse(
                                state.pathParameters['pocketId']!,
                              );
                              final pocket = state.extra;
                              return getPage(
                                child:
                                    pocket is Pocket
                                        ? EditPocketScreen(pocket: pocket)
                                        : PocketEditRouteScreen(
                                          pocketId: pocketId,
                                        ),
                                state: state,
                              );
                            },
                          ),
                          GoRoute(
                            path: 'pocket-transactions',
                            redirect:
                                (_, state) => Paths.pocketDetailsRoute(
                                  int.parse(state.pathParameters['pocketId']!),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: statisticsNavigationKey,
            routes: [
              GoRoute(
                path: Paths.statistics,
                pageBuilder: (context, state) {
                  return getPage(child: StatisticsScreen(), state: state);
                },
              ),
              GoRoute(
                path: Paths.statisticsShowMore,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  return getPage(
                    child: StatisticsBreakdownScreen(
                      initialChartType:
                          extra is StatisticsChartType ? extra : null,
                    ),
                    state: state,
                  );
                },
              ),
              GoRoute(
                path: Paths.statisticsCategoryTransactions,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  if (extra is StatisticsCategoryDrilldown) {
                    return getPage(
                      child: StatisticsCategoryTransactionsScreen(
                        drilldown: extra,
                      ),
                      state: state,
                    );
                  }

                  return getPage(child: StatisticsScreen(), state: state);
                },
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: settingsNavigationKey,
            routes: [
              GoRoute(
                path: Paths.settings,
                pageBuilder: (context, state) {
                  return getPage(child: SettingsScreen(), state: state);
                },
              ),
              GoRoute(
                path: Paths.manageCategories,
                pageBuilder: (context, state) {
                  return getPage(child: ManageCategoriesScreen(), state: state);
                },
              ),
            ],
          ),
        ],
      ),
      _budgetRoutes(),
      _loanRoutes(),
    ];

    router = GoRouter(
      navigatorKey: rootNavigationKey,
      initialLocation: Paths.ledger,
      routes: routes,
    );
  }
}

GoRoute _budgetRoutes() => GoRoute(
  path: Paths.budget,
  pageBuilder: (context, state) => getPage(child: BudgetScreen(), state: state),
  routes: [
    GoRoute(
      path: 'add',
      pageBuilder:
          (context, state) => getPage(child: AddBudgetScreen(), state: state),
    ),
    GoRoute(
      path: ':budgetId',
      pageBuilder:
          (context, state) => getPage(
            child: BudgetDetailScreen(
              budgetId: int.parse(state.pathParameters['budgetId']!),
            ),
            state: state,
          ),
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) {
            final budget = state.extra;
            final budgetId = int.parse(state.pathParameters['budgetId']!);
            return getPage(
              child:
                  budget is Budget
                      ? EditBudgetScreen(budget: budget)
                      : BudgetDetailScreen(budgetId: budgetId),
              state: state,
            );
          },
        ),
      ],
    ),
  ],
);

GoRoute _loanRoutes() => GoRoute(
  path: Paths.loan,
  pageBuilder: (context, state) => getPage(child: LoanScreen(), state: state),
  routes: [
    GoRoute(
      path: 'add',
      pageBuilder:
          (context, state) => getPage(child: AddLoanScreen(), state: state),
    ),
    GoRoute(
      path: ':loanId',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final loanId = int.parse(state.pathParameters['loanId']!);
        return getPage(
          child:
              extra is Loan
                  ? LoanDetailScreen(loan: extra)
                  : LoanDetailScreen(loanId: loanId),
          state: state,
        );
      },
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) {
            final loan = state.extra;
            final loanId = int.parse(state.pathParameters['loanId']!);
            return getPage(
              child:
                  loan is Loan
                      ? EditLoanScreen(loan: loan)
                      : LoanDetailScreen(loanId: loanId),
              state: state,
            );
          },
        ),
        GoRoute(
          path: 'repayment',
          pageBuilder: (context, state) {
            final loan = state.extra;
            final loanId = int.parse(state.pathParameters['loanId']!);
            return getPage(
              child:
                  loan is Loan
                      ? AddRepaymentScreen(loan: loan)
                      : LoanDetailScreen(loanId: loanId),
              state: state,
            );
          },
        ),
        GoRoute(
          path: 'installments',
          pageBuilder:
              (context, state) => getPage(
                child: LoanInstallmentsScreen(
                  loanId: int.parse(state.pathParameters['loanId']!),
                ),
                state: state,
              ),
        ),
      ],
    ),
  ],
);
