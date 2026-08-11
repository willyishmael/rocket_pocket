import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/statistics.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/dashboard_statistics_view_model.dart';

class StatisticsCategoryTransactionsScreen extends ConsumerWidget {
  final DashboardCategoryDrilldown drilldown;

  const StatisticsCategoryTransactionsScreen({
    super.key,
    required this.drilldown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(
      dashboardCategoryTransactionRowsProvider(drilldown),
    );

    return Scaffold(
      appBar: AppBar(title: Text('${drilldown.label} Transactions')),
      body: rowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Text('Unable to load category transactions: $error'),
            ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final row = rows[index];
              final transaction = row.transaction;

              return TransactionListTile(
                transaction: transaction,
                currency: row.currency,
                pocketName: row.pocketName,
                categoryName: row.categoryName,
                onTap:
                    transaction.id == null
                        ? null
                        : () => context.push(
                          Paths.transactionDetailsRoute(transaction.id!),
                          extra: transaction,
                        ),
              );
            },
          );
        },
      ),
    );
  }
}
