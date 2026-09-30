import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/budget/budget_status_chip.dart';
import 'package:rocket_pocket/screens/loan/loan_card.dart';
import 'package:rocket_pocket/screens/pocket/widgets/pocket_card.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  int _activePocketIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pocketsAsync = ref.watch(pocketViewModelProvider);
    final budgetsAsync = ref.watch(budgetViewModelProvider);
    final loansAsync = ref.watch(ledgerLoanPreviewsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Hi William!'),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeading(
              title: 'Pockets',
              route: Paths.pockets,
              onAdd: () async {
                await context.push(Paths.createPocket);
                if (!context.mounted) return;
                await ref
                    .read(pocketViewModelProvider.notifier)
                    .refreshPockets();
              },
            ),
          ),
          SliverToBoxAdapter(child: _pocketCarousel(context, pocketsAsync)),
          SliverToBoxAdapter(
            child: _SectionHeading(title: 'Budgets', route: Paths.budget),
          ),
          budgetsAsync.when(
            loading: () => const _SectionState(label: 'Loading budgets...'),
            error: (error, _) => _SectionState(label: 'Error: $error'),
            data: (budgets) {
              final previews = prioritizeBudgetPreviews(budgets);
              if (previews.isEmpty) {
                return const _SectionState(label: 'No budgets yet.');
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  for (final item in previews)
                    _BudgetPreviewTile(
                      item: item,
                      onTap:
                          () => context.push(
                            Paths.budgetDetailsRoute(item.budget.id!),
                          ),
                    ),
                ]),
              );
            },
          ),
          SliverToBoxAdapter(
            child: _SectionHeading(title: 'Loans', route: Paths.loan),
          ),
          loansAsync.when(
            loading: () => const _SectionState(label: 'Loading loans...'),
            error: (error, _) => _SectionState(label: 'Error: $error'),
            data: (loans) {
              final previews = prioritizeLoanPreviews(loans);
              if (previews.isEmpty) {
                return const _SectionState(label: 'No active loans.');
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  for (final preview in previews)
                    LoanCard(
                      loan: preview.loan,
                      nextDueDate: preview.nextDueDate,
                      isOverdue: preview.isOverdue,
                      onTap:
                          () => context.push(
                            Paths.loanDetailsRoute(preview.loan.id!),
                            extra: preview.loan,
                          ),
                    ),
                ]),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _pocketCarousel(
    BuildContext context,
    AsyncValue<List<Pocket>> pocketsAsync,
  ) {
    return SizedBox(
      height: 250,
      child: pocketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (pockets) {
          if (pockets.isEmpty) {
            return const Center(
              child: Text('No pockets yet. Use + to create one.'),
            );
          }

          final maxIndex = pockets.length - 1;
          final safeIndex = _activePocketIndex.clamp(0, maxIndex);
          if (safeIndex != _activePocketIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _activePocketIndex = safeIndex);
            });
          }

          return Swiper(
            itemCount: pockets.length,
            index: safeIndex,
            viewportFraction: 0.8,
            scale: 1.1,
            fade: 0.6,
            curve: Curves.bounceInOut,
            onIndexChanged: (index) {
              if (_activePocketIndex != index) {
                setState(() => _activePocketIndex = index);
              }
            },
            itemBuilder: (context, index) {
              final pocket = pockets[index];
              return GestureDetector(
                onTap: () => context.push(Paths.pocketDetailsRoute(pocket.id!)),
                child: PocketCard(pocket: pocket),
              );
            },
          );
        },
      ),
    );
  }
}

// These helpers stay local because they only compose Ledger section layouts.
class _SectionHeading extends StatelessWidget {
  final String title;
  final String route;
  final VoidCallback? onAdd;

  const _SectionHeading({required this.title, required this.route, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton(
            onPressed: () => context.push(route),
            child: const Text('Manage'),
          ),
          if (onAdd != null)
            IconButton.filledTonal(
              tooltip: 'Add pocket',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }
}

class _SectionState extends StatelessWidget {
  final String label;

  const _SectionState({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child:
              label.startsWith('Loading')
                  ? const CircularProgressIndicator()
                  : Text(label),
        ),
      ),
    );
  }
}

class _BudgetPreviewTile extends StatelessWidget {
  final BudgetWithSpent item;
  final VoidCallback onTap;

  const _BudgetPreviewTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.budget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BudgetStatusChip(item: item),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Budget limit: ${item.budget.amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
