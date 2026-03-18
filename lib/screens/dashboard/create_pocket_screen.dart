import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_form_fields.dart';
import 'package:rocket_pocket/viewmodels/create_pocket_view_model.dart';

class CreatePocketScreen extends ConsumerStatefulWidget {
  const CreatePocketScreen({super.key});

  @override
  ConsumerState<CreatePocketScreen> createState() => _CreatePocketScreenState();
}

class _CreatePocketScreenState extends ConsumerState<CreatePocketScreen> {
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _emoticonController = TextEditingController(text: '💰');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(
      () => ref
          .read(createPocketViewModelProvider.notifier)
          .setName(_nameController.text),
    );
    _purposeController.addListener(
      () => ref
          .read(createPocketViewModelProvider.notifier)
          .setPurpose(_purposeController.text),
    );
    _emoticonController.addListener(
      () => ref
          .read(createPocketViewModelProvider.notifier)
          .setEmoticon(_emoticonController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _emoticonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(createPocketViewModelProvider);

    return Scaffold(
      body: viewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final pocket = state.pocket;
          final gradients = state.gradients;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                expandedHeight: 150.0,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Create Pocket'),
                ),
              ),
              SliverToBoxAdapter(child: PocketCard(pocket: pocket)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PocketFormFields(
                        nameController: _nameController,
                        purposeController: _purposeController,
                        emoticonController: _emoticonController,
                        gradients: gradients,
                        selectedGradient: pocket.colorGradient,
                        onGradientSelected:
                            (g) => ref
                                .read(createPocketViewModelProvider.notifier)
                                .setColorGradient(g),
                        currency: pocket.currency,
                        onCurrencyChanged:
                            (c) => ref
                                .read(createPocketViewModelProvider.notifier)
                                .setCurrency(c),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initial Deposit',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Pocket Balance',
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          ref
                              .read(createPocketViewModelProvider.notifier)
                              .setBalance(amount);
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await ref
                              .read(createPocketViewModelProvider.notifier)
                              .createPocket(pocket);
                          if (context.mounted) context.pop();
                        },
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
