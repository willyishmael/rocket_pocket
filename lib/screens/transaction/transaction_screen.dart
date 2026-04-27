import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/0_widgets/transaction_filter_sheet.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionViewModelProvider);
    final filterState = ref.watch(transactionFilterProvider);
    final pockets = ref.watch(pocketViewModelProvider).value ?? [];

    final pocketCurrency = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.currency,
    };
    final pocketName = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.name,
    };

    final hasActiveFilters = filterState.activeTypeFilters.isNotEmpty;

    // Derive unique months (newest first) from all loaded transactions,
    // independent of any filter so the selector is always stable.
    final allSorted = [...(transactionsAsync.value ?? <Transaction>[])]
      ..sort(_compareTransactionsByDate(filterState.sortOrder));

    final availableMonths = <DateTime>[];
    final seenMonths = <DateTime>{};
    for (final t in allSorted) {
      final d = t.date ?? t.createdAt;
      if (d == null) continue;
      final m = DateTime(d.year, d.month);
      if (seenMonths.add(m)) {
        availableMonths.add(m);
      }
    }

    // Keep the current selection if it is still valid; otherwise fall back
    // to the most recent month that has transactions.
    final effectiveMonth =
        availableMonths.isEmpty
            ? null
            : (filterState.selectedMonth != null &&
                seenMonths.contains(filterState.selectedMonth!))
            ? filterState.selectedMonth!
            : availableMonths.first;

    void showFilterSheet() {
      showTransactionFilterSheet(
        context: context,
        activeFilters: filterState.activeTypeFilters,
        sortOrder: filterState.sortOrder,
        onChanged:
            (updated) => ref
                .read(transactionFilterProvider.notifier)
                .setTypeFilters(updated),
        onSortChanged:
            (updated) => ref
                .read(transactionFilterProvider.notifier)
                .setSortOrder(updated),
      );
    }

    return Scaffold(
      floatingActionButton: _addTransactionButton(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150.0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Transactions'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  label: Text('${filterState.activeTypeFilters.length}'),
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filter',
                onPressed: showFilterSheet,
              ),
            ],
          ),
          // ── Month selector ───────────────────────────────────────────
          if (availableMonths.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: MonthSelectorDelegate(
                months: availableMonths,
                selectedMonth: effectiveMonth!,
                onMonthSelected:
                    (m) => ref
                        .read(transactionFilterProvider.notifier)
                        .setSelectedMonth(m),
              ),
            ),
          transactionsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
            data: (transactions) {
              final sorted = [...transactions]
                ..sort(_compareTransactionsByDate(filterState.sortOrder));

              // Apply month filter.
              final monthFiltered =
                  effectiveMonth == null
                      ? sorted
                      : sorted.where((t) {
                        final d = t.date ?? t.createdAt;
                        return d != null &&
                            d.year == effectiveMonth.year &&
                            d.month == effectiveMonth.month;
                      }).toList();

              // Apply type filter.
              final filtered =
                  hasActiveFilters
                      ? monthFiltered
                          .where(
                            (t) =>
                                filterState.activeTypeFilters.contains(t.type),
                          )
                          .toList()
                      : monthFiltered;

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      hasActiveFilters
                          ? 'No transactions match the current filters.'
                          : 'No transactions yet.',
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final t = filtered[index];
                  final currency =
                      pocketCurrency[t.senderPocketId] ??
                      pocketCurrency[t.receiverPocketId] ??
                      'IDR';
                  final String? resolvedPocketName =
                      t.isTransfer
                          ? '${pocketName[t.senderPocketId] ?? '?'} → ${pocketName[t.receiverPocketId] ?? '?'}'
                          : pocketName[t.senderPocketId] ??
                              pocketName[t.receiverPocketId];
                  return TransactionListTile(
                    transaction: t,
                    currency: currency,
                    pocketName: resolvedPocketName,
                    onTap:
                        t.id == null
                            ? null
                            : () => context.push(
                              Paths.transactionDetailsRoute(t.id!),
                              extra: t,
                            ),
                  );
                }, childCount: filtered.length),
              );
            },
          ),
        ],
      ),
    );
  }

  FloatingActionButton _addTransactionButton(
    BuildContext context,
    WidgetRef ref,
  ) {
    return FloatingActionButton(
      onPressed: () async {
        await context.push(Paths.addTransaction);
        if (!context.mounted) return;
        await ref
            .read(transactionViewModelProvider.notifier)
            .refreshTransactions();
      },
      child: const Icon(Icons.add),
    );
  }
}

/// Returns a comparator for transactions that respects the given [sortOrder].
Comparator<Transaction> _compareTransactionsByDate(
  TransactionSortOrder sortOrder,
) {
  return (a, b) {
    final aPrimaryTime = a.date ?? DateTime(0);
    final bPrimaryTime = b.date ?? DateTime(0);
    final primaryComparison = bPrimaryTime.compareTo(aPrimaryTime);
    if (primaryComparison != 0) {
      return sortOrder == TransactionSortOrder.newest
          ? primaryComparison
          : -primaryComparison;
    }

    final aCreatedAt = a.createdAt ?? DateTime(0);
    final bCreatedAt = b.createdAt ?? DateTime(0);
    final createdAtComparison = bCreatedAt.compareTo(aCreatedAt);
    if (createdAtComparison != 0) {
      return sortOrder == TransactionSortOrder.newest
          ? createdAtComparison
          : -createdAtComparison;
    }

    final idComparison = (b.id ?? 0).compareTo(a.id ?? 0);
    return sortOrder == TransactionSortOrder.newest
        ? idComparison
        : -idComparison;
  };
}
