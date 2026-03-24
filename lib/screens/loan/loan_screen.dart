import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    // TODO: replace with real data from viewmodel
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
}
