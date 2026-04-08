import 'package:flutter/material.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

/// Resolves the color associated with a [BudgetStatus] from the current theme.
Color budgetStatusColor(BudgetStatus status, ColorScheme colorScheme) {
  return switch (status) {
    BudgetStatus.overBudget => colorScheme.error,
    BudgetStatus.nearLimit => colorScheme.tertiary,
    BudgetStatus.onTrack => colorScheme.primary,
  };
}

class BudgetStatusChip extends StatelessWidget {
  final BudgetWithSpent item;
  const BudgetStatusChip({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bg, fg) = switch (item.status) {
      BudgetStatus.overBudget => (
        'Over Budget',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      BudgetStatus.nearLimit => (
        'Near Limit',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      BudgetStatus.onTrack => (
        'On Track',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
