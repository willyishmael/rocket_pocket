import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';
import 'package:rocket_pocket/viewmodels/viewmodel_utils.dart';

class AddLoanState {
  final LoanType selectedType;
  final String counterpartyName;
  final String currency;
  final double amount;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final List<Pocket> pockets;
  final Pocket? selectedPocket;

  AddLoanState({
    this.selectedType = LoanType.given,
    this.counterpartyName = '',
    this.currency = 'IDR',
    this.amount = 0,
    this.description = '',
    DateTime? startDate,
    DateTime? dueDate,
    this.pockets = const [],
    this.selectedPocket,
  }) : startDate = startDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  bool get isValid => counterpartyName.trim().isNotEmpty && amount > 0;

  AddLoanState copyWith({
    LoanType? selectedType,
    String? counterpartyName,
    String? currency,
    double? amount,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    List<Pocket>? pockets,
    Object? selectedPocket = absent,
  }) {
    return AddLoanState(
      selectedType: selectedType ?? this.selectedType,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      pockets: pockets ?? this.pockets,
      selectedPocket:
          selectedPocket == absent
              ? this.selectedPocket
              : selectedPocket as Pocket?,
    );
  }
}

final addLoanViewModelProvider =
    AsyncNotifierProvider<AddLoanViewModel, AddLoanState>(AddLoanViewModel.new);

class AddLoanViewModel extends AsyncNotifier<AddLoanState> {
  late LoanRepository _loanRepository;
  late PocketRepository _pocketRepository;

  @override
  FutureOr<AddLoanState> build() async {
    _loanRepository = ref.watch(loanRepositoryProvider);
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    final pockets = await _pocketRepository.getAllPockets();
    return AddLoanState(pockets: pockets);
  }

  void setType(LoanType type) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedType: type));
  }

  void setCounterpartyName(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(counterpartyName: name));
  }

  void setAmount(double amount) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(amount: amount));
  }

  void setCurrency(String currency) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(currency: currency));
  }

  void setDescription(String description) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(description: description));
  }

  void setStartDate(DateTime date) {
    final current = state.value;
    if (current == null) return;
    final adjustedDueDate =
        current.dueDate.isBefore(date) ? date : current.dueDate;
    state = AsyncData(
      current.copyWith(startDate: date, dueDate: adjustedDueDate),
    );
  }

  void setDueDate(DateTime date) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(dueDate: date));
  }

  void setSelectedPocket(Pocket? pocket) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedPocket: pocket));
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      if (current.selectedPocket != null &&
          current.selectedPocket!.currency != current.currency) {
        state = AsyncData(current);
        return;
      }

      // Loan given moves money out; require enough balance when a pocket is selected.
      if (current.selectedType == LoanType.given &&
          current.selectedPocket != null &&
          current.amount > current.selectedPocket!.balance) {
        state = AsyncData(current);
        return;
      }

      final loan = Loan(
        type: current.selectedType,
        counterpartyName: current.counterpartyName.trim(),
        currency: current.currency,
        amount: current.amount,
        description: current.description.trim(),
        startDate: current.startDate,
        dueDate: current.dueDate,
        status: LoanStatus.ongoing,
        repaidAmount: 0,
        createdAt: DateTime.now(),
      );

      await _loanRepository.insertLoan(loan.toInsertCompanion());

      // Record transaction if pocket is selected
      if (current.selectedPocket != null &&
          current.selectedPocket!.id != null) {
        final pocket = current.selectedPocket!;
        final categoryName =
            current.selectedType == LoanType.given
                ? 'Loan Given'
                : 'Loan Taken';
        final transactionType =
            current.selectedType == LoanType.given
                ? TransactionType.loanGiven
                : TransactionType.loanTaken;

        final categoryRepo = ref.read(transactionCategoryRepositoryProvider);
        final transactionRepo = ref.read(transactionRepositoryProvider);

        final category = await categoryRepo.getOrCreateSystemCategory(
          name: categoryName,
          type: transactionType,
        );

        // For loan given: debit pocket (negative amount)
        // For loan taken: credit pocket (positive amount)
        final amount =
            current.selectedType == LoanType.given
                ? -current.amount
                : current.amount;

        final transaction = Transaction(
          senderPocketId: pocket.id,
          type: transactionType,
          categoryId: category.id,
          description: 'Loan: ${current.counterpartyName}',
          amount: amount,
          date: current.startDate,
        );

        await transactionRepo.insertTransaction(
          transaction.toInsertCompanion(),
        );

        // Update pocket balance
        await _pocketRepository.updatePocket(
          pocket.copyWith(
            balance: pocket.balance + amount,
            updatedAt: DateTime.now(),
          ),
        );

        // Refresh transaction list
        await ref
            .read(transactionViewModelProvider.notifier)
            .refreshTransactions();
      }

      ref.invalidate(loanViewModelProvider);
      // Reload pockets after transaction is recorded
      final pockets = await _pocketRepository.getAllPockets();
      state = AsyncData(AddLoanState(pockets: pockets));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
