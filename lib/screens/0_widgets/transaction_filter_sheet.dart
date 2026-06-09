import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

export 'package:rocket_pocket/data/model/enums.dart' show TransactionSortOrder;
import 'package:rocket_pocket/data/model/enums.dart' show TransactionSortOrder;

void showTransactionFilterSheet({
  required BuildContext context,
  required Set<TransactionType> activeFilters,
  required TransactionSortOrder sortOrder,
  required List<Pocket> pockets,
  required Set<int> activePocketFilters,
  required void Function(Set<TransactionType>) onChanged,
  required void Function(TransactionSortOrder) onSortChanged,
  required void Function(Set<int>) onPocketFilterChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      var selectedSortOrder = sortOrder;
      var selectedFilters = Set<TransactionType>.from(activeFilters);
      var selectedPocketFilters = Set<int>.from(activePocketFilters);

      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (ctx, scrollController) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 32,
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Transactions',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              selectedFilters = <TransactionType>{};
                              selectedPocketFilters = <int>{};
                              selectedSortOrder = TransactionSortOrder.newest;
                              onChanged(selectedFilters);
                              onSortChanged(selectedSortOrder);
                              onPocketFilterChanged(selectedPocketFilters);
                              setSheetState(() {});
                            },
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sort order',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<TransactionSortOrder>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: TransactionSortOrder.newest,
                              label: Text('Newest First'),
                            ),
                            ButtonSegment(
                              value: TransactionSortOrder.oldest,
                              label: Text('Oldest First'),
                            ),
                          ],
                          selected: {selectedSortOrder},
                          onSelectionChanged: (value) {
                            selectedSortOrder = value.first;
                            onSortChanged(selectedSortOrder);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Transaction type',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            TransactionType.values.map((type) {
                              final selected = selectedFilters.contains(type);
                              return FilterChip(
                                label: Text(type.toReadableString()),
                                selected: selected,
                                onSelected: (on) {
                                  final updated = Set<TransactionType>.from(
                                    selectedFilters,
                                  );
                                  on ? updated.add(type) : updated.remove(type);
                                  selectedFilters = updated;
                                  onChanged(updated);
                                  setSheetState(() {});
                                },
                              );
                            }).toList(),
                      ),
                      if (pockets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Pocket',
                          style: Theme.of(ctx).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              pockets.map((p) {
                                final selected =
                                    p.id != null &&
                                    selectedPocketFilters.contains(p.id);
                                return FilterChip(
                                  avatar: Text(p.icon),
                                  label: Text(p.name),
                                  selected: selected,
                                  onSelected: (on) {
                                    if (p.id == null) return;
                                    final updated = Set<int>.from(
                                      selectedPocketFilters,
                                    );
                                    on
                                        ? updated.add(p.id!)
                                        : updated.remove(p.id!);
                                    selectedPocketFilters = updated;
                                    onPocketFilterChanged(updated);
                                    setSheetState(() {});
                                  },
                                );
                              }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
