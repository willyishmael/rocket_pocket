import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/screens/loan/loan_detail_header.dart';
import 'package:rocket_pocket/screens/loan/loan_detail_info_card.dart';
import 'package:rocket_pocket/screens/transaction/transaction_list_tile.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final Loan? loan;
  final int? loanId;

  const LoanDetailScreen({super.key, this.loan, this.loanId})
    : assert(
        loan != null || loanId != null,
        'Either loan or loanId must be provided. '
        'When both are given, loan.id takes precedence over loanId.',
      );

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;
  bool _fabVisible = true;
  double _lastScrollOffset = 0;

  static const double _expandedHeight = 280.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;

      final collapsed = offset > _expandedHeight - kToolbarHeight - 8;
      if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);

      final scrollingUp = offset < _lastScrollOffset;
      final fabShouldBeVisible = scrollingUp || offset <= 0;
      if (fabShouldBeVisible != _fabVisible) {
        setState(() => _fabVisible = fabShouldBeVisible);
      }
      _lastScrollOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loanViewModelProvider);

    // Resolve the effective id: prefer widget.loan.id, then widget.loanId.
    final effectiveId = widget.loan?.id ?? widget.loanId;

    // Resolve the loan from the provider list (keeps data fresh after edits/repayments).
    final loans = loansAsync.value;
    final resolvedFromList =
        effectiveId != null
            ? loans?.where((l) => l.id == effectiveId).firstOrNull
            : null;
    final loan = resolvedFromList ?? widget.loan;

    // When only a loanId was provided and the list is still loading (or the
    // loan hasn't been found yet), show a spinner so the rest of the build
    // can assume a non-null loan.
    if (loan == null) {
      if (loansAsync.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        body: Center(child: Text('Loan #$effectiveId not found')),
      );
    }
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
    final pockets = ref.watch(pocketViewModelProvider).value ?? [];
    final pocketCurrency = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.currency,
    };
    final pocketName = {
      for (final p in pockets)
        if (p.id != null) p.id!: p.name,
    };

    final repaymentTransactions =
        (transactionsAsync.value ?? [])
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
        physics: const AlwaysScrollableScrollPhysics(),
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
                onPressed:
                    () => context.push(
                      Paths.editLoanRoute(loan.id!),
                      extra: loan,
                    ),
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
              ? AnimatedScale(
                scale: _fabVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.bottomRight,
                child: FloatingActionButton.extended(
                  onPressed:
                      () => context.push(
                        Paths.addRepaymentRoute(loan.id!),
                        extra: loan,
                      ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    loan.type == LoanType.given
                        ? 'Record Collection'
                        : 'Record Repayment',
                  ),
                ),
              )
              : null,
    );
  }
}
