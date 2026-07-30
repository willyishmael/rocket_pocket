import 'package:drift/drift.dart' show Value;
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/enums.dart';

class Loan {
  int? id;
  final LoanType type;
  final LoanFinancingKind financingKind;
  final String counterpartyName;
  final String currency;
  final double amount;
  final double principalAmount;
  final double downPaymentAmount;
  final double financedAmount;
  final LoanInterestModel interestModel;
  final double monthlyInterestRatePercent;
  final InstallmentMode installmentMode;
  final int installmentCount;
  final int? paymentDayOfMonth;
  final DateTime? firstInstallmentDate;
  final bool isReminderEnabled;
  final int reminderDaysBefore;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;
  final double repaidAmount;
  final DateTime createdAt;

  Loan({
    this.id,
    required this.type,
    this.financingKind = LoanFinancingKind.cashLoan,
    required this.counterpartyName,
    required this.currency,
    required this.amount,
    double? principalAmount,
    this.downPaymentAmount = 0,
    double? financedAmount,
    this.interestModel = LoanInterestModel.flat,
    this.monthlyInterestRatePercent = 0,
    this.installmentMode = InstallmentMode.fixed,
    this.installmentCount = 1,
    this.paymentDayOfMonth,
    this.firstInstallmentDate,
    this.isReminderEnabled = true,
    this.reminderDaysBefore = 3,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.repaidAmount,
    required this.createdAt,
  }) : principalAmount = principalAmount ?? amount,
       financedAmount = financedAmount ?? amount;

  Loan copyWith({
    int? id,
    LoanType? type,
    LoanFinancingKind? financingKind,
    String? counterpartyName,
    String? currency,
    double? amount,
    double? principalAmount,
    double? downPaymentAmount,
    double? financedAmount,
    LoanInterestModel? interestModel,
    double? monthlyInterestRatePercent,
    InstallmentMode? installmentMode,
    int? installmentCount,
    Object? paymentDayOfMonth = _sentinel,
    Object? firstInstallmentDate = _sentinel,
    bool? isReminderEnabled,
    int? reminderDaysBefore,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
    double? repaidAmount,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      type: type ?? this.type,
      financingKind: financingKind ?? this.financingKind,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      principalAmount: principalAmount ?? this.principalAmount,
      downPaymentAmount: downPaymentAmount ?? this.downPaymentAmount,
      financedAmount: financedAmount ?? this.financedAmount,
      interestModel: interestModel ?? this.interestModel,
      monthlyInterestRatePercent:
          monthlyInterestRatePercent ?? this.monthlyInterestRatePercent,
      installmentMode: installmentMode ?? this.installmentMode,
      installmentCount: installmentCount ?? this.installmentCount,
      paymentDayOfMonth:
          paymentDayOfMonth == _sentinel
              ? this.paymentDayOfMonth
              : paymentDayOfMonth as int?,
      firstInstallmentDate:
          firstInstallmentDate == _sentinel
              ? this.firstInstallmentDate
              : firstInstallmentDate as DateTime?,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Loan fromDb(db.Loan row) {
    return Loan(
      id: row.id,
      type: row.type,
      financingKind: LoanFinancingKind.values.byName(row.financingKind),
      counterpartyName: row.counterpartyName,
      currency: row.currency,
      amount: row.amount,
      principalAmount: row.principalAmount,
      downPaymentAmount: row.downPaymentAmount,
      financedAmount: row.financedAmount,
      interestModel: LoanInterestModel.values.byName(row.interestModel),
      monthlyInterestRatePercent: row.monthlyInterestRatePercent,
      installmentMode: InstallmentMode.values.byName(row.installmentMode),
      installmentCount: row.installmentCount,
      paymentDayOfMonth: row.paymentDayOfMonth,
      firstInstallmentDate: row.firstInstallmentDate,
      isReminderEnabled: row.isReminderEnabled,
      reminderDaysBefore: row.reminderDaysBefore,
      description: row.description,
      startDate: row.startDate,
      dueDate: row.dueDate,
      status: row.status,
      repaidAmount: row.repaidAmount,
      createdAt: row.createdAt,
    );
  }

  /// Convert this Loan to a Companion for inserting a new row.
  /// Uses Value.absent() for id so the database auto-increments it.
  db.LoansCompanion toInsertCompanion() {
    return db.LoansCompanion.insert(
      type: type,
      financingKind: Value(financingKind.name),
      counterpartyName: counterpartyName,
      currency: Value(currency),
      amount: amount,
      principalAmount: Value(principalAmount),
      downPaymentAmount: Value(downPaymentAmount),
      financedAmount: Value(financedAmount),
      interestModel: Value(interestModel.name),
      monthlyInterestRatePercent: Value(monthlyInterestRatePercent),
      installmentMode: Value(installmentMode.name),
      installmentCount: Value(installmentCount),
      paymentDayOfMonth: Value(paymentDayOfMonth),
      firstInstallmentDate: Value(firstInstallmentDate),
      isReminderEnabled: Value(isReminderEnabled),
      reminderDaysBefore: Value(reminderDaysBefore),
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      status: status,
      repaidAmount: repaidAmount,
      createdAt: Value(createdAt),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert this Loan to a Companion for updating an existing row.
  /// Requires a non-null id. Only writes fields explicitly set as Value(...)
  /// (createdAt is omitted so the original value is preserved).
  db.LoansCompanion toUpdateCompanion() {
    assert(id != null, 'toUpdateCompanion() requires a non-null id.');
    return db.LoansCompanion(
      id: Value(id!),
      type: Value(type),
      financingKind: Value(financingKind.name),
      counterpartyName: Value(counterpartyName),
      currency: Value(currency),
      amount: Value(amount),
      principalAmount: Value(principalAmount),
      downPaymentAmount: Value(downPaymentAmount),
      financedAmount: Value(financedAmount),
      interestModel: Value(interestModel.name),
      monthlyInterestRatePercent: Value(monthlyInterestRatePercent),
      installmentMode: Value(installmentMode.name),
      installmentCount: Value(installmentCount),
      paymentDayOfMonth: Value(paymentDayOfMonth),
      firstInstallmentDate: Value(firstInstallmentDate),
      isReminderEnabled: Value(isReminderEnabled),
      reminderDaysBefore: Value(reminderDaysBefore),
      description: Value(description),
      startDate: Value(startDate),
      dueDate: Value(dueDate),
      status: Value(status),
      repaidAmount: Value(repaidAmount),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Convert this Loan to a database row for updates.
  /// Requires a non-null id (the row must already exist).
  db.Loan toDb() {
    assert(
      id != null,
      'toDb() requires a non-null id. Use toInsertCompanion() for new loans.',
    );
    return db.Loan(
      id: id!,
      type: type,
      financingKind: financingKind.name,
      counterpartyName: counterpartyName,
      currency: currency,
      amount: amount,
      principalAmount: principalAmount,
      downPaymentAmount: downPaymentAmount,
      financedAmount: financedAmount,
      interestModel: interestModel.name,
      monthlyInterestRatePercent: monthlyInterestRatePercent,
      installmentMode: installmentMode.name,
      installmentCount: installmentCount,
      paymentDayOfMonth: paymentDayOfMonth,
      firstInstallmentDate: firstInstallmentDate,
      isReminderEnabled: isReminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      status: status,
      repaidAmount: repaidAmount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

const Object _sentinel = Object();
