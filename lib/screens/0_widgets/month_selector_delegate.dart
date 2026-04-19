import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MonthSelectorDelegate extends SliverPersistentHeaderDelegate {
  final List<DateTime> months;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  const MonthSelectorDelegate({
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: months.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month == selectedMonth;
          final label = '${_monthNames[month.month - 1]} ${month.year}';
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onMonthSelected(month),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(MonthSelectorDelegate old) =>
      !listEquals(months, old.months) || selectedMonth != old.selectedMonth;
}
