// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/budget.dart' as budget_model;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

class TransactionTypeDateSection extends StatelessWidget {
  const TransactionTypeDateSection({
    required this.selectedType,
    required this.date,
    required this.onTypeChanged,
    required this.onDateChanged,
    this.segments,
    super.key,
  });

  final TransactionType selectedType;
  final DateTime date;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;

  /// Override the displayed type segments.
  /// Defaults to income / expense / transfer.
  final List<ButtonSegment<TransactionType>>? segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TransactionType>(
            showSelectedIcon: false,
            segments:
                segments ??
                const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: TransactionType.transfer,
                    label: Text('Transfer'),
                  ),
                ],
            selected: {selectedType},
            onSelectionChanged: (value) => onTypeChanged(value.first),
          ),
        ),
        const SizedBox(height: 24),
        TransactionDateTimeSection(dateTime: date, onPicked: onDateChanged),
      ],
    );
  }
}

class TransactionDateTimeSection extends StatelessWidget {
  const TransactionDateTimeSection({
    required this.dateTime,
    required this.onPicked,
    super.key,
  });

  final DateTime dateTime;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateTime,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;

              onPicked(
                DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  dateTime.hour,
                  dateTime.minute,
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                icon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(dateTime),
              );
              if (picked == null) return;

              onPicked(
                DateTime(
                  dateTime.year,
                  dateTime.month,
                  dateTime.day,
                  picked.hour,
                  picked.minute,
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                icon: Icon(Icons.access_time),
              ),
              child: Text(
                '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionPocketDropdown extends StatelessWidget {
  const TransactionPocketDropdown({
    required this.label,
    required this.pockets,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.includeNoPocketOption = false,
    this.noPocketLabel = 'No pocket',
    super.key,
  });

  final String label;
  final List<Pocket> pockets;
  final Pocket? value;
  final ValueChanged<Pocket?> onChanged;
  final String? errorText;
  final bool includeNoPocketOption;
  final String noPocketLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Pocket?>(
      value: value,
      isExpanded: true,
      isDense: false,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        icon: const Icon(Icons.account_balance_wallet),
        errorText: errorText,
      ),
      items: [
        if (includeNoPocketOption)
          DropdownMenuItem<Pocket?>(
            value: null,
            child: Text(noPocketLabel),
          ),
        ...pockets.map(
          (p) => DropdownMenuItem<Pocket?>(
            value: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p.icon}  ${p.name}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${p.currency}  ${CurrencyUtils.format(p.balance, p.currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class TransactionCategoryDropdown extends StatelessWidget {
  const TransactionCategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<db.TransactionCategory> categories;
  final db.TransactionCategory? value;
  final ValueChanged<db.TransactionCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<db.TransactionCategory>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        icon: Icon(Icons.category),
      ),
      items:
          categories
              .map(
                (c) => DropdownMenuItem<db.TransactionCategory>(
                  value: c,
                  child: Text(c.name),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

class TransactionBudgetDropdown extends StatelessWidget {
  const TransactionBudgetDropdown({
    required this.budgets,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<budget_model.Budget> budgets;
  final budget_model.Budget? value;
  final ValueChanged<budget_model.Budget?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<budget_model.Budget?>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Budget (optional)',
        border: OutlineInputBorder(),
        icon: Icon(Icons.savings),
      ),
      items: [
        const DropdownMenuItem<budget_model.Budget?>(
          value: null,
          child: Text('None'),
        ),
        ...budgets.map(
          (budget) => DropdownMenuItem<budget_model.Budget?>(
            value: budget,
            child: Text(budget.name),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class TransactionTextField extends StatefulWidget {
  const TransactionTextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.keyboardType,
    super.key,
  }) : assert(controller == null || initialValue == null);

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  State<TransactionTextField> createState() => _TransactionTextFieldState();
}

class _TransactionTextFieldState extends State<TransactionTextField> {
  late TextEditingController _internalController;
  bool _usingInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
      _usingInternalController = true;
    } else {
      _internalController = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_usingInternalController) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _internalController,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        icon: Icon(widget.icon),
      ),
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
    );
  }
}
