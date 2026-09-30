import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

Future<void> showAdjustBalanceSheet({
  required BuildContext context,
  required Pocket pocket,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AdjustBalanceSheetContent(pocket: pocket),
  );
}

class _AdjustBalanceSheetContent extends ConsumerStatefulWidget {
  const _AdjustBalanceSheetContent({required this.pocket});

  final Pocket pocket;

  @override
  ConsumerState<_AdjustBalanceSheetContent> createState() =>
      _AdjustBalanceSheetContentState();
}

class _AdjustBalanceSheetContentState
    extends ConsumerState<_AdjustBalanceSheetContent> {
  late final TextEditingController _controller;
  bool _recordAsTransaction = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.pocket.balance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oldBalance = widget.pocket.balance;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adjust Balance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'New Balance (${widget.pocket.currency})',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _recordAsTransaction,
            onChanged:
                _isSaving
                    ? null
                    : (checked) {
                      setState(() => _recordAsTransaction = checked ?? false);
                    },
            title: const Text('Record as transaction'),
            subtitle: const Text('Creates an Adjustment transaction entry.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.check),
            label: const Text('Save'),
            onPressed:
                _isSaving
                    ? null
                    : () async {
                      final newBalance = double.tryParse(_controller.text);
                      if (newBalance == null) return;
                      if (newBalance == oldBalance) {
                        if (context.mounted) Navigator.of(context).pop();
                        return;
                      }

                      setState(() => _isSaving = true);
                      try {
                        await ref
                            .read(pocketViewModelProvider.notifier)
                            .adjustBalance(
                              pocket: widget.pocket,
                              newBalance: newBalance,
                              recordAsTransaction: _recordAsTransaction,
                            );

                        if (context.mounted) Navigator.of(context).pop();
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
          ),
        ],
      ),
    );
  }
}
