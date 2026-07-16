import 'dart:async';
import 'dart:math' as math;
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
import 'package:rocket_pocket/utils/loan_installment_schedule.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';
import 'package:rocket_pocket/viewmodels/viewmodel_utils.dart';

class AddLoanState {
  final LoanFinancingKind financingKind;
  final LoanType selectedType;
  final String counterpartyName;
  final String currency;
  final double amount;
  final double downPaymentAmount;
  final double monthlyInterestRatePercent;
  final double additionalFeeAmount;
  final int installmentCount;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final List<Pocket> pockets;
  final Pocket? selectedPocket;

  AddLoanState({
    this.financingKind = LoanFinancingKind.cashLoan,
    this.selectedType = LoanType.given,
    this.counterpartyName = '',
    this.currency = 'IDR',
    this.amount = 0,
    this.downPaymentAmount = 0,
    this.monthlyInterestRatePercent = 0,
    this.additionalFeeAmount = 0,
    this.installmentCount = 1,
    this.description = '',
    DateTime? startDate,
    DateTime? dueDate,
    this.pockets = const [],
    this.selectedPocket,
  }) : startDate = startDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  bool get isValid =>
      counterpartyName.trim().isNotEmpty &&
      financedPrincipal > 0 &&
      downPaymentAmount >= 0 &&
      monthlyInterestRatePercent >= 0 &&
      additionalFeeAmount >= 0 &&
      installmentCount > 0;

  bool get usesInstallments => installmentCount > 1;

  bool get isPurchaseInstallment =>
      financingKind == LoanFinancingKind.purchaseInstallment;

  double get financedPrincipal =>
      isPurchaseInstallment ? math.max(amount - downPaymentAmount, 0) : amount;

  LoanInstallmentPlan? get previewPlan {
    if (financedPrincipal <= 0 || installmentCount <= 0) return null;

    try {
      return LoanInstallmentSchedule.buildFlatMonthlyPlan(
        LoanInstallmentPlanInput(
          principalAmount: financedPrincipal,
          monthlyInterestRatePercent: monthlyInterestRatePercent,
          additionalFeeAmount: additionalFeeAmount,
          installmentCount: installmentCount,
          firstDueDate: dueDate,
          installmentMode: InstallmentMode.fixed,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  AddLoanState copyWith({
    LoanFinancingKind? financingKind,
    LoanType? selectedType,
    String? counterpartyName,
    String? currency,
    double? amount,
    double? downPaymentAmount,
    double? monthlyInterestRatePercent,
    double? additionalFeeAmount,
    int? installmentCount,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    List<Pocket>? pockets,
    Object? selectedPocket = absent,
  }) {
    return AddLoanState(
      financingKind: financingKind ?? this.financingKind,
      selectedType: selectedType ?? this.selectedType,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      downPaymentAmount: downPaymentAmount ?? this.downPaymentAmount,
      monthlyInterestRatePercent:
          monthlyInterestRatePercent ?? this.monthlyInterestRatePercent,
      additionalFeeAmount: additionalFeeAmount ?? this.additionalFeeAmount,
      installmentCount: installmentCount ?? this.installmentCount,
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

  void setFinancingKind(LoanFinancingKind financingKind) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        financingKind: financingKind,
        selectedType:
            financingKind == LoanFinancingKind.purchaseInstallment
                ? LoanType.taken
                : current.selectedType,
      ),
    );
  }

  void setType(LoanType type) {
    final current = state.value;
    if (current == null) return;
    if (current.financingKind == LoanFinancingKind.purchaseInstallment) {
      state = AsyncData(current.copyWith(selectedType: LoanType.taken));
      return;
    }
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
    final normalizedAmount = amount < 0 ? 0.0 : amount;
    final normalizedDownPayment =
        current.downPaymentAmount > normalizedAmount
            ? normalizedAmount
            : current.downPaymentAmount;
    state = AsyncData(
      current.copyWith(
        amount: normalizedAmount,
        downPaymentAmount: normalizedDownPayment,
      ),
    );
  }

  void setDownPaymentAmount(double downPaymentAmount) {
    final current = state.value;
    if (current == null) return;
    final normalized = downPaymentAmount < 0 ? 0.0 : downPaymentAmount;
    state = AsyncData(
      current.copyWith(
        downPaymentAmount:
            normalized > current.amount ? current.amount : normalized,
      ),
    );
  }

  void setCurrency(String currency) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(currency: currency));
  }

  void setMonthlyInterestRatePercent(double monthlyInterestRatePercent) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        monthlyInterestRatePercent:
            monthlyInterestRatePercent < 0 ? 0 : monthlyInterestRatePercent,
      ),
    );
  }

  void setAdditionalFeeAmount(double additionalFeeAmount) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        additionalFeeAmount: additionalFeeAmount < 0 ? 0 : additionalFeeAmount,
      ),
    );
  }

  void setInstallmentCount(int installmentCount) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        installmentCount: installmentCount <= 0 ? 1 : installmentCount,
      ),
    );
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

  LoanInstallmentPlan _buildInstallmentPlan(AddLoanState current) {
    return current.previewPlan!;
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null || !current.isValid) return;

    state = const AsyncLoading();
    try {
      if (current.selectedPocket != null &&
          current.selectedPocket!.id == null) {
        state = AsyncData(current);
        return;
      }

      final selectedPocketId = current.selectedPocket?.id;
      final latestSelectedPocket =
          selectedPocketId == null
              ? null
              : await _pocketRepository.getPocketById(selectedPocketId);

      if (selectedPocketId != null && latestSelectedPocket == null) {
        state = AsyncData(current);
        return;
      }

      if (latestSelectedPocket != null &&
          latestSelectedPocket.currency != current.currency) {
        state = AsyncData(current);
        return;
      }

      if (current.isPurchaseInstallment &&
          latestSelectedPocket != null &&
          current.downPaymentAmount > latestSelectedPocket.balance) {
        state = AsyncData(current);
        return;
      }

      // Loan given moves money out; require enough balance when a pocket is selected.
      if (current.selectedType == LoanType.given &&
          latestSelectedPocket != null &&
          current.financedPrincipal > latestSelectedPocket.balance) {
        state = AsyncData(current);
        return;
      }

      final plan = _buildInstallmentPlan(current);
      final loan = Loan(
        type: current.selectedType,
        financingKind: current.financingKind,
        counterpartyName: current.counterpartyName.trim(),
        currency: current.currency,
        amount: plan.totalPayable,
        principalAmount: current.financedPrincipal,
        downPaymentAmount: current.downPaymentAmount,
        financedAmount: current.financedPrincipal,
        monthlyInterestRatePercent: current.monthlyInterestRatePercent,
        installmentCount: current.installmentCount,
        installmentMode: InstallmentMode.fixed,
        paymentDayOfMonth: current.dueDate.day,
        firstInstallmentDate: current.dueDate,
        description: current.description.trim(),
        startDate: current.startDate,
        dueDate: plan.lines.last.dueDate,
        status: LoanStatus.ongoing,
        repaidAmount: 0,
        createdAt: DateTime.now(),
      );

      await _loanRepository.createLoanWithSchedule(
        loan: loan.toInsertCompanion(),
        scheduleLines: plan.lines,
      );

      // Record transaction if pocket is selected
      if (latestSelectedPocket != null && latestSelectedPocket.id != null) {
        final pocket = latestSelectedPocket;
        final transactionRepo = ref.read(transactionRepositoryProvider);
        var updatedBalance = pocket.balance;

        if (current.financingKind == LoanFinancingKind.cashLoan) {
          final categoryName =
              current.selectedType == LoanType.given
                  ? 'Loan Given'
                  : 'Loan Taken';
          final transactionType =
              current.selectedType == LoanType.given
                  ? TransactionType.loanGiven
                  : TransactionType.loanTaken;
          final categoryRepo = ref.read(transactionCategoryRepositoryProvider);

          final category = await categoryRepo.getOrCreateSystemCategory(
            name: categoryName,
            type: transactionType,
          );

          final amount =
              current.selectedType == LoanType.given
                  ? -current.financedPrincipal
                  : current.financedPrincipal;

          await transactionRepo.insertTransaction(
            Transaction(
              senderPocketId: pocket.id,
              type: transactionType,
              categoryId: category.id,
              description: 'Loan: ${current.counterpartyName}',
              amount: amount,
              date: current.startDate,
            ).toInsertCompanion(),
          );

          updatedBalance += amount;
        } else if (current.downPaymentAmount > 0) {
          await transactionRepo.insertTransaction(
            Transaction(
              senderPocketId: pocket.id,
              type: TransactionType.expense,
              description: 'Down payment: ${current.counterpartyName}',
              amount: current.downPaymentAmount,
              date: current.startDate,
            ).toInsertCompanion(),
          );

          updatedBalance -= current.downPaymentAmount;
        }

        await _pocketRepository.updatePocket(
          pocket.copyWith(balance: updatedBalance, updatedAt: DateTime.now()),
        );

        // Refresh transaction list
        await ref
            .read(transactionViewModelProvider.notifier)
            .refreshTransactions();
      }

      ref.invalidate(loanViewModelProvider);
      ref.invalidate(pocketViewModelProvider);
      // Reload pockets after transaction is recorded
      final pockets = await _pocketRepository.getAllPockets();
      state = AsyncData(AddLoanState(pockets: pockets));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
