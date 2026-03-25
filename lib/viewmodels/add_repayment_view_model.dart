import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/loan_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class AddRepaymentState {
  final List<Pocket> pockets;
  final Pocket? selectedPocket;
  final double amount;
  final String description;
  final DateTime date;

  AddRepaymentState({
    required this.pockets,
    this.selectedPocket,
    this.amount = 0,
    this.description = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  bool get isValid => selectedPocket != null && amount > 0;

  AddRepaymentState copyWith({
    List<Pocket>? pockets,
    Object? selectedPocket = _absent,
    double? amount,
    String? description,
    DateTime? date,
  }) {
    return AddRepaymentState(
      pockets: pockets ?? this.pockets,
      selectedPocket:
          selectedPocket == _absent
              ? this.selectedPocket
              : selectedPocket as Pocket?,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}

const Object _absent = Object();

final addRepaymentViewModelProvider =
    AsyncNotifierProvider<AddRepaymentViewModel, AddRepaymentState>(
      AddRepaymentViewModel.new,
    );

class AddRepaymentViewModel extends AsyncNotifier<AddRepaymentState> {
  late PocketRepository _pocketRepository;
  late TransactionRepository _transactionRepository;
  late LoanRepository _loanRepository;

  @override
  FutureOr<AddRepaymentState> build() async {
    _pocketRepository = ref.watch(pocketRepositoryProvider);
    _transactionRepository = ref.watch(transactionRepositoryProvider);
    _loanRepository = ref.watch(loanRepositoryProvider);

    final pockets = await _pocketRepository.getAllPockets();
    return AddRepaymentState(
      pockets: pockets,
      selectedPocket: pockets.isNotEmpty ? pockets.first : null,
    );
  }

  void setSelectedPocket(Pocket pocket) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedPocket: pocket));
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

  void setDate(DateTime date) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(date: date));
  }

  Future<void> submit(Loan loan) async {
    final current = state.valueOrNull;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      final transactionType =
          loan.type == LoanType.given
              ? TransactionType.loanCollection
              : TransactionType.loanRepayment;

      final transaction = Transaction(
        type: transactionType,
        senderPocketId: current.selectedPocket!.id,
        loanId: loan.id,
        description: current.description.trim(),
        amount: current.amount,
        date: current.date,
      );

      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
        await _transactionRepository.insertTransaction(
          transaction.toInsertCompanion(),
        );

        // Update pocket balance
        final pocket = current.selectedPocket!;
        final amount = current.amount;
        if (transactionType.isPositive) {
          // loanCollection — money coming in, credit pocket
          await _pocketRepository.updatePocket(
            pocket.copyWith(balance: pocket.balance + amount),
          );
        } else {
          // loanRepayment — money going out, debit pocket
          await _pocketRepository.updatePocket(
            pocket.copyWith(balance: pocket.balance - amount),
          );
        }

        // Update loan's repaid amount
        final newRepaidAmount = loan.repaidAmount + amount;
        await _loanRepository.updateRepaidAmount(loan.id!, newRepaidAmount);
      });

      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(transactionViewModelProvider);
      ref.invalidate(loanViewModelProvider);
      ref.invalidate(addRepaymentViewModelProvider);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
