import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/0_widgets/transaction_filter_sheet.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class PocketDetailScreen extends ConsumerStatefulWidget {
  final int pocketId;

  const PocketDetailScreen({super.key, required this.pocketId});

  @override
  ConsumerState<PocketDetailScreen> createState() => _PocketDetailScreenState();
}

class _PocketDetailScreenState extends ConsumerState<PocketDetailScreen> {
  DateTime? _selectedMonth;
  final Set<TransactionType> _activeTypeFilters = {};

  void _showFilterSheet() {
    showTransactionFilterSheet(
      context: context,
      activeFilters: _activeTypeFilters,
      onChanged:
          (updated) => setState(() {
            _activeTypeFilters
              ..clear()
              ..addAll(updated);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pockets = ref.watch(pocketViewModelProvider).valueOrNull ?? [];
    final pocket = pockets.where((p) => p.id == widget.pocketId).firstOrNull;
    final transactionsAsync = ref.watch(transactionViewModelProvider);
    final hasActiveFilters = _activeTypeFilters.isNotEmpty;
    final pocketMap = {
      for (final p in pockets)
        if (p.id != null) p.id!: p,
    };

    // Compute available months from all transactions for this pocket
    final allForPocket =
        [...(transactionsAsync.valueOrNull ?? [])]
          ..retainWhere(
            (t) =>
                t.senderPocketId == widget.pocketId ||
                t.receiverPocketId == widget.pocketId,
          )
          ..sort((a, b) {
            final aTime = a.date ?? a.createdAt ?? DateTime(0);
            final bTime = b.date ?? b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

    final availableMonths = <DateTime>[];
    final seenMonths = <DateTime>{};
    for (final t in allForPocket) {
      final d = t.date ?? t.createdAt;
      if (d == null) continue;
      final m = DateTime(d.year, d.month);
      if (seenMonths.add(m)) availableMonths.add(m);
    }

    final effectiveMonth =
        availableMonths.isEmpty
            ? null
            : (_selectedMonth != null && seenMonths.contains(_selectedMonth!))
            ? _selectedMonth!
            : availableMonths.first;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(Paths.addTransaction);
          if (!context.mounted) return;
          await ref
              .read(transactionViewModelProvider.notifier)
              .refreshTransactions();
        },
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar with embedded pocket info ────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            backgroundColor: pocket?.colorGradient.colors.first ?? Colors.blue,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace:
                pocket != null
                    ? FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(bottom: 16, top: 16),
                      title: Text(
                        pocket.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: _PocketHeader(pocket: pocket),
                    )
                    : null,
          ),

          // ── Transactions label + filter button ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            ),
          ),

          // ── Month selector ────────────────────────────────────────────
          if (availableMonths.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: MonthSelectorDelegate(
                months: availableMonths,
                selectedMonth: effectiveMonth!,
                onMonthSelected: (m) => setState(() => _selectedMonth = m),
              ),
            ),

          // ── Transaction list ──────────────────────────────────────────
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
              final sorted =
                  transactions
                      .where(
                        (t) =>
                            t.senderPocketId == widget.pocketId ||
                            t.receiverPocketId == widget.pocketId,
                      )
                      .toList()
                    ..sort((a, b) {
                      final aTime = a.date ?? a.createdAt ?? DateTime(0);
                      final bTime = b.date ?? b.createdAt ?? DateTime(0);
                      return bTime.compareTo(aTime);
                    });

              final monthFiltered =
                  effectiveMonth == null
                      ? sorted
                      : sorted.where((t) {
                        final d = t.date ?? t.createdAt;
                        return d != null &&
                            d.year == effectiveMonth.year &&
                            d.month == effectiveMonth.month;
                      }).toList();

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
                          : 'No transactions for this pocket yet.',
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final t = filtered[index];
                  final currency = pocket?.currency ?? 'IDR';
                  // For transfers, show "From → To"; otherwise omit pocket
                  // name since we're already on this pocket's screen.
                  final String? resolvedPocketName =
                      t.isTransfer
                          ? '${pocketMap[t.senderPocketId]?.name ?? '?'} → ${pocketMap[t.receiverPocketId]?.name ?? '?'}'
                          : null;
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
}

class _PocketHeader extends StatelessWidget {
  final Pocket pocket;

  const _PocketHeader({required this.pocket});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pocket.colorGradient.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: topPadding,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pocket.purpose,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyUtils.format(pocket.balance, pocket.currency),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('💳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      pocket.currency,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(pocket.emoticon, style: const TextStyle(fontSize: 64)),
        ],
      ),
    );
  }
}
