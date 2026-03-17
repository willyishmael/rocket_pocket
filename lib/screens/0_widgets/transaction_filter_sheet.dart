import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

/// Shows a modal bottom sheet for filtering transactions by type.
///
/// [activeFilters] is the current set of active type filters.
/// [onChanged] is called (from inside the sheet) whenever the set changes,
/// so the caller can rebuild via setState.
void showTransactionFilterSheet({
  required BuildContext context,
  required Set<TransactionType> activeFilters,
  required void Function(Set<TransactionType>) onChanged,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final cleared = <TransactionType>{};
                        onChanged(cleared);
                        setSheetState(() {});
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Transaction type',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      TransactionType.values.map((type) {
                        final selected = activeFilters.contains(type);
                        return FilterChip(
                          label: Text(type.toReadableString()),
                          selected: selected,
                          onSelected: (on) {
                            final updated = Set<TransactionType>.from(
                              activeFilters,
                            );
                            on ? updated.add(type) : updated.remove(type);
                            onChanged(updated);
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
