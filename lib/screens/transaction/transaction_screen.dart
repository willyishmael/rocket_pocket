import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/router/paths.dart';
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _activeTypeFilters.clear());
                          setSheetState(() {});
                        },
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transaction type',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        TransactionType.values.map((type) {
                          final selected = _activeTypeFilters.contains(type);
                          return FilterChip(
                            label: Text(type.toReadableString()),
                            selected: selected,
                            onSelected: (on) {
                              setState(() {
                                on
                                    ? _activeTypeFilters.add(type)
                                    : _activeTypeFilters.remove(type);
                              });
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionViewModelProvider);
    final pockets = ref.watch(pocketViewModelProvider).valueOrNull ?? [];
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
    final allSorted = [...(transactionsAsync.valueOrNull ?? [])]..sort((a, b) {
      final aTime = a.date ?? a.createdAt ?? DateTime(0);
      final bTime = b.date ?? b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

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
            : (_selectedMonth != null &&
                seenMonths.contains(_selectedMonth!))
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
              delegate: _MonthSelectorDelegate(
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
              // Sort by transaction date (newest first), fall back to createdAt
              final sorted = [...transactions]..sort((a, b) {
                final aTime = a.date ?? a.createdAt ?? DateTime(0);
                final bTime = b.date ?? b.createdAt ?? DateTime(0);
                return bTime.compareTo(aTime);
              });

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

class _MonthSelectorDelegate extends SliverPersistentHeaderDelegate {
  final List<DateTime> months;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  const _MonthSelectorDelegate({
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month == selectedMonth;
          final label = '${_monthNames[month.month - 1]} ${month.year}';
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onMonthSelected(month),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_MonthSelectorDelegate old) =>
      months != old.months || selectedMonth != old.selectedMonth;
}
