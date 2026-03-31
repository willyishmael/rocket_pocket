import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/data/model/loan.dart';
import 'package:rocket_pocket/viewmodels/loan_view_model.dart';

class EditLoanScreen extends ConsumerStatefulWidget {
  final Loan loan;

  const EditLoanScreen({super.key, required this.loan});

  @override
  ConsumerState<EditLoanScreen> createState() => _EditLoanScreenState();
}

class _EditLoanScreenState extends ConsumerState<EditLoanScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late LoanStatus _status;
  late DateTime _startDate;
  late DateTime _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.loan.counterpartyName);
    _amountController = TextEditingController(
      text: widget.loan.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.loan.description,
    );
    _status = widget.loan.status;
    _startDate = widget.loan.startDate;
    _dueDate = widget.loan.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) > 0;

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    try {
      final updated = widget.loan.copyWith(
        counterpartyName: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        status: _status,
        startDate: _startDate,
        dueDate: _dueDate,
      );
      await ref
          .read(loanViewModelProvider.notifier)
          .updateLoan(updated.toUpdateCompanion());
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
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
              title: Text('Edit Loan'),
              titlePadding: EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Loan type (read-only) ──────────────────────────
                  Row(
                    children: [
                      Icon(
                        widget.loan.type == LoanType.given
                            ? Icons.call_made
                            : Icons.call_received,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.loan.type == LoanType.given
                            ? 'Loan Given'
                            : 'Loan Taken',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Counterparty name ──────────────────────────────
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Counterparty Name',
                      hintText: 'Person or organization',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // ── Amount ─────────────────────────────────────────
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // ── Description ────────────────────────────────────
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 24),

                  // ── Status ─────────────────────────────────────────
                  Text('Status', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LoanStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.flag_outlined),
                    ),
                    items:
                        LoanStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          );
                        }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Dates ──────────────────────────────────────────
                  Text('Duration', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start Date',
                          icon: Icons.calendar_today_outlined,
                          date: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          onPicked: (d) => setState(() => _startDate = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Due Date',
                          icon: Icons.event_outlined,
                          date: _dueDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                          onPicked: (d) => setState(() => _dueDate = d),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Save ───────────────────────────────────────────
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon:
                        _saving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    onPressed: (_isValid && !_saving) ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(LoanStatus s) => switch (s) {
    LoanStatus.ongoing => 'Ongoing',
    LoanStatus.completed => 'Completed',
    LoanStatus.overdue => 'Overdue',
    LoanStatus.cancelled => 'Cancelled',
  };
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    required this.icon,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
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
