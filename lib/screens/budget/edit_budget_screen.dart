import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/budget.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

class EditBudgetScreen extends ConsumerStatefulWidget {
  final Budget budget;

  const EditBudgetScreen({super.key, required this.budget});

  @override
  ConsumerState<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends ConsumerState<EditBudgetScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late BudgetPeriod _selectedPeriod;
  late DateTime _startDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _amountController = TextEditingController(
      text: widget.budget.amount.toString(),
    );
    _selectedPeriod = widget.budget.period;
    _startDate = widget.budget.startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) > 0;

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    try {
      final updated = widget.budget.copyWith(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        period: _selectedPeriod,
        startDate: _startDate,
      );
      await ref.read(budgetViewModelProvider.notifier).updateBudget(updated);
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
              title: Text('Edit Budget'),
              titlePadding: EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name ───────────────────────────────────────────
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Budget Name',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.label),
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
                      icon: Icon(Icons.payments),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // ── Period ─────────────────────────────────────────
                  DropdownButtonFormField<BudgetPeriod>(
                    initialValue: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.repeat),
                    ),
                    items:
                        BudgetPeriod.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(_periodLabel(p)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPeriod = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Start date ─────────────────────────────────────
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_startDate.year}-'
                        '${_startDate.month.toString().padLeft(2, '0')}-'
                        '${_startDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Save ───────────────────────────────────────────
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.check),
                    onPressed: (_saving || !_isValid) ? null : _save,
                    label: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.once:
        return 'One-time';
    }
  }
}
