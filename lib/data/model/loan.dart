import 'package:rocket_pocket/data/model/loan_status.dart';
import 'package:rocket_pocket/data/model/loan_type.dart';

class Loan {
  final int id;
  final LoanType type;
  final String counterpartyName;
  final double amount;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;
  final double repaidAmount;
  final DateTime createdAt;

  Loan({
    required this.id,
    required this.type,
    required this.counterpartyName,
    required this.amount,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.repaidAmount,
    required this.createdAt,
  });
}