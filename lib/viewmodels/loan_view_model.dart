import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/utils/enum_converter/loan_status.dart';
import 'package:rocket_pocket/utils/error_handler/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';

final loanViewModelProvider = AsyncNotifierProvider<LoanViewModel, List<Loan>>((ref) {
  final loanRepository = ref.read(loanRepositoryProvider);
  return LoanViewModel(loanRepository);
} as LoanViewModel Function());

class LoanViewModel extends AsyncNotifier<List<Loan>> {
  late final LoanRepository _loanRepository;

  LoanViewModel(this._loanRepository);

  @override
  Future<List<Loan>> build() async {
    return await _fetchLoans();
  }

  Future<List<Loan>> _fetchLoans() async {
    try {
      return await _loanRepository.getAllLoans();
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
