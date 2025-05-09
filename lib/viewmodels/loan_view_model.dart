import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/loan_status.dart';
import 'package:rocket_pocket/data/model/loan_type.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';

/// This is the view model for managing loans in the application.
/// It uses the [LoanRepository] to perform CRUD operations on loans.
final loanViewModelProvider = AsyncNotifierProvider<LoanViewModel, List<Loan>>(
  (ref) {
        final loanRepository = ref.read(loanRepositoryProvider);
        return LoanViewModel(loanRepository);
      }
      as LoanViewModel Function(),
);

/// The [LoanViewModel] class extends [AsyncNotifier] to manage the state of loans.
class LoanViewModel extends AsyncNotifier<List<Loan>> {
  late final LoanRepository _loanRepository;

  LoanViewModel(this._loanRepository);

  @override
  Future<List<Loan>> build() async {
    return await _fetchLoans();
  }

  /// Fetches all loans from the repository and updates the state.
  Future<List<Loan>> _fetchLoans() async {
    try {
      return await _loanRepository.getAllLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Refreshes the list of loans by calling [_fetchLoans] and updating the state.
  Future<void> refreshLoans() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLoans());
  }

  /// Adds a new loan to the repository and refreshes the list of loans.
  Future<void> addLoan(LoansCompanion loan) async {
    try {
      await _loanRepository.insertLoan(loan);
      await refreshLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Fetches a loan by its ID.
  Future<Loan?> getLoanById(int id) async {
    try {
      return await _loanRepository.getLoanById(id);
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Fetches loans by their status.
  Future<List<Loan>> getLoansByStatus(LoanStatus status) async {
    try {
      return await _loanRepository.getLoansByStatus(status);
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Fetches loans by their type.
  Future<List<Loan>> getLoansByType(LoanType type) async {
    try {
      return await _loanRepository.getLoansByType(type);
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Fetches loans by the counterparty name.'
  Future<List<Loan>> getLoansByCounterpartyName(String counterpartyName) async {
    try {
      return await _loanRepository.getLoansByCounterpartyName(counterpartyName);
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Updates an existing loan in the repository and refreshes the list of loans.
  Future<void> updateLoan(LoansCompanion loan) async {
    try {
      await _loanRepository.updateLoan(loan);
      await refreshLoans();
    } on AppError catch (e) {
      state = AsyncError(e, e.stackTrace);
      e.throwError();
    }
  }

  /// Updates the status of a loan in the repository and refreshes the list of loans.
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
