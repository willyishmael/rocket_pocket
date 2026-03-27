import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;

  const LoanCard({super.key, required this.loan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final remaining = loan.amount - loan.repaidAmount;
    final progress =
        loan.amount > 0
            ? (loan.repaidAmount / loan.amount).clamp(0.0, 1.0)
            : 0.0;
    final isOverdue =
        loan.status == LoanStatus.ongoing &&
        loan.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      loan.counterpartyName.isNotEmpty
                          ? loan.counterpartyName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.counterpartyName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (loan.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            loan.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status chip
                  _StatusChip(status: loan.status, isOverdue: isOverdue),
                ],
              ),

              const SizedBox(height: 14),

              // ── Amount row ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        loan.amount.toStringAsFixed(2),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Repaid',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        loan.repaidAmount.toStringAsFixed(2),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        remaining.toStringAsFixed(2),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isOverdue ? colorScheme.error : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Progress bar ──────────────────────────────────────────
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: colorScheme.surfaceContainerHighest,
                color:
                    loan.status == LoanStatus.completed
                        ? colorScheme.primary
                        : isOverdue
                        ? colorScheme.error
                        : colorScheme.primary,
              ),

              const SizedBox(height: 10),

              // ── Due date row ──────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color:
                        isOverdue
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${_formatDate(loan.dueDate)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          isOverdue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  final LoanStatus status;
  final bool isOverdue;

  const _StatusChip({required this.status, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bg, fg) = switch (status) {
      LoanStatus.ongoing when isOverdue => (
        'Overdue',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      LoanStatus.ongoing => (
        'Ongoing',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      LoanStatus.completed => (
        'Completed',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      LoanStatus.overdue => (
        'Overdue',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      LoanStatus.cancelled => (
        'Cancelled',
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
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
