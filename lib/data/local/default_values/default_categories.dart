import 'package:drift/drift.dart' show Value;
import 'package:rocket_pocket/data/local/database.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';

List<TransactionCategoriesCompanion> get defaultCategories {
  final now = DateTime.now();

  TransactionCategoriesCompanion cat(
    String name,
    TransactionType type, {
    bool isSystem = false,
  }) => TransactionCategoriesCompanion.insert(
    name: name,
    type: Value(type),
    isSystem: Value(isSystem),
    updatedAt: now,
  );

  return [
    // System expense categories (protected — cannot be renamed or deleted)
    cat('Tax', TransactionType.expense, isSystem: true),
    cat('Tip', TransactionType.expense, isSystem: true),
    cat('Admin Fee', TransactionType.expense, isSystem: true),
    // Expense & Refund categories
    cat('Food & Drinks', TransactionType.expense),
    cat('Groceries', TransactionType.expense),
    cat('Transportation', TransactionType.expense),
    cat('Housing & Rent', TransactionType.expense),
    cat('Utilities', TransactionType.expense),
    cat('Health & Medical', TransactionType.expense),
    cat('Education', TransactionType.expense),
    cat('Entertainment', TransactionType.expense),
    cat('Shopping', TransactionType.expense),
    cat('Travel', TransactionType.expense),
    cat('Personal Care', TransactionType.expense),
    cat('Subscriptions', TransactionType.expense),
    cat('Other', TransactionType.expense),
    // Income categories
    cat('Salary', TransactionType.income),
    cat('Freelance', TransactionType.income),
    cat('Business', TransactionType.income),
    cat('Investment', TransactionType.income),
    cat('Gift', TransactionType.income),
    cat('Other', TransactionType.income),
  ];
}
