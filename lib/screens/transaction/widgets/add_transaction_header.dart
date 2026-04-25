// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/add_transaction_view_model.dart';

class AddTransactionHeader extends ConsumerWidget {
  const AddTransactionHeader({required this.state, super.key});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addTransactionViewModelProvider.notifier);

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
            selected: {state.selectedType},
            onSelectionChanged: (value) => notifier.setType(value.first),
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
                    initialDate: state.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;

                  final current = state.date;
                  notifier.setDate(
                    DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      current.hour,
                      current.minute,
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
                    '${state.date.year}-'
                    '${state.date.month.toString().padLeft(2, '0')}-'
                    '${state.date.day.toString().padLeft(2, '0')}',
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
                    initialTime: TimeOfDay.fromDateTime(state.date),
                  );
                  if (picked == null) return;

                  final current = state.date;
                  notifier.setDate(
                    DateTime(
                      current.year,
                      current.month,
                      current.day,
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
                    '${state.date.hour.toString().padLeft(2, '0')}:'
                    '${state.date.minute.toString().padLeft(2, '0')}',
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
