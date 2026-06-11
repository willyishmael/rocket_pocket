import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
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
    final hasMismatchedPocketCurrency =
        state.selectedPocket != null &&
        state.selectedPocket!.currency != loan.currency;
    final displayCurrency = loan.currency;
    final hasInsufficientPocketBalance =
        !isCollection &&
        state.selectedPocket != null &&
        !hasMismatchedPocketCurrency &&
        state.amount > state.selectedPocket!.balance;

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
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    ? 'Outstanding: ${CurrencyUtils.format(remaining, displayCurrency)}'
                                    : 'Remaining: ${CurrencyUtils.format(remaining, displayCurrency)}',
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
                TransactionDateTimeSection(
                  dateTime: state.date,
                  onPicked: notifier.setDate,
                ),
                const SizedBox(height: 24),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.currency_exchange),
                  ),
                  child: Text(loan.currency),
                ),
                const SizedBox(height: 24),
                if (state.pockets.isEmpty)
                  Text(
                    'No pockets available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  )
                else
                  TransactionPocketDropdown(
                    label: 'Pocket',
                    pockets: state.pockets,
                    value: state.selectedPocket,
                    includeNoPocketOption: true,
                    noPocketLabel: 'No pocket',
                    errorText:
                        hasMismatchedPocketCurrency
                            ? 'Pocket currency must match loan currency'
                            : hasInsufficientPocketBalance
                            ? 'Insufficient pocket balance'
                            : null,
                    onChanged: notifier.setSelectedPocket,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText:
                        'Max: ${CurrencyUtils.format(remaining, displayCurrency)}',
                    border: const OutlineInputBorder(),
                    icon: const Icon(Icons.payments_outlined),
                    errorText:
                        state.amount > remaining
                            ? 'Amount cannot exceed remaining (${CurrencyUtils.format(remaining, displayCurrency)})'
                            : hasMismatchedPocketCurrency
                            ? 'Selected pocket currency does not match the loan currency'
                            : hasInsufficientPocketBalance
                            ? 'Amount exceeds selected pocket balance'
                            : null,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v) ?? 0;
                    final double clamped =
                        parsed < 0
                            ? 0
                            : (parsed > remaining ? remaining : parsed);
                    notifier.setAmount(clamped);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: notifier.setDescription,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(title),
                  onPressed:
                      state.isValid &&
                              !hasMismatchedPocketCurrency &&
                              !hasInsufficientPocketBalance
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
