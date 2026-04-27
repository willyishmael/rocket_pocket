// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/screens/transaction/widgets/add_transaction_header.dart';
import 'package:rocket_pocket/screens/transaction/widgets/expense_transaction_form.dart';
import 'package:rocket_pocket/screens/transaction/widgets/income_transaction_form.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transfer_transaction_form.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  Widget _buildTransactionForm({
    required BuildContext context,
    required AddTransactionState state,
  }) {
    switch (state.selectedType) {
      case TransactionType.income:
        return IncomeTransactionForm(state: state);
      case TransactionType.transfer:
        return TransferTransactionForm(state: state);
      case TransactionType.expense:
      default:
        return ExpenseTransactionForm(state: state);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelAsync = ref.watch(addTransactionViewModelProvider);

    return Scaffold(
      body: viewModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                expandedHeight: 120.0,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Add Transaction'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddTransactionHeader(state: state),
                      const SizedBox(height: 24),
                      _buildTransactionForm(context: context, state: state),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
