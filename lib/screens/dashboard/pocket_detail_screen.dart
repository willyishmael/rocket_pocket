import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/0_widgets/adjust_balance_sheet.dart';
import 'package:rocket_pocket/screens/0_widgets/month_selector_delegate.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_header.dart';
import 'package:rocket_pocket/screens/0_widgets/transaction_filter_sheet.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
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
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  // expandedHeight - kToolbarHeight = the threshold where the bar is fully collapsed
  static const double _expandedHeight = 250.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final collapsed =
          _scrollController.hasClients &&
          _scrollController.offset > _expandedHeight - kToolbarHeight - 8;
      if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        controller: _scrollController,
        slivers: [
          // ── Gradient app bar with embedded pocket info ────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            backgroundColor: pocket?.colorGradient.colors.first ?? Colors.blue,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title:
                _isCollapsed
                    ? Text(
                      pocket?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
            actions: [
              if (pocket != null) ...[
                IconButton(
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Adjust Balance',
                  onPressed:
                      () => showAdjustBalanceSheet(
                        context: context,
                        ref: ref,
                        pocket: pocket,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit Pocket',
                  onPressed:
                      () => context.push(
                        Paths.editPocketRoute(pocket.id!),
                        extra: pocket,
                      ),
                ),
              ],
            ],
            flexibleSpace:
                pocket != null
                    ? FlexibleSpaceBar(background: PocketHeader(pocket: pocket))
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
