import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';
import 'package:rocket_pocket/viewmodels/create_pocket_view_model.dart';

class CreatePocketScreen extends ConsumerWidget {
  const CreatePocketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: () {
                    context.pop();
                  },
                ),
                expandedHeight: 150.0,
                flexibleSpace: const FlexibleSpaceBar(title: Text('Create Pocket')),
              ),
              SliverToBoxAdapter(child: PocketCard(pocket: pocket)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize your pocket',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Pocket Name',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.add_card),
                        ),
                        onChanged: (value) {
                          ref.read(createPocketViewModelProvider.notifier).setName(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Purpose',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.account_balance_wallet),
                        ),
                        onChanged: (value) {
                          ref.read(createPocketViewModelProvider.notifier).setPurpose(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        maxLength: 1,
                        maxLines: 1,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Emoticon',
                          border: const OutlineInputBorder(),
                          icon: const Icon(Icons.emoji_emotions),
                        ),
                        onChanged: (value) {
                          ref.read(createPocketViewModelProvider.notifier).setEmoticon(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      GradientPicker(
                        gradients: gradients,
                        selectedColor: pocket.colorGradient,
                        onSelected: (color) {
                          ref.read(createPocketViewModelProvider.notifier).setColorGradient(color);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initial Deposit',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: CurrencyPickerDropdown(
                              initialValue: pocket.currency,
                              itemBuilder: _buildCurrencyDropdownItem,
                              onValuePicked: (Country? country) {
                                if (country != null) {
                                  ref.read(createPocketViewModelProvider.notifier).setCurrency(country.currencyCode ?? '');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            flex: 2,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Pocket Balance',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final amount = double.tryParse(value) ?? 0.0;
                                ref.read(createPocketViewModelProvider.notifier).setBalance(amount);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await ref.read(createPocketViewModelProvider.notifier).createPocket(pocket);
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

  Widget _buildCurrencyDropdownItem(Country country) => Row(
        children: <Widget>[
          CountryPickerUtils.getDefaultFlagImage(country),
          const SizedBox(width: 16.0),
          Text("${country.currencyCode}"),
        ],
      );
}
