import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

class LoanInstallmentSection extends StatelessWidget {
  final Loan loan;
  final List<db.LoanInstallment> installments;

  const LoanInstallmentSection({
    super.key,
    required this.loan,
    required this.installments,
  });

  @override
  Widget build(BuildContext context) {
    if (installments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final nextDue =
        installments.where((line) {
          return line.status == InstallmentStatus.unpaid.name ||
              line.status == InstallmentStatus.partial.name ||
              line.status == InstallmentStatus.overdue.name;
        }).firstOrNull;
    final interestTotal = installments.fold<double>(
      0,
      (sum, line) => sum + line.interestDue,
    );
    final feeTotal = installments.fold<double>(
      0,
      (sum, line) => sum + line.feeDue,
    );
    final principalTotal = installments.fold<double>(
      0,
      (sum, line) => sum + line.principalDue,
    );
    final remaining = installments.fold<double>(0, (sum, line) {
      final lineRemaining = line.totalDue - line.paidAmount;
      return sum + (lineRemaining > 0 ? lineRemaining : 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Installment Schedule',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nextDue != null) ...[
                  Text('Next Due', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${nextDue.sequenceNo} on ${_formatDate(nextDue.dueDate)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        CurrencyUtils.format(
                          nextDue.totalDue - nextDue.paidAmount,
                          loan.currency,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
                _SummaryRow(
                  label: 'Installments',
                  value: '${installments.length}',
                ),
                _SummaryRow(
                  label: 'Principal',
                  value: CurrencyUtils.format(principalTotal, loan.currency),
                ),
                _SummaryRow(
                  label: 'Interest',
                  value: CurrencyUtils.format(interestTotal, loan.currency),
                ),
                _SummaryRow(
                  label: 'Fee',
                  value: CurrencyUtils.format(feeTotal, loan.currency),
                ),
                if (loan.downPaymentAmount > 0)
                  _SummaryRow(
                    label: 'Down Payment',
                    value: CurrencyUtils.format(
                      loan.downPaymentAmount,
                      loan.currency,
                    ),
                  ),
                _SummaryRow(
                  label: 'Remaining',
                  value: CurrencyUtils.format(remaining, loan.currency),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...installments.map(
          (line) => Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              title: Text('Installment #${line.sequenceNo}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Due ${_formatDate(line.dueDate)}'),
                  const SizedBox(height: 2),
                  Text(
                    'Paid ${CurrencyUtils.format(line.paidAmount, loan.currency)} of ${CurrencyUtils.format(line.totalDue, loan.currency)}',
                  ),
                ],
              ),
              trailing: _InstallmentStatusChip(status: line.status),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InstallmentStatusChip extends StatelessWidget {
  final String status;

  const _InstallmentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      'paid' => (
        'Paid',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      'partial' => (
        'Partial',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      'overdue' => (
        'Overdue',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      _ => (
        'Unpaid',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
