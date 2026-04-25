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
    super.key,
  });

  final TransactionType selectedType;
  final DateTime date;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;

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
            segments: const [
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
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;

                  onDateChanged(
                    DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      date.hour,
                      date.minute,
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
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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
                    initialTime: TimeOfDay.fromDateTime(date),
                  );
                  if (picked == null) return;

                  onDateChanged(
                    DateTime(
                      date.year,
                      date.month,
                      date.day,
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
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
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
    super.key,
  });

  final String label;
  final List<Pocket> pockets;
  final Pocket? value;
  final ValueChanged<Pocket?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Pocket>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        icon: const Icon(Icons.account_balance_wallet),
      ),
      items:
          pockets
              .map(
                (p) => DropdownMenuItem<Pocket>(
                  value: p,
                  child: Text(
                    '${p.emoticon}  ${p.name} (${CurrencyUtils.format(p.balance, p.currency)})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
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
