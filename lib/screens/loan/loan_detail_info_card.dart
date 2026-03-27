import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/loan.dart';

class LoanDetailInfoCard extends StatelessWidget {
  final Loan loan;
  final bool isOverdue;

  const LoanDetailInfoCard({
    super.key,
    required this.loan,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Start Date',
              value: _formatDate(loan.startDate),
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Due Date',
              value: _formatDate(loan.dueDate),
              valueColor: isOverdue ? colorScheme.error : null,
            ),
            if (loan.description.isNotEmpty) ...[
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: loan.description,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
