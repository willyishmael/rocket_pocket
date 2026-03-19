import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

Future<void> showAdjustBalanceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Pocket pocket,
}) {
  final controller = TextEditingController(
    text: pocket.balance.toStringAsFixed(2),
  );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust Balance',
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Balance (${pocket.currency})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              onPressed: () async {
                final newBalance = double.tryParse(controller.text);
                if (newBalance == null) return;
                await ref
                    .read(pocketViewModelProvider.notifier)
                    .updatePocket(
                      pocket.copyWith(
                        balance: newBalance,
                        updatedAt: DateTime.now(),
                      ),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
