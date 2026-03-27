import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' show LoansCompanion;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';

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
