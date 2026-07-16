import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/services/local_notifications_adapter.dart';

final loanReminderServiceProvider = Provider<LoanReminderService>((ref) {
  final repo = ref.watch(loanRepositoryProvider);
  final notifications = ref.watch(localNotificationsAdapterProvider);
  return LoanReminderService(repo, notifications);
});

class LoanReminderService {
  final LoanRepository _loanRepository;
  final LocalNotificationsAdapter _notifications;

  LoanReminderService(this._loanRepository, this._notifications);

  Future<void> scheduleForLoan(int loanId) async {
    final loan = await _loanRepository.getLoanById(loanId);
    if (loan == null) return;

    final installments = await _loanRepository.getInstallmentsByLoanId(loanId);

    for (final line in installments) {
      await _notifications.cancel(_notificationId(loanId, line.sequenceNo));
      await _loanRepository.setInstallmentReminderScheduledAt(line.id, null);
    }

    if (!loan.isReminderEnabled ||
        loan.status == LoanStatus.completed ||
        loan.status == LoanStatus.cancelled) {
      return;
    }

    final now = DateTime.now();
    for (final line in installments) {
      final isOutstanding =
          line.status == InstallmentStatus.unpaid.name ||
          line.status == InstallmentStatus.partial.name ||
          line.status == InstallmentStatus.overdue.name;
      if (!isOutstanding) continue;

      final scheduledAt = line.dueDate.subtract(
        Duration(days: loan.reminderDaysBefore),
      );
      if (!scheduledAt.isAfter(now)) continue;

      await _notifications.schedule(
        id: _notificationId(loanId, line.sequenceNo),
        title: 'Installment reminder',
        body:
            '${loan.counterpartyName} installment #${line.sequenceNo} is due on ${_formatDate(line.dueDate)}',
        scheduledAt: scheduledAt,
        payload: 'loan:$loanId:installment:${line.sequenceNo}',
      );

      await _loanRepository.setInstallmentReminderScheduledAt(
        line.id,
        scheduledAt,
      );
    }
  }

  Future<void> cancelForLoan(int loanId) async {
    final installments = await _loanRepository.getInstallmentsByLoanId(loanId);
    for (final line in installments) {
      await _notifications.cancel(_notificationId(loanId, line.sequenceNo));
      await _loanRepository.setInstallmentReminderScheduledAt(line.id, null);
    }
  }

  int _notificationId(int loanId, int sequenceNo) {
    return loanId * 100000 + sequenceNo;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
