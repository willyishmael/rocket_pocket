import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/0_widgets/transaction_filter_sheet.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  /// Empty set means "show all types"; non-empty set filters to those types.
  final Set<TransactionType> _activeTypeFilters = {};

  /// null means "auto-select the most recent month with transactions"
  DateTime? _selectedMonth;

  TransactionSortOrder _sortOrder = TransactionSortOrder.newest;

  int _compareTransactionsByDate(Transaction a, Transaction b) {
    final aPrimaryTime = a.date ?? DateTime(0);
    final bPrimaryTime = b.date ?? DateTime(0);
    final primaryComparison = bPrimaryTime.compareTo(aPrimaryTime);
    if (primaryComparison != 0) {
      return _sortOrder == TransactionSortOrder.newest
          ? primaryComparison
          : -primaryComparison;
    }

    final aCreatedAt = a.createdAt ?? DateTime(0);
    final bCreatedAt = b.createdAt ?? DateTime(0);
    final createdAtComparison = bCreatedAt.compareTo(aCreatedAt);
    if (createdAtComparison != 0) {
      return _sortOrder == TransactionSortOrder.newest
          ? createdAtComparison
          : -createdAtComparison;
    }

    final idComparison = (b.id ?? 0).compareTo(a.id ?? 0);
    return _sortOrder == TransactionSortOrder.newest
        ? idComparison
        : -idComparison;
  }

  void _showFilterSheet() {
    showTransactionFilterSheet(
      context: context,
      activeFilters: _activeTypeFilters,
      sortOrder: _sortOrder,
      onChanged:
          (updated) => setState(() {
            _activeTypeFilters
              ..clear()
              ..addAll(updated);
          }),
      onSortChanged: (updated) => setState(() => _sortOrder = updated),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionViewModelProvider);
    final pockets = ref.watch(pocketViewModelProvider).value ?? [];
    final pocketCurrency = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.currency,
    };
    final pocketName = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.name,
    };

    final hasActiveFilters = _activeTypeFilters.isNotEmpty;

    // Derive unique months (newest first) from all loaded transactions,
    // independent of any filter so the selector is always stable.
    final allSorted = [...(transactionsAsync.value ?? <Transaction>[])]
      ..sort(_compareTransactionsByDate);

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
            : (_selectedMonth != null && seenMonths.contains(_selectedMonth!))
            ? _selectedMonth!
            : availableMonths.first;

    return Scaffold(
      floatingActionButton: _addTransactionButton(),
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
                  label: Text('${_activeTypeFilters.length}'),
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filter',
                onPressed: _showFilterSheet,
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
                onMonthSelected: (m) => setState(() => _selectedMonth = m),
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
                ..sort(_compareTransactionsByDate);

              // Apply month filter
              final monthFiltered =
                  effectiveMonth == null
                      ? sorted
                      : sorted.where((t) {
                        final d = t.date ?? t.createdAt;
                        return d != null &&
                            d.year == effectiveMonth.year &&
                            d.month == effectiveMonth.month;
                      }).toList();

              // Apply type filter
              final filtered =
                  hasActiveFilters
                      ? monthFiltered
                          .where((t) => _activeTypeFilters.contains(t.type))
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

  FloatingActionButton _addTransactionButton() {
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
