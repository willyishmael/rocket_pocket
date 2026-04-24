import 'dart:ui';

import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart' as loan_model;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart' as transaction_model;
import 'package:rocket_pocket/data/model/transaction_type.dart';

DateTime fixedDate([int day = 15]) => DateTime(2026, 4, day, 10, 0, 0);

budget_model.Budget buildBudgetModel({
  int? id = 1,
  String name = 'Groceries',
  double amount = 1000,
  BudgetPeriod period = BudgetPeriod.monthly,
  DateTime? startDate,
  DateTime? createdAt,
}) {
  return budget_model.Budget(
    id: id,
    name: name,
    amount: amount,
    period: period,
    startDate: startDate ?? fixedDate(1),
    createdAt: createdAt ?? fixedDate(1),
  );
}

db.Budget buildBudgetRow({
  int id = 1,
  String name = 'Groceries',
  double amount = 1000,
  BudgetPeriod period = BudgetPeriod.monthly,
  DateTime? startDate,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return db.Budget(
    id: id,
    name: name,
    amount: amount,
    period: period,
    startDate: startDate ?? fixedDate(1),
    createdAt: createdAt ?? fixedDate(1),
    updatedAt: updatedAt ?? fixedDate(2),
  );
}

transaction_model.Transaction buildTransactionModel({
  int? id,
  int? senderPocketId,
  int? receiverPocketId,
  TransactionType type = TransactionType.expense,
  int? categoryId,
  int? loanId,
  int? originalTransactionId,
  int? budgetId,
  String description = 'Item',
  double amount = 10,
  DateTime? date,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return transaction_model.Transaction(
    id: id,
    senderPocketId: senderPocketId,
    receiverPocketId: receiverPocketId,
    type: type,
    categoryId: categoryId,
    loanId: loanId,
    originalTransactionId: originalTransactionId,
    budgetId: budgetId,
    description: description,
    amount: amount,
    date: date ?? fixedDate(3),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

db.Transaction buildTransactionRow({
  int id = 1,
  int? senderPocketId,
  int? receiverPocketId,
  TransactionType type = TransactionType.expense,
  int? categoryId,
  int? loanId,
  int? originalTransactionId,
  int? budgetId,
  String description = 'Item',
  double amount = 10,
  DateTime? date,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return db.Transaction(
    id: id,
    senderPocketId: senderPocketId,
    receiverPocketId: receiverPocketId,
    type: type,
    categoryId: categoryId,
    loanId: loanId,
    originalTransactionId: originalTransactionId,
    budgetId: budgetId,
    description: description,
    amount: amount,
    date: date,
    createdAt: createdAt ?? fixedDate(1),
    updatedAt: updatedAt ?? fixedDate(2),
  );
}

db.TransactionCategory buildCategoryRow({
  int id = 1,
  String name = 'Food',
  TransactionType type = TransactionType.expense,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return db.TransactionCategory(
    id: id,
    name: name,
    type: type,
    createdAt: createdAt ?? fixedDate(1),
    updatedAt: updatedAt ?? fixedDate(2),
  );
}

ColorGradient buildGradientModel({
  int? id = 1,
  String name = 'Ocean',
  List<Color>? colors,
  DateTime? createdAt,
}) {
  return ColorGradient(
    id: id,
    name: name,
    colors: colors ?? const [Color(0xFF0000FF), Color(0xFF00FFFF)],
    createdAt: createdAt ?? fixedDate(1),
  );
}

Pocket buildPocketModel({
  int? id = 1,
  String name = 'Main Pocket',
  String purpose = 'General',
  String currency = 'USD',
  double balance = 100,
  String emoticon = ':moneybag:',
  ColorGradient? colorGradient,
}) {
  return Pocket(
    id: id,
    name: name,
    purpose: purpose,
    currency: currency,
    balance: balance,
    emoticon: emoticon,
    colorGradient: colorGradient ?? buildGradientModel(),
    createdAt: fixedDate(1),
    updatedAt: fixedDate(2),
  );
}

loan_model.Loan buildLoanModel({
  int? id = 1,
  LoanType type = LoanType.given,
  String counterpartyName = 'Alex',
  double amount = 500,
  String description = 'Bridge loan',
  DateTime? startDate,
  DateTime? dueDate,
  LoanStatus status = LoanStatus.ongoing,
  double repaidAmount = 0,
  DateTime? createdAt,
}) {
  return loan_model.Loan(
    id: id,
    type: type,
    counterpartyName: counterpartyName,
    amount: amount,
    description: description,
    startDate: startDate ?? fixedDate(1),
    dueDate: dueDate ?? fixedDate(30),
    status: status,
    repaidAmount: repaidAmount,
    createdAt: createdAt ?? fixedDate(1),
  );
}

db.Loan buildLoanRow({
  int id = 1,
  LoanType type = LoanType.given,
  String counterpartyName = 'Alex',
  double amount = 500,
  String description = 'Bridge loan',
  DateTime? startDate,
  DateTime? dueDate,
  LoanStatus status = LoanStatus.ongoing,
  double repaidAmount = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return db.Loan(
    id: id,
    type: type,
    counterpartyName: counterpartyName,
    amount: amount,
    description: description,
    startDate: startDate ?? fixedDate(1),
    dueDate: dueDate ?? fixedDate(30),
    status: status,
    repaidAmount: repaidAmount,
    createdAt: createdAt ?? fixedDate(1),
    updatedAt: updatedAt ?? fixedDate(2),
  );
}
