import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/screens/loan/loan_detail_header.dart';
import 'package:rocket_pocket/screens/loan/loan_detail_info_card.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  static const double _expandedHeight = 280.0;

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

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final remaining = loan.amount - loan.repaidAmount;
    final progress =
        loan.amount > 0
            ? (loan.repaidAmount / loan.amount).clamp(0.0, 1.0)
            : 0.0;
    final isOverdue =
        loan.status == LoanStatus.ongoing &&
        loan.dueDate.isBefore(DateTime.now());

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

    final repaymentTransactions =
        (transactionsAsync.valueOrNull ?? [])
            .where(
              (t) =>
                  t.loanId == loan.id &&
                  (t.type == TransactionType.loanRepayment ||
                      t.type == TransactionType.loanCollection),
            )
            .toList()
          ..sort((a, b) {
            final aTime = a.date ?? a.createdAt ?? DateTime(0);
            final bTime = b.date ?? b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

    final headerColor = switch (loan.status) {
      LoanStatus.completed => colorScheme.primary,
      LoanStatus.cancelled => colorScheme.outline,
      LoanStatus.overdue || _ when isOverdue => colorScheme.error,
      _ =>
        loan.type == LoanType.given
            ? colorScheme.tertiary
            : colorScheme.secondary,
    };

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Expanded header ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: _expandedHeight,
            backgroundColor: headerColor,
            foregroundColor: colorScheme.onPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  // TODO: navigate to edit loan screen
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    kToolbarHeight,
                    20,
                    16,
                  ),
                  child: LoanDetailHeader(
                    loan: loan,
                    progress: progress,
                    remaining: remaining,
                    isOverdue: isOverdue,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
              title:
                  _isCollapsed
                      ? Text(
                        loan.counterpartyName,
                        style: TextStyle(color: colorScheme.onPrimary),
                      )
                      : null,
            ),
          ),

          // ── Details card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: LoanDetailInfoCard(loan: loan, isOverdue: isOverdue),
            ),
          ),

          // ── Repayment transactions header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repayment Transactions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${repaymentTransactions.length} records',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          // ── Transaction list ─────────────────────────────────────────
          transactionsAsync.when(
            loading:
                () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            error:
                (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
            data: (_) {
              if (repaymentTransactions.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No repayment transactions yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: repaymentTransactions.length,
                itemBuilder: (context, i) {
                  final tx = repaymentTransactions[i];
                  final currency =
                      tx.senderPocketId != null
                          ? (pocketCurrency[tx.senderPocketId] ?? 'IDR')
                          : 'IDR';
                  final pocket =
                      tx.senderPocketId != null
                          ? pocketName[tx.senderPocketId]
                          : null;
                  return TransactionListTile(
                    transaction: tx,
                    currency: currency,
                    pocketName: pocket,
                  );
                },
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton:
          loan.status == LoanStatus.ongoing || loan.status == LoanStatus.overdue
              ? FloatingActionButton.extended(
                onPressed: () {
                  // TODO: navigate to add repayment transaction screen
                },
                icon: const Icon(Icons.add),
                label: Text(
                  loan.type == LoanType.given
                      ? 'Record Collection'
                      : 'Record Repayment',
                ),
              )
              : null,
    );
  }
}
