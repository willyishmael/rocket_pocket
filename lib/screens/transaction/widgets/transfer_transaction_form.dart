import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';

class TransferTransactionForm extends ConsumerWidget {
  const TransferTransactionForm({required this.state, super.key});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samePocket =
        state.senderPocket != null &&
        state.receiverPocket != null &&
        state.senderPocket == state.receiverPocket;
    final totalDebit = state.amount + state.adminFeeAmount;
    final insufficientBalance =
        state.senderPocket != null &&
        totalDebit > 0 &&
        totalDebit > state.senderPocket!.balance;
    final canSubmit = state.isValid && !samePocket && !insufficientBalance;

    return Column(
      children: [
        TransactionPocketDropdown(
          label: 'From Pocket',
          pockets: state.pockets,
          value: state.senderPocket,
          errorText:
              samePocket
                  ? 'From and To pocket cannot be the same'
                  : insufficientBalance
                  ? 'Insufficient balance'
                  : null,
          onChanged: (p) {
            if (p != null) {
              ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setSenderPocket(p);
            }
          },
        ),
        const SizedBox(height: 16),
        TransactionPocketDropdown(
          label: 'To Pocket',
          pockets: state.pockets,
          value: state.receiverPocket,
          errorText:
              samePocket ? 'From and To pocket cannot be the same' : null,
          onChanged: (p) {
            if (p != null) {
              ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setReceiverPocket(p);
            }
          },
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Description (optional)',
          icon: Icons.notes,
          onChanged:
              (value) => ref
                  .read(addTransactionViewModelProvider.notifier)
                  .setDescription(value),
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Amount',
          icon: Icons.payments,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setAmount(amount);
          },
        ),
        const SizedBox(height: 16),
        TransactionTextField(
          label: 'Admin Fee (optional)',
          icon: Icons.receipt_long,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref
                .read(addTransactionViewModelProvider.notifier)
                .setAdminFeeAmount(amount);
          },
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.check),
          onPressed:
              canSubmit
                  ? () async {
                    await ref
                        .read(addTransactionViewModelProvider.notifier)
                        .submit();
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                  : null,
          label: const Text('Save Transfer'),
        ),
      ],
    );
  }
}
