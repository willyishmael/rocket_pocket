import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/utils/loan_installment_schedule.dart';

void main() {
  group('LoanInstallmentSchedule', () {
    test('builds fixed monthly flat-interest plan', () {
      final plan = LoanInstallmentSchedule.buildFlatMonthlyPlan(
        LoanInstallmentPlanInput(
          principalAmount: 1200,
          annualInterestRatePercent: 12,
          installmentCount: 12,
          firstDueDate: DateTime(2026, 1, 31),
          installmentMode: InstallmentMode.fixed,
        ),
      );

      expect(plan.lines.length, 12);
      expect(plan.totalPrincipal, 1200);
      expect(plan.totalInterest, 144);
      expect(plan.totalPayable, 1344);

      // First line should keep Jan 31.
      expect(plan.lines.first.dueDate, DateTime(2026, 1, 31));
      // February should clamp from 31 -> 28.
      expect(plan.lines[1].dueDate, DateTime(2026, 2, 28));

      final principalSum = plan.lines.fold<double>(
        0,
        (sum, line) => sum + line.principalDue,
      );
      final totalSum = plan.lines.fold<double>(
        0,
        (sum, line) => sum + line.totalDue,
      );

      expect(principalSum, closeTo(1200, 0.01));
      expect(totalSum, closeTo(1344, 0.01));
    });

    test('builds variable monthly plan when totals are valid', () {
      final totals = [280.0, 260.0, 250.0, 250.0];
      final plan = LoanInstallmentSchedule.buildFlatMonthlyPlan(
        LoanInstallmentPlanInput(
          principalAmount: 1000,
          annualInterestRatePercent: 12,
          installmentCount: 4,
          firstDueDate: DateTime(2026, 3, 15),
          installmentMode: InstallmentMode.variable,
          variableInstallmentTotals: totals,
        ),
      );

      expect(plan.lines.length, 4);
      expect(plan.totalInterest, 40);
      expect(plan.totalPayable, 1040);

      final totalsSum = plan.lines.fold<double>(
        0,
        (sum, line) => sum + line.totalDue,
      );
      expect(totalsSum, closeTo(1040, 0.01));
    });

    test('throws when variable totals do not sum to payable total', () {
      expect(
        () => LoanInstallmentSchedule.buildFlatMonthlyPlan(
          LoanInstallmentPlanInput(
            principalAmount: 1000,
            annualInterestRatePercent: 12,
            installmentCount: 4,
            firstDueDate: DateTime(2026, 3, 15),
            installmentMode: InstallmentMode.variable,
            variableInstallmentTotals: [200, 200, 200, 200],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
