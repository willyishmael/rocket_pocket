import 'package:rocket_pocket/data/model/enums.dart';

class LoanInstallmentLine {
  final int sequence;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double feeDue;
  final double totalDue;

  const LoanInstallmentLine({
    required this.sequence,
    required this.dueDate,
    required this.principalDue,
    required this.interestDue,
    required this.feeDue,
    required this.totalDue,
  });
}

class LoanInstallmentPlanInput {
  final double principalAmount;
  final double monthlyInterestRatePercent;
  final double additionalFeeAmount;
  final int installmentCount;
  final DateTime firstDueDate;
  final InstallmentMode installmentMode;
  final List<double>? variableInstallmentTotals;

  const LoanInstallmentPlanInput({
    required this.principalAmount,
    required this.monthlyInterestRatePercent,
    this.additionalFeeAmount = 0,
    required this.installmentCount,
    required this.firstDueDate,
    required this.installmentMode,
    this.variableInstallmentTotals,
  });
}

class LoanInstallmentPlan {
  final List<LoanInstallmentLine> lines;
  final double totalPrincipal;
  final double totalInterest;
  final double totalFee;
  final double totalPayable;

  const LoanInstallmentPlan({
    required this.lines,
    required this.totalPrincipal,
    required this.totalInterest,
    required this.totalFee,
    required this.totalPayable,
  });
}

class LoanInstallmentSchedule {
  static LoanInstallmentPlan buildFlatMonthlyPlan(
    LoanInstallmentPlanInput input,
  ) {
    _validate(input);

    final principal = _round2(input.principalAmount);
    final monthlyInterest = _round2(
      principal * input.monthlyInterestRatePercent / 100,
    );
    final interestTotal = _round2(monthlyInterest * input.installmentCount);
    final feeTotal = _round2(input.additionalFeeAmount);
    final feePerInstallment = _distributeAcrossInstallments(
      total: feeTotal,
      count: input.installmentCount,
    );
    final totalPayable = _round2(principal + interestTotal + feeTotal);

    final lines =
        input.installmentMode == InstallmentMode.fixed
            ? _buildFixedLines(
              firstDueDate: input.firstDueDate,
              installmentCount: input.installmentCount,
              principal: principal,
              monthlyInterest: monthlyInterest,
              feePerInstallment: feePerInstallment,
            )
            : _buildVariableLines(
              firstDueDate: input.firstDueDate,
              installmentCount: input.installmentCount,
              principal: principal,
              monthlyInterest: monthlyInterest,
              feePerInstallment: feePerInstallment,
              expectedTotalPayable: totalPayable,
              totals: input.variableInstallmentTotals!,
            );

    return LoanInstallmentPlan(
      lines: lines,
      totalPrincipal: principal,
      totalInterest: interestTotal,
      totalFee: feeTotal,
      totalPayable: totalPayable,
    );
  }

  static List<LoanInstallmentLine> _buildFixedLines({
    required DateTime firstDueDate,
    required int installmentCount,
    required double principal,
    required double monthlyInterest,
    required List<double> feePerInstallment,
  }) {
    final principalBase = _round2(principal / installmentCount);
    final lines = <LoanInstallmentLine>[];

    double principalAccumulated = 0;
    for (var i = 0; i < installmentCount; i++) {
      final sequence = i + 1;
      final isLast = sequence == installmentCount;
      final principalDue =
          isLast ? _round2(principal - principalAccumulated) : principalBase;
      principalAccumulated = _round2(principalAccumulated + principalDue);

      final feeDue = feePerInstallment[i];
      final totalDue = _round2(principalDue + monthlyInterest + feeDue);
      lines.add(
        LoanInstallmentLine(
          sequence: sequence,
          dueDate: _dueDateAt(firstDueDate, i),
          principalDue: principalDue,
          interestDue: monthlyInterest,
          feeDue: feeDue,
          totalDue: totalDue,
        ),
      );
    }

    return lines;
  }

  static List<LoanInstallmentLine> _buildVariableLines({
    required DateTime firstDueDate,
    required int installmentCount,
    required double principal,
    required double monthlyInterest,
    required List<double> feePerInstallment,
    required double expectedTotalPayable,
    required List<double> totals,
  }) {
    if (totals.length != installmentCount) {
      throw ArgumentError(
        'Variable installment totals length must match installmentCount.',
      );
    }

    final normalizedTotals = totals.map(_round2).toList(growable: false);
    final sumTotals = normalizedTotals.fold<double>(
      0,
      (a, b) => _round2(a + b),
    );

    if ((sumTotals - expectedTotalPayable).abs() > 0.01) {
      throw ArgumentError(
        'Variable installment totals must sum to total payable.',
      );
    }

    final lines = <LoanInstallmentLine>[];
    double principalAccumulated = 0;

    for (var i = 0; i < installmentCount; i++) {
      final sequence = i + 1;
      final isLast = sequence == installmentCount;
      final totalDue = normalizedTotals[i];
      final feeDue = feePerInstallment[i];

      final principalDue =
          isLast
              ? _round2(principal - principalAccumulated)
              : _round2(totalDue - monthlyInterest - feeDue);

      if (principalDue < 0) {
        throw ArgumentError(
          'Installment #$sequence is lower than monthly interest and fee.',
        );
      }

      principalAccumulated = _round2(principalAccumulated + principalDue);

      lines.add(
        LoanInstallmentLine(
          sequence: sequence,
          dueDate: _dueDateAt(firstDueDate, i),
          principalDue: principalDue,
          interestDue: monthlyInterest,
          feeDue: feeDue,
          totalDue: _round2(principalDue + monthlyInterest + feeDue),
        ),
      );
    }

    if ((principalAccumulated - principal).abs() > 0.01) {
      throw ArgumentError(
        'Variable installment principal totals do not match principal amount.',
      );
    }

    return lines;
  }

  static DateTime _dueDateAt(DateTime firstDueDate, int offsetMonth) {
    final year = firstDueDate.year;
    final month = firstDueDate.month + offsetMonth;
    final day = firstDueDate.day;

    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = day > lastDayOfTargetMonth ? lastDayOfTargetMonth : day;

    return DateTime(
      year,
      month,
      clampedDay,
      firstDueDate.hour,
      firstDueDate.minute,
      firstDueDate.second,
      firstDueDate.millisecond,
      firstDueDate.microsecond,
    );
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;

  static List<double> _distributeAcrossInstallments({
    required double total,
    required int count,
  }) {
    if (count <= 0) return const [];
    final base = _round2(total / count);
    final values = List<double>.filled(count, base, growable: false);
    final baseTotal = _round2(base * count);
    values[count - 1] = _round2(values.last + _round2(total - baseTotal));
    return values;
  }

  static void _validate(LoanInstallmentPlanInput input) {
    if (input.principalAmount <= 0) {
      throw ArgumentError('principalAmount must be greater than 0.');
    }
    if (input.installmentCount <= 0) {
      throw ArgumentError('installmentCount must be greater than 0.');
    }
    if (input.monthlyInterestRatePercent < 0) {
      throw ArgumentError('monthlyInterestRatePercent cannot be negative.');
    }
    if (input.additionalFeeAmount < 0) {
      throw ArgumentError('additionalFeeAmount cannot be negative.');
    }
    if (input.installmentMode == InstallmentMode.variable &&
        input.variableInstallmentTotals == null) {
      throw ArgumentError(
        'variableInstallmentTotals is required when installmentMode is variable.',
      );
    }
  }
}
