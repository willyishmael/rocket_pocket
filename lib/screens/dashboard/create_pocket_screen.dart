import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';

class CreatePocketScreen extends StatefulWidget {
  const CreatePocketScreen({super.key});

  @override
  State<CreatePocketScreen> createState() => _CreatePocketScreenState();
}

class _CreatePocketScreenState extends State<CreatePocketScreen> {
  Pocket pocket = Pocket(
    name: '',
    purpose: '',
    currency: 'IDR',
    balance: 0.0,
    colorGradient: ColorGradient(
      name: 'Platinum',
      colors: [Colors.grey.shade900, Colors.grey.shade800],
    ),
    emoticon: '💰',
  );

  List<ColorGradient> gradients = [
    ColorGradient(
      name: 'Platinum',
      colors: [Colors.grey.shade900, const Color.fromARGB(255, 91, 94, 106)],
    ),
    ColorGradient(
      name: 'Blueberry',
      colors: [Colors.blueAccent, Colors.purpleAccent],
    ),
    ColorGradient(
      name: 'Fire',
      colors: [Colors.redAccent, Colors.orangeAccent],
    ),
    ColorGradient(
      name: 'Mint',
      colors: [Colors.greenAccent, Colors.tealAccent],
    ),
    ColorGradient(
      name: 'Peach',
      colors: [Colors.pinkAccent, Colors.orangeAccent],
    ),
    ColorGradient(
      name: 'Lavender',
      colors: [Colors.purpleAccent, Colors.blueAccent],
    ),
    ColorGradient(
      name: 'Lemonade',
      colors: [Colors.yellowAccent, Colors.pinkAccent],
    ),
  ];

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
                spacing: 16.0,
                children: [
                  Text(
                    'Customize your pocket',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Pocket Name',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.add_card),
                    ),
                    onChanged: (value) {
                      setState(() {
                        pocket.name = value;
                      });
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.account_balance_wallet),
                    ),
                    onChanged: (value) {
                      setState(() {
                        pocket.purpose = value;
                      });
                    },
                  ),
                  TextField(
                    maxLength: 1,
                    maxLines: 1,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Emoticon',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.emoji_emotions),
                    ),
                    onChanged: (value) {
                      setState(() {
                        pocket.emoticon = value;
                      });
                    },
                  ),
                  GradientPicker(
                    gradients: gradients,
                    selectedColor: pocket.colorGradient,
                    onSelected: (color) {
                      setState(() {
                        pocket.colorGradient = color;
                      });
                    },
                  ),

                  Text(
                    'Initial Deposit',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: CurrencyPickerDropdown(
                          initialValue: 'IDR',
                          itemBuilder: _buildCurrencyDropdownItem,
                          onValuePicked: (Country? country) {
                            if (country != null) {
                              setState(() {
                                pocket.currency = country.currencyCode ?? '';
                              });
                            }
                          },
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Pocket Balance',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              pocket.balance = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      print('Pocket Created');
                    },
                    label: const Text('Create'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdownItem(Country country) => Row(
    children: <Widget>[
      CountryPickerUtils.getDefaultFlagImage(country),
      SizedBox(width: 16.0),
      Text("${country.currencyCode}"),
    ],
  );
}
