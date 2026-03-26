import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

class AddLoanState {
  final LoanType selectedType;
  final String counterpartyName;
  final double amount;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;

  AddLoanState({
    this.selectedType = LoanType.given,
    this.counterpartyName = '',
    this.amount = 0,
    this.description = '',
    DateTime? startDate,
    DateTime? dueDate,
  }) : startDate = startDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  bool get isValid => counterpartyName.trim().isNotEmpty && amount > 0;

  AddLoanState copyWith({
    LoanType? selectedType,
    String? counterpartyName,
    double? amount,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
  }) {
    return AddLoanState(
      selectedType: selectedType ?? this.selectedType,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

final addLoanViewModelProvider =
    AsyncNotifierProvider<AddLoanViewModel, AddLoanState>(AddLoanViewModel.new);

class AddLoanViewModel extends AsyncNotifier<AddLoanState> {
  late LoanRepository _loanRepository;

  @override
  FutureOr<AddLoanState> build() {
    _loanRepository = ref.watch(loanRepositoryProvider);
    return AddLoanState();
  }

  void setType(LoanType type) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedType: type));
  }

  void setCounterpartyName(String name) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(counterpartyName: name));
  }

  void setAmount(double amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(amount: amount));
  }

  void setDescription(String description) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(description: description));
  }

  void setStartDate(DateTime date) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(startDate: date));
  }

  void setDueDate(DateTime date) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(dueDate: date));
  }

  Future<void> submit() async {
    final current = state.valueOrNull;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      final loan = Loan(
        type: current.selectedType,
        counterpartyName: current.counterpartyName.trim(),
        amount: current.amount,
        description: current.description.trim(),
        startDate: current.startDate,
        dueDate: current.dueDate,
        status: LoanStatus.ongoing,
        repaidAmount: 0,
        createdAt: DateTime.now(),
      );

      await _loanRepository.insertLoan(loan.toInsertCompanion());
      ref.invalidate(loanViewModelProvider);
      // Reset form state directly instead of self-invalidating
      state = AsyncData(AddLoanState());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
