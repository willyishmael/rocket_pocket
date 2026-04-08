import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/budget.dart';
import 'package:rocket_pocket/data/model/enums.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final budget = Budget(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      period: _selectedPeriod,
      startDate: _startDate,
      createdAt: DateTime.now(),
    );

    await ref.read(budgetViewModelProvider.notifier).addBudget(budget);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            expandedHeight: 120.0,
            flexibleSpace: const FlexibleSpaceBar(title: Text('Add Budget')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name ─────────────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Name',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.label),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Amount ───────────────────────────────────────────
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.payments),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final amount = double.tryParse(v.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Period ───────────────────────────────────────────
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

                    // ── Start date ──────────────────────────────────────
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

                    // ── Submit ───────────────────────────────────────────
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.check),
                      onPressed: _isSubmitting ? null : _submit,
                      label: const Text('Save Budget'),
                    ),
                  ],
                ),
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
