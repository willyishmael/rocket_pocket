import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/viewmodels/add_repayment_view_model.dart';

class AddRepaymentScreen extends ConsumerWidget {
  final Loan loan;

  const AddRepaymentScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelAsync = ref.watch(addRepaymentViewModelProvider);

    return Scaffold(
      body: viewModelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => _AddRepaymentForm(loan: loan, state: state),
      ),
    );
  }
}

class _AddRepaymentForm extends ConsumerWidget {
  final Loan loan;
  final AddRepaymentState state;

  const _AddRepaymentForm({required this.loan, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addRepaymentViewModelProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCollection = loan.type == LoanType.given;
    final title = isCollection ? 'Record Collection' : 'Record Repayment';
    final remaining = loan.amount - loan.repaidAmount;
    final currencyFormat = NumberFormat('#,##0.##');

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
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title),
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Loan summary card ───────────────────────────────────
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          radius: 22,
                          child: Text(
                            loan.counterpartyName.isNotEmpty
                                ? loan.counterpartyName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.counterpartyName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isCollection
                                    ? 'Outstanding: ${currencyFormat.format(remaining)}'
                                    : 'Remaining: ${currencyFormat.format(remaining)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Pocket selector ─────────────────────────────────────
                Text('Pocket', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (state.pockets.isEmpty)
                  Text(
                    'No pockets available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  )
                else
                  DropdownButtonFormField<Pocket>(
                    value: state.selectedPocket,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      icon: Icon(
                        isCollection
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_balance_wallet_outlined,
                      ),
                      hintText: 'Select pocket',
                    ),
                    items:
                        state.pockets.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Text(p.emoticon),
                                const SizedBox(width: 8),
                                Text(p.name),
                                const SizedBox(width: 4),
                                Text(
                                  '(${p.currency} ${currencyFormat.format(p.balance)})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (p) {
                      if (p != null) notifier.setSelectedPocket(p);
                    },
                  ),

                const SizedBox(height: 16),

                // ── Amount ──────────────────────────────────────────────
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Max: ${currencyFormat.format(remaining)}',
                    border: const OutlineInputBorder(),
                    icon: const Icon(Icons.payments_outlined),
                    errorText: state.amount > remaining
                        ? 'Amount cannot exceed remaining (${currencyFormat.format(remaining)})'
                        : null,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v) ?? 0;
                    final clamped = parsed < 0
                        ? 0
                        : (parsed > remaining ? remaining : parsed);
                    notifier.setAmount(clamped);
                  },
                ),

                const SizedBox(height: 16),

                // ── Description ─────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: notifier.setDescription,
                ),

                const SizedBox(height: 16),

                // ── Date picker ─────────────────────────────────────────
                _DateTimeField(
                  label: 'Date',
                  dateTime: state.date,
                  onPicked: notifier.setDate,
                ),

                const SizedBox(height: 32),

                // ── Submit ──────────────────────────────────────────────
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(title),
                  onPressed:
                      state.isValid
                          ? () async {
                            await ref
                                .read(addRepaymentViewModelProvider.notifier)
                                .submit(loan);
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

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final ValueChanged<DateTime> onPicked;

  const _DateTimeField({
    required this.label,
    required this.dateTime,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate == null || !context.mounted) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(dateTime),
        );
        if (pickedTime == null) return;

        onPicked(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          icon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatter.format(dateTime)),
      ),
    );
  }
}
