// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';

class AddTransactionHeader extends ConsumerWidget {
  const AddTransactionHeader({required this.state, super.key});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addTransactionViewModelProvider.notifier);
    return TransactionTypeDateSection(
      selectedType: state.selectedType,
      date: state.date,
      onTypeChanged: notifier.setType,
      onDateChanged: notifier.setDate,
    );
  }
}
