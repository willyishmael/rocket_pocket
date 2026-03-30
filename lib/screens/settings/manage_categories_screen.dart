import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/local/database.dart'
    show TransactionCategory;
import 'package:rocket_pocket/data/model/transaction_type.dart';
import 'package:rocket_pocket/viewmodels/category_view_model.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TransactionType get _activeType =>
      _tabController.index == 0
          ? TransactionType.expense
          : TransactionType.income;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryViewModelProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                title: const Text('Manage Categories'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
                ),
              ),
            ],
        body: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data:
              (categories) => TabBarView(
                controller: _tabController,
                children: [
                  _CategoryList(
                    categories:
                        categories
                            .where((c) => c.type == TransactionType.expense)
                            .toList(),
                  ),
                  _CategoryList(
                    categories:
                        categories
                            .where((c) => c.type == TransactionType.income)
                            .toList(),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(
                'Add ${_activeType == TransactionType.expense ? 'Expense' : 'Income'} Category',
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.of(ctx).pop(true),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Add'),
                ),
              ],
            ),
      );

      if (confirmed == true && controller.text.trim().isNotEmpty) {
        await ref
            .read(categoryViewModelProvider.notifier)
            .addCategory(controller.text.trim(), _activeType);
      }
    } finally {
      controller.dispose();
    }
  }
}

class _CategoryList extends ConsumerWidget {
  final List<TransactionCategory> categories;

  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          title: Text(category.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Rename',
                onPressed: () => _showRenameDialog(context, ref, category),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref, category),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
  ) async {
    final controller = TextEditingController(text: category.name);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Rename Category'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.of(ctx).pop(true),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      if (confirmed == true && controller.text.trim().isNotEmpty) {
        await ref
            .read(categoryViewModelProvider.notifier)
            .renameCategory(category.id, controller.text.trim());
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Category?'),
            content: Text(
              '"${category.name}" will be removed. This may affect transactions that are currently assigned to this category.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref
          .read(categoryViewModelProvider.notifier)
          .deleteCategory(category.id);
    }
  }
}
