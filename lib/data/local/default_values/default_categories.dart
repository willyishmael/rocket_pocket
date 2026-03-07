import 'package:rocket_pocket/data/local/database.dart';

List<TransactionCategoriesCompanion> get defaultCategories {
  final now = DateTime.now();
  return [
    // Expense categories
    TransactionCategoriesCompanion.insert(name: 'Food & Drinks', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Groceries', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Transportation', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Housing & Rent', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Utilities', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Health & Medical', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Education', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Entertainment', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Shopping', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Travel', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Personal Care', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Subscriptions', updatedAt: now),
    // Income categories
    TransactionCategoriesCompanion.insert(name: 'Salary', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Freelance', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Business', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Investment', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Gift', updatedAt: now),
    // General
    TransactionCategoriesCompanion.insert(name: 'Transfer', updatedAt: now),
    TransactionCategoriesCompanion.insert(name: 'Other', updatedAt: now),
  ];
}
