import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/router/paths.dart';
import 'package:rocket_pocket/screens/loan/loan_card.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen>
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
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                expandedHeight: 120.0,
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
          children: const [
            _LoanListTab(type: _LoanTabType.given),
            _LoanListTab(type: _LoanTabType.taken),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add loan screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _LoanTabType { given, taken }

class _LoanListTab extends StatelessWidget {
  final _LoanTabType type;

  const _LoanListTab({required this.type});

  // TODO: replace with real data from viewmodel
  static final _stubLoans = [
    Loan(
      id: 1,
      type: LoanType.given,
      counterpartyName: 'Alice',
      amount: 500000,
      description: 'Emergency fund',
      startDate: DateTime(2026, 1, 10),
      dueDate: DateTime(2026, 4, 10),
      status: LoanStatus.ongoing,
      repaidAmount: 200000,
      createdAt: DateTime(2026, 1, 10),
    ),
    Loan(
      id: 2,
      type: LoanType.given,
      counterpartyName: 'Bob',
      amount: 200000,
      description: 'Laptop purchase',
      startDate: DateTime(2025, 11, 1),
      dueDate: DateTime(2026, 2, 1),
      status: LoanStatus.ongoing,
      repaidAmount: 0,
      createdAt: DateTime(2025, 11, 1),
    ),
    Loan(
      id: 3,
      type: LoanType.taken,
      counterpartyName: 'Jane',
      amount: 1000000,
      description: 'Rent advance',
      startDate: DateTime(2026, 2, 1),
      dueDate: DateTime(2026, 8, 1),
      status: LoanStatus.ongoing,
      repaidAmount: 300000,
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final loans =
        _stubLoans
            .where(
              (l) =>
                  type == _LoanTabType.given
                      ? l.type == LoanType.given
                      : l.type == LoanType.taken,
            )
            .toList();

    if (loans.isEmpty) {
      return Center(
        child: Text(
          type == _LoanTabType.given
              ? 'No loans given yet'
              : 'No loans taken yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: loans.length,
      itemBuilder:
          (context, index) => LoanCard(
            loan: loans[index],
            onTap:
                () => context.push(
                  Paths.loanDetailsRoute(loans[index].id!),
                  extra: loans[index],
                ),
          ),
    );
  }
}
