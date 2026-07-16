import 'package:drift/drift.dart';
import '../../model/type_converter/loan_type_converter.dart';
import '../../model/type_converter/loan_status_converter.dart';

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().map(const LoanTypeConverter())();
  TextColumn get financingKind =>
      text().withDefault(const Constant('cashLoan'))();
  TextColumn get counterpartyName => text()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  RealColumn get amount => real()();
  RealColumn get principalAmount => real().withDefault(const Constant(0))();
  RealColumn get downPaymentAmount => real().withDefault(const Constant(0))();
  RealColumn get financedAmount => real().withDefault(const Constant(0))();
  TextColumn get interestModel => text().withDefault(const Constant('flat'))();
  RealColumn get annualInterestRatePercent =>
      real().withDefault(const Constant(0))();
  TextColumn get installmentMode =>
      text().withDefault(const Constant('fixed'))();
  IntColumn get installmentCount => integer().withDefault(const Constant(1))();
  IntColumn get paymentDayOfMonth => integer().nullable()();
  DateTimeColumn get firstInstallmentDate => dateTime().nullable()();
  BoolColumn get isReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(3))();
  TextColumn get description => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().map(const LoanStatusConverter())();
  RealColumn get repaidAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
}
