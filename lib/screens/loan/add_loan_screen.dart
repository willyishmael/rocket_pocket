import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/viewmodels/add_loan_view_model.dart';

class AddLoanScreen extends ConsumerWidget {
  const AddLoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelAsync = ref.watch(addLoanViewModelProvider);

    return Scaffold(
      body: viewModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => _AddLoanForm(state: state),
      ),
    );
  }
}

class _AddLoanForm extends ConsumerWidget {
  final AddLoanState state;

  const _AddLoanForm({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addLoanViewModelProvider.notifier);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          expandedHeight: 120,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: const FlexibleSpaceBar(
            title: Text('Add Loan'),
            titlePadding: EdgeInsets.only(left: 56, bottom: 16),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Loan type ──────────────────────────────────────────
                Text('Type', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LoanType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: LoanType.given,
                        label: Text('Loan Given'),
                        icon: Icon(Icons.call_made),
                      ),
                      ButtonSegment(
                        value: LoanType.taken,
                        label: Text('Loan Taken'),
                        icon: Icon(Icons.call_received),
                      ),
                    ],
                    selected: {state.selectedType},
                    onSelectionChanged: (v) => notifier.setType(v.first),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Counterparty name ──────────────────────────────────
                TextFormField(
                  initialValue: state.counterpartyName,
                  decoration: const InputDecoration(
                    labelText: 'Counterparty Name',
                    hintText: 'Person or organization',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: notifier.setCounterpartyName,
                ),

                const SizedBox(height: 16),

                // ── Amount ─────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => notifier.setAmount(double.tryParse(v) ?? 0),
                ),

                const SizedBox(height: 16),

                // ── Description / notes ────────────────────────────────
                TextFormField(
                  initialValue: state.description,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: notifier.setDescription,
                ),

                const SizedBox(height: 24),

                // ── Dates ──────────────────────────────────────────────
                Text('Duration', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start Date',
                        icon: Icons.calendar_today_outlined,
                        date: state.startDate,
                        onPicked: notifier.setStartDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Due Date',
                        icon: Icons.event_outlined,
                        date: state.dueDate,
                        onPicked: notifier.setDueDate,
                        firstDate: state.startDate,
                        lastDate: DateTime(2100),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Submit ─────────────────────────────────────────────
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Save Loan'),
                  onPressed:
                      state.isValid
                          ? () async {
                            await ref
                                .read(addLoanViewModelProvider.notifier)
                                .submit();
                            if (context.mounted) context.pop();
                          }
                          : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime date;
  final ValueChanged<DateTime> onPicked;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DateField({
    required this.label,
    required this.icon,
    required this.date,
    required this.onPicked,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          icon: Icon(icon),
        ),
        child: Text(
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
