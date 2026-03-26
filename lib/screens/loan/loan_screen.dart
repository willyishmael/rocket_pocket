import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/loan/loan_card.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key});

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loanViewModelProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                expandedHeight: 182.0,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Loans'),
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 16, bottom: 48),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Loans Given'),
                    Tab(text: 'Loans Taken'),
                  ],
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _LoanListTab(
              loansAsync: loansAsync,
              type: LoanType.given,
              emptyLabel: 'No loans given yet',
            ),
            _LoanListTab(
              loansAsync: loansAsync,
              type: LoanType.taken,
              emptyLabel: 'No loans taken yet',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Paths.addLoan),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LoanListTab extends StatelessWidget {
  final AsyncValue<List<Loan>> loansAsync;
  final LoanType type;
  final String emptyLabel;

  const _LoanListTab({
    required this.loansAsync,
    required this.type,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (loans) {
        final filtered = loans.where((l) => l.type == type).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder:
              (context, index) => LoanCard(
                loan: filtered[index],
                onTap:
                    () => context.push(
                      Paths.loanDetailsRoute(filtered[index].id!),
                      extra: filtered[index],
                    ),
              ),
        );
      },
    );
  }
}
