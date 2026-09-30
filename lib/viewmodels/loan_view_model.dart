import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' show LoansCompanion;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

class LoanPreview {
  final Loan loan;
  final DateTime nextDueDate;

  const LoanPreview({required this.loan, required this.nextDueDate});

  bool get isOverdue => isLoanOverdue(loan, dueDate: nextDueDate);
}

// Compares due dates by calendar day and honors an explicit overdue status.
bool isLoanOverdue(Loan loan, {DateTime? dueDate, DateTime? asOf}) {
  if (loan.status == LoanStatus.overdue) return true;
  if (loan.status != LoanStatus.ongoing) return false;

  final now = asOf ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final statusDueDate = dueDate ?? loan.dueDate;
  final statusDate = DateTime(
    statusDueDate.year,
    statusDueDate.month,
    statusDueDate.day,
  );
  return statusDate.isBefore(today);
}

// Loads each active loan's next unpaid installment, falling back to its due date.
final ledgerLoanPreviewsProvider = FutureProvider<List<LoanPreview>>((
  ref,
) async {
  final loans = await ref.watch(loanViewModelProvider.future);
  final repository = ref.watch(loanRepositoryProvider);
  final activeLoans = loans.where(
    (loan) =>
        loan.status == LoanStatus.ongoing || loan.status == LoanStatus.overdue,
  );

  return Future.wait(
    activeLoans.map((loan) async {
      final installment =
          loan.id == null
              ? null
              : await repository.getNextUnpaidInstallment(loan.id!);
      return LoanPreview(
        loan: loan,
        nextDueDate: installment?.dueDate ?? loan.dueDate,
      );
    }),
  );
});

// Prioritizes overdue and near-term loans while keeping active loans as fill-ins.
List<LoanPreview> prioritizeLoanPreviews(
  Iterable<LoanPreview> loans, {
  DateTime? asOf,
  int limit = 3,
}) {
  final today = asOf ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final nearTermEnd = todayDate.add(const Duration(days: 7));
  final prioritized =
      loans
          .where(
            (preview) =>
                preview.loan.status == LoanStatus.ongoing ||
                preview.loan.status == LoanStatus.overdue,
          )
          .toList()
        ..sort((a, b) {
          int priority(LoanPreview preview) {
            final dueDate = DateTime(
              preview.nextDueDate.year,
              preview.nextDueDate.month,
              preview.nextDueDate.day,
            );
            if (preview.loan.status == LoanStatus.overdue ||
                dueDate.isBefore(todayDate)) {
              return 0;
            }
            if (!dueDate.isAfter(nearTermEnd)) return 1;
            return 2;
          }

          final priorityOrder = priority(a).compareTo(priority(b));
          if (priorityOrder != 0) return priorityOrder;
          return a.nextDueDate.compareTo(b.nextDueDate);
        });

  return prioritized.take(limit).toList(growable: false);
}

final loanViewModelProvider = AsyncNotifierProvider<LoanViewModel, List<Loan>>(
  LoanViewModel.new,
);

class LoanViewModel extends AsyncNotifier<List<Loan>> {
  late LoanRepository _loanRepository;

  @override
  Future<List<Loan>> build() async {
    _loanRepository = ref.watch(loanRepositoryProvider);
    return await _fetchLoans();
  }

  Future<List<Loan>> _fetchLoans() async {
    try {
      final rows = await _loanRepository.getAllLoans();
      return rows.map(Loan.fromDb).toList();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<void> refreshLoans() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLoans());
  }

  Future<void> addLoan(LoansCompanion loan) async {
    try {
      await _loanRepository.insertLoan(loan);
      await refreshLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<Loan?> getLoanById(int id) async {
    try {
      final row = await _loanRepository.getLoanById(id);
      return row != null ? Loan.fromDb(row) : null;
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<List<Loan>> getLoansByStatus(LoanStatus status) async {
    try {
      final rows = await _loanRepository.getLoansByStatus(status);
      return rows.map(Loan.fromDb).toList();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<List<Loan>> getLoansByType(LoanType type) async {
    try {
      final rows = await _loanRepository.getLoansByType(type);
      return rows.map(Loan.fromDb).toList();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<List<Loan>> getLoansByCounterpartyName(String counterpartyName) async {
    try {
      final rows = await _loanRepository.getLoansByCounterpartyName(
        counterpartyName,
      );
      return rows.map(Loan.fromDb).toList();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<void> updateLoan(LoansCompanion loan) async {
    try {
      await _loanRepository.updateLoan(loan);
      await refreshLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  Future<void> updateStatus(int id, LoanStatus status) async {
    try {
      await _loanRepository.updateLoanStatus(id, status);
      await refreshLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }
}
