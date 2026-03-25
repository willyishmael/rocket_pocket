import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';

class LoanDetailHeader extends StatelessWidget {
  final Loan loan;
  final double progress;
  final double remaining;
  final bool isOverdue;
  final Color foregroundColor;

  const LoanDetailHeader({
    super.key,
    required this.loan,
    required this.progress,
    required this.remaining,
    required this.isOverdue,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: foregroundColor);
    final subtleStyle = TextStyle(
      color: foregroundColor.withValues(alpha: 0.75),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar + name
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: foregroundColor.withValues(alpha: 0.2),
              child: Text(
                loan.counterpartyName.isNotEmpty
                    ? loan.counterpartyName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.counterpartyName,
                    style: textStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    loan.type == LoanType.given ? 'Loan Given' : 'Loan Taken',
                    style: subtleStyle.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Total amount
        Text('Total Amount', style: subtleStyle.copyWith(fontSize: 12)),
        Text(
          loan.amount.toStringAsFixed(2),
          style: textStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        // Progress bar
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: foregroundColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          minHeight: 6,
        ),

        const SizedBox(height: 8),

        // Repaid / remaining row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Repaid: ${loan.repaidAmount.toStringAsFixed(2)}',
              style: subtleStyle.copyWith(fontSize: 12),
            ),
            Text(
              'Remaining: ${remaining.toStringAsFixed(2)}',
              style: textStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
