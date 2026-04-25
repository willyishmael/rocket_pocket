import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart' as db;
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/transaction.dart';
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/repositories/budget_repository.dart';
import 'package:rocket_pocket/repositories/pocket_repository.dart';
import 'package:rocket_pocket/repositories/transaction_categories_repository.dart';
import 'package:rocket_pocket/repositories/transaction_repository.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';
import 'package:rocket_pocket/viewmodels/budget_view_model.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';
import 'package:rocket_pocket/viewmodels/transaction_view_model.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({this.transaction, this.transactionId, super.key})
    : assert(transaction != null || transactionId != null);

  final Transaction? transaction;
  final int? transactionId;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late final TransactionRepository _transactionRepository;
  late final PocketRepository _pocketRepository;
  late final TransactionCategoriesRepository _categoryRepository;
  late final BudgetRepository _budgetRepository;

  Transaction? _original;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Pocket> _pockets = const [];
  List<db.TransactionCategory> _categories = const [];
  List<db.Budget> _budgets = const [];

  TransactionType _selectedType = TransactionType.expense;
  Pocket? _senderPocket;
  Pocket? _receiverPocket;
  db.TransactionCategory? _selectedCategory;
  db.Budget? _selectedBudget;
  late DateTime _selectedDate;

  bool get _supportsFullEdit =>
      _original != null &&
      (_original!.type == TransactionType.income ||
          _original!.type == TransactionType.expense ||
          _original!.type == TransactionType.transfer);

  List<db.TransactionCategory> get _filteredCategories {
    if (_selectedType != TransactionType.expense &&
        _selectedType != TransactionType.income) {
      return [];
    }
    return _categories.where((c) => c.type == _selectedType).toList();
  }

  bool get _isValid {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (description.isEmpty || amount <= 0) return false;
    if (_senderPocket == null) return false;
    if (_selectedType == TransactionType.transfer) {
      return _receiverPocket != null && _receiverPocket != _senderPocket;
    }
    return _selectedCategory != null;
  }

  @override
  void initState() {
    super.initState();
    _transactionRepository = ref.read(transactionRepositoryProvider);
    _pocketRepository = ref.read(pocketRepositoryProvider);
    _categoryRepository = ref.read(transactionCategoryRepositoryProvider);
    _budgetRepository = ref.read(budgetRepositoryProvider);
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      Transaction? tx = widget.transaction;
      final id = widget.transactionId;
      if (tx == null && id != null) {
        final row = await _transactionRepository.getTransactionById(id);
        if (row != null) {
          tx = Transaction.fromDb(row);
        }
      }

      final pockets = await _pocketRepository.getAllPockets();
      final categories =
          await _categoryRepository.getAllTransactionCategories();
      final budgets = await _budgetRepository.getAllBudgets();

      if (!mounted) return;

      _original = tx;
      _pockets = pockets;
      _categories = categories;
      _budgets = budgets;

      if (tx != null) {
        _selectedType = tx.type;
        _senderPocket = _findPocketById(tx.senderPocketId);
        _receiverPocket = _findPocketById(tx.receiverPocketId);
        _selectedCategory = _findCategoryById(tx.categoryId);
        _selectedBudget = _findBudgetById(tx.budgetId);
        _descriptionController.text = tx.description;
        _amountController.text = tx.amount.toStringAsFixed(2);
        _selectedDate = tx.date ?? tx.createdAt ?? DateTime.now();

        // Ensure the selected category aligns with type after initialization.
        _syncCategoryWithType();
      } else {
        _selectedDate = DateTime.now();
      }

      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Pocket? _findPocketById(int? id) {
    if (id == null) return null;
    for (final pocket in _pockets) {
      if (pocket.id == id) return pocket;
    }
    return null;
  }

  db.TransactionCategory? _findCategoryById(int? id) {
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  db.Budget? _findBudgetById(int? id) {
    if (id == null) return null;
    for (final budget in _budgets) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  void _syncCategoryWithType() {
    if (_selectedType == TransactionType.transfer) {
      _selectedCategory = null;
      _selectedBudget = null;
      return;
    }

    if (_selectedCategory != null && _selectedCategory!.type == _selectedType) {
      return;
    }

    final filtered = _filteredCategories;
    _selectedCategory = filtered.isNotEmpty ? filtered.first : null;
    if (_selectedType != TransactionType.expense) {
      _selectedBudget = null;
    }
  }

  void _onTypeChanged(TransactionType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      if (type != TransactionType.transfer) {
        _receiverPocket = null;
      }
      _syncCategoryWithType();
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (!mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDate.hour,
        pickedTime?.minute ?? _selectedDate.minute,
      );
    });
  }

  Transaction _buildUpdatedTransaction(Transaction original) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return original.copyWith(
      type: _selectedType,
      senderPocketId: _senderPocket?.id,
      receiverPocketId:
          _selectedType == TransactionType.transfer
              ? _receiverPocket?.id
              : null,
      categoryId:
          _selectedType == TransactionType.transfer
              ? null
              : _selectedCategory?.id,
      budgetId:
          _selectedType == TransactionType.expense ? _selectedBudget?.id : null,
      description: _descriptionController.text.trim(),
      amount: amount,
      date: _selectedDate,
    );
  }

  Future<void> _updatePocketBalance(int? pocketId, double delta) async {
    if (pocketId == null || delta == 0) return;
    final pocket = await _pocketRepository.getPocketById(pocketId);
    if (pocket == null) return;
    await _pocketRepository.updatePocket(
      pocket.copyWith(balance: pocket.balance + delta),
    );
  }

  Future<void> _applyPocketImpact(
    Transaction tx, {
    required bool revert,
  }) async {
    final multiplier = revert ? -1.0 : 1.0;

    if (tx.type.isPositive) {
      await _updatePocketBalance(tx.senderPocketId, tx.amount * multiplier);
      return;
    }

    if (tx.type == TransactionType.transfer) {
      await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
      await _updatePocketBalance(tx.receiverPocketId, tx.amount * multiplier);
      return;
    }

    await _updatePocketBalance(tx.senderPocketId, -tx.amount * multiplier);
  }

  Future<void> _save() async {
    final original = _original;
    if (original == null || original.id == null || !_isValid || _isSaving)
      return;

    final updated = _buildUpdatedTransaction(original);

    setState(() => _isSaving = true);
    try {
      final database = ref.read(db.appDatabaseProvider);
      await database.transaction(() async {
        await _applyPocketImpact(original, revert: true);
        await _transactionRepository.updateTransaction(
          updated.toUpdateCompanion(),
        );
        await _applyPocketImpact(updated, revert: false);
      });

      ref.invalidate(transactionViewModelProvider);
      ref.invalidate(pocketViewModelProvider);
      ref.invalidate(budgetViewModelProvider);

      if (!mounted) return;
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update transaction.')),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final date =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    if (!_supportsFullEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This transaction type is not supported in the full editor yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<TransactionType>(
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
            selected: {_selectedType},
            onSelectionChanged: (value) => _onTypeChanged(value.first),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date & Time',
                border: OutlineInputBorder(),
                icon: Icon(Icons.calendar_today),
              ),
              child: Text(_formatDateTime(_selectedDate)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Pocket>(
            value: _senderPocket,
            decoration: InputDecoration(
              labelText:
                  _selectedType == TransactionType.transfer
                      ? 'From Pocket'
                      : 'Pocket',
              border: const OutlineInputBorder(),
              icon: const Icon(Icons.account_balance_wallet),
            ),
            items:
                _pockets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p.emoticon}  ${p.name} (${CurrencyUtils.format(p.balance, p.currency)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (pocket) => setState(() => _senderPocket = pocket),
          ),
          if (_selectedType == TransactionType.transfer) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<Pocket>(
              value: _receiverPocket,
              decoration: const InputDecoration(
                labelText: 'To Pocket',
                border: OutlineInputBorder(),
                icon: Icon(Icons.account_balance_wallet),
              ),
              items:
                  _pockets
                      .where((p) => p != _senderPocket)
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.emoticon}  ${p.name} (${CurrencyUtils.format(p.balance, p.currency)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (pocket) => setState(() => _receiverPocket = pocket),
            ),
          ],
          if (_selectedType != TransactionType.transfer) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<db.TransactionCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                icon: Icon(Icons.category),
              ),
              items:
                  _filteredCategories
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
              onChanged:
                  (category) => setState(() => _selectedCategory = category),
            ),
          ],
          if (_selectedType == TransactionType.expense &&
              _budgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<db.Budget?>(
              value: _selectedBudget,
              decoration: const InputDecoration(
                labelText: 'Budget (optional)',
                border: OutlineInputBorder(),
                icon: Icon(Icons.savings),
              ),
              items: [
                const DropdownMenuItem<db.Budget?>(
                  value: null,
                  child: Text('None'),
                ),
                ..._budgets.map(
                  (b) => DropdownMenuItem<db.Budget?>(
                    value: b,
                    child: Text(b.name),
                  ),
                ),
              ],
              onChanged: (budget) => setState(() => _selectedBudget = budget),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              icon: Icon(Icons.notes),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              icon: Icon(Icons.payments),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isSaving || !_isValid ? null : _save,
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
