import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

import 'loan_installment_section.dart';

class LoanInstallmentsScreen extends ConsumerWidget {
  final int loanId;

  const LoanInstallmentsScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loanViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installment Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          final loan = loans.where((l) => l.id == loanId).firstOrNull;
          if (loan == null) {
            return Center(child: Text('Loan #$loanId not found'));
          }

          return FutureBuilder<List<db.LoanInstallment>>(
            future: ref
                .read(loanRepositoryProvider)
                .getInstallmentsByLoanId(loanId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final installments =
                  snapshot.data ?? const <db.LoanInstallment>[];
              final effectiveInstallments =
                  installments.isNotEmpty
                      ? installments
                      : <db.LoanInstallment>[_fallbackInstallment(loan)];

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  LoanInstallmentSection(
                    loan: loan,
                    installments: effectiveInstallments,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  db.LoanInstallment _fallbackInstallment(Loan loan) {
    final now = DateTime.now();
    final remaining = (loan.amount - loan.repaidAmount).clamp(0.0, loan.amount);
    final status =
        loan.repaidAmount >= loan.amount
            ? InstallmentStatus.paid.name
            : loan.dueDate.isBefore(now)
            ? InstallmentStatus.overdue.name
            : InstallmentStatus.unpaid.name;

    return db.LoanInstallment(
      id: -loan.id!,
      loanId: loan.id!,
      sequenceNo: 1,
      dueDate: loan.dueDate,
      principalDue: remaining,
      interestDue: 0,
      feeDue: 0,
      totalDue: loan.amount,
      paidAmount: loan.repaidAmount,
      paidAt: null,
      status: status,
      reminderScheduledAt: null,
      createdAt: loan.createdAt,
      updatedAt: now,
    );
  }
}
