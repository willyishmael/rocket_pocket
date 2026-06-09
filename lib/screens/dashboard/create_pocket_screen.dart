import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_form_fields.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_header.dart';
import 'package:rocket_pocket/viewmodels/create_pocket_view_model.dart';

class CreatePocketScreen extends ConsumerStatefulWidget {
  const CreatePocketScreen({super.key});

  @override
  ConsumerState<CreatePocketScreen> createState() => _CreatePocketScreenState();
}

class _CreatePocketScreenState extends ConsumerState<CreatePocketScreen> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: '💰');
  bool _showNameError = false;
  static const double _expandedHeight = 250.0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      ref
          .read(createPocketViewModelProvider.notifier)
          .setName(_nameController.text);
      if (_showNameError && _nameController.text.trim().isNotEmpty) {
        setState(() => _showNameError = false);
      }
    });
    _iconController.addListener(
      () => ref
          .read(createPocketViewModelProvider.notifier)
          .setIcon(_iconController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
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
          final canCreate = pocket.name.trim().isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _expandedHeight,
                backgroundColor: pocket.colorGradient.colors.first,
                foregroundColor: Colors.white,
                title: const Text('Create Pocket'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: PocketHeader(pocket: pocket),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gradients.isNotEmpty)
                        GradientPicker(
                          gradients: gradients,
                          selectedColor: pocket.colorGradient,
                          onSelected:
                              (g) => ref
                                  .read(createPocketViewModelProvider.notifier)
                                  .setColorGradient(g),
                        ),
                      if (gradients.isNotEmpty) const SizedBox(height: 16),
                      PocketFormFields(
                        nameController: _nameController,
                        iconController: _iconController,
                        nameErrorText:
                            _showNameError ? 'Pocket name is required' : null,
                        showGradientPicker: false,
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
                        onPressed:
                            canCreate
                                ? () async {
                                  await ref
                                      .read(
                                        createPocketViewModelProvider.notifier,
                                      )
                                      .createPocket(pocket);
                                  if (context.mounted) context.pop();
                                }
                                : () {
                                  setState(() => _showNameError = true);
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
