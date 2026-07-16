import 'package:flutter/material.dart';
import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/screens/transaction/widgets/transaction_form_fields.dart';
import 'package:rocket_pocket/viewmodels/add_loan_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

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
    final livePockets =
        ref.watch(pocketViewModelProvider).value ?? state.pockets;
    final selectedPocketId = state.selectedPocket?.id;
    final liveSelectedPocket =
        selectedPocketId == null
            ? state.selectedPocket
            : livePockets.where((p) => p.id == selectedPocketId).firstOrNull;
    final hasMismatchedPocketCurrency =
        liveSelectedPocket != null &&
        liveSelectedPocket.currency != state.currency;
    final hasInsufficientDownPaymentBalance =
        state.isPurchaseInstallment &&
        liveSelectedPocket != null &&
        !hasMismatchedPocketCurrency &&
        state.downPaymentAmount > liveSelectedPocket.balance;
    final hasInsufficientPocketBalance =
        state.financingKind == LoanFinancingKind.cashLoan &&
        state.selectedType == LoanType.given &&
        liveSelectedPocket != null &&
        !hasMismatchedPocketCurrency &&
        state.financedPrincipal > liveSelectedPocket.balance;
    final previewPlan = state.previewPlan;

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
            titlePadding: EdgeInsets.only(left: 16, bottom: 16),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Financing',
                  subtitle: 'Choose the obligation type and cashflow behavior.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LoanFinancingKind>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: LoanFinancingKind.cashLoan,
                        label: Text('Cash Loan'),
                        icon: Icon(Icons.account_balance_outlined),
                      ),
                      ButtonSegment(
                        value: LoanFinancingKind.purchaseInstallment,
                        label: Text('Purchase Installment'),
                        icon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ],
                    selected: {state.financingKind},
                    onSelectionChanged:
                        (v) => notifier.setFinancingKind(v.first),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Loan type ──────────────────────────────────────────
                if (!state.isPurchaseInstallment) ...[
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
                ] else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.call_received),
                    title: const Text('Purchase Installment'),
                    subtitle: const Text(
                      'Creates a payable schedule. No loan-in cashflow is posted to your pocket.',
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _SectionHeader(
                  title: 'Core Info',
                  subtitle: 'Identify who you owe or who owes you.',
                ),
                const SizedBox(height: 12),

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

                CurrencyPickerDropdown(
                  initialValue: state.currency,
                  itemBuilder: _buildCurrencyItem,
                  onValuePicked: (Country? country) {
                    if (country != null) {
                      notifier.setCurrency(
                        country.currencyCode ?? state.currency,
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ── Associated Pocket (optional) ────────────────────────
                if (state.pockets.isNotEmpty)
                  TransactionPocketDropdown(
                    label: 'Associated Pocket (optional)',
                    pockets: state.pockets,
                    value: state.selectedPocket,
                    includeNoPocketOption: true,
                    noPocketLabel: 'No pocket',
                    errorText:
                        hasMismatchedPocketCurrency
                            ? 'Pocket currency must match loan currency'
                            : hasInsufficientDownPaymentBalance
                            ? 'Insufficient pocket balance for down payment'
                            : hasInsufficientPocketBalance
                            ? 'Insufficient pocket balance for loan given'
                            : null,
                    onChanged: notifier.setSelectedPocket,
                  )
                else
                  Text(
                    'No pockets available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Amount ─────────────────────────────────────────────
                TextFormField(
                  decoration: InputDecoration(
                    labelText:
                        state.isPurchaseInstallment
                            ? 'Purchase Price'
                            : 'Principal Amount',
                    border: OutlineInputBorder(),
                    icon: const Icon(Icons.payments_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => notifier.setAmount(double.tryParse(v) ?? 0),
                ),

                if (state.isPurchaseInstallment) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Down Payment',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.south_west),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged:
                        (v) => notifier.setDownPaymentAmount(
                          double.tryParse(v) ?? 0,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _InlineSummaryRow(
                    label: 'Financed Principal',
                    value:
                        '${state.currency} ${state.financedPrincipal.toStringAsFixed(2)}',
                  ),
                ],

                if (hasMismatchedPocketCurrency)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text(
                      'Selected pocket currency does not match the loan currency.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                else if (hasInsufficientDownPaymentBalance)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text(
                      'Down payment exceeds selected pocket balance.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                else if (hasInsufficientPocketBalance)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text(
                      'Amount exceeds selected pocket balance.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                _SectionHeader(
                  title: 'Installments',
                  subtitle: 'Define the monthly repayment structure.',
                ),
                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Installments',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.format_list_numbered),
                  ),
                  initialValue: state.installmentCount.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    notifier.setInstallmentCount(int.tryParse(v) ?? 1);
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Monthly Interest %',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.percent),
                  ),
                  initialValue: state.monthlyInterestRatePercent.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    notifier.setMonthlyInterestRatePercent(
                      double.tryParse(v) ?? 0,
                    );
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Fee',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                  initialValue: state.additionalFeeAmount.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    notifier.setAdditionalFeeAmount(double.tryParse(v) ?? 0);
                  },
                ),

                const SizedBox(height: 16),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Installment Reminder'),
                  subtitle: const Text(
                    'Enable reminder notifications for this loan.',
                  ),
                  value: state.isReminderEnabled,
                  onChanged: notifier.setReminderEnabled,
                ),

                Wrap(
                  spacing: 8,
                  children:
                      const [0, 1, 2, 3, 5, 7, 14]
                          .map(
                            (days) => ChoiceChip(
                              label: Text(
                                days == 0 ? 'On due date' : '$days d',
                              ),
                              selected: state.reminderDaysBefore == days,
                              onSelected:
                                  state.isReminderEnabled
                                      ? (_) =>
                                          notifier.setReminderDaysBefore(days)
                                      : null,
                            ),
                          )
                          .toList(),
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
                        label:
                            state.usesInstallments
                                ? 'First Due Date'
                                : 'Due Date',
                        icon: Icons.event_outlined,
                        date: state.dueDate,
                        onPicked: notifier.setDueDate,
                        firstDate: state.startDate,
                        lastDate: DateTime(2100),
                      ),
                    ),
                  ],
                ),
                if (state.usesInstallments)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text(
                      'The final due date will be calculated from the first due date and installment count.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                if (previewPlan != null) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Schedule Preview',
                    subtitle: 'Review totals and first upcoming installments.',
                  ),
                  const SizedBox(height: 12),
                  _SchedulePreviewCard(state: state),
                ],

                const SizedBox(height: 32),

                // ── Submit ─────────────────────────────────────────────
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Save Loan'),
                  onPressed:
                      state.isValid &&
                              !hasMismatchedPocketCurrency &&
                              !hasInsufficientDownPaymentBalance &&
                              !hasInsufficientPocketBalance
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

  Widget _buildCurrencyItem(Country country) => Row(
    children: [
      CountryPickerUtils.getDefaultFlagImage(country),
      const SizedBox(width: 16),
      Text('${country.currencyCode}'),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InlineSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _InlineSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _SchedulePreviewCard extends StatelessWidget {
  final AddLoanState state;

  const _SchedulePreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final plan = state.previewPlan;
    if (plan == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final previewLines =
        plan.lines.length <= 3 ? plan.lines : plan.lines.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InlineSummaryRow(
              label: 'Total Payable',
              value:
                  '${state.currency} ${plan.totalPayable.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _InlineSummaryRow(
              label: 'Interest Total',
              value:
                  '${state.currency} ${plan.totalInterest.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _InlineSummaryRow(
              label: 'Additional Fee',
              value: '${state.currency} ${plan.totalFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _InlineSummaryRow(
              label: 'Installment Count',
              value: '${plan.lines.length}',
            ),
            const SizedBox(height: 12),
            Text('Upcoming', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ...previewLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${line.sequence}  ${_formatDate(line.dueDate)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${state.currency} ${line.totalDue.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (plan.lines.length > previewLines.length)
              Text(
                '+${plan.lines.length - previewLines.length} more installments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
