import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/account.dart';
import 'package:rocket_pocket/data/model/two_color_gradient.dart';
import 'package:rocket_pocket/screens/dashboard/account_card.dart';
import 'package:rocket_pocket/screens/dashboard/gradient_circle.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  Account account = Account(
    name: '',
    currency: '',
    balance: 0.0,
    accentColor: Colors.blue.toARGB32(),
  );

  List<TwoColorGradient> gradients = [
    // --- Soft, pastel combos above ---
    TwoColorGradient(
      name: 'Blueberry',
      topLeftColor: Colors.blue,
      bottomRightColor: Colors.pinkAccent,
    ),
    TwoColorGradient(
      name: 'Minty',
      topLeftColor: Colors.greenAccent,
      bottomRightColor: Colors.teal,
    ),
    TwoColorGradient(
      name: 'Lavender',
      topLeftColor: Colors.purple,
      bottomRightColor: Colors.pinkAccent,
    ),
    TwoColorGradient(
      name: 'Peachy',
      topLeftColor: Colors.orangeAccent,
      bottomRightColor: Colors.pinkAccent,
    ),

    // --- Brave, vibrant combos below ---
    TwoColorGradient(
      name: 'Sunset',
      topLeftColor: Colors.deepOrange,
      bottomRightColor: Colors.purpleAccent,
    ),
    TwoColorGradient(
      name: 'Aqua Lemon',
      topLeftColor: Colors.cyan,
      bottomRightColor: Colors.yellowAccent,
    ),
    TwoColorGradient(
      name: 'Fire',
      topLeftColor: Colors.red,
      bottomRightColor: Colors.amber,
    ),
    TwoColorGradient(
      name: 'Electric',
      topLeftColor: Colors.lightGreenAccent,
      bottomRightColor: Colors.indigo,
    ),
    TwoColorGradient(
      name: 'Bubblegum',
      topLeftColor: Colors.pinkAccent,
      bottomRightColor: Colors.lightBlueAccent,
    ),
    TwoColorGradient(
      name: 'Lime Magenta',
      topLeftColor: Colors.lime,
      bottomRightColor: Colors.purple,
    ),
    TwoColorGradient(
      name: 'Ocean',
      topLeftColor: Colors.teal,
      bottomRightColor: Colors.blueAccent,
    ),
    TwoColorGradient(
      name: 'Gold Mint',
      topLeftColor: Colors.amber,
      bottomRightColor: Colors.tealAccent,
    ),
    TwoColorGradient(
      name: 'Nightlife',
      topLeftColor: Colors.deepPurple,
      bottomRightColor: Colors.pinkAccent,
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
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Create Account'),
            ),
          ),
          SliverToBoxAdapter(child: AccountCard(account: account)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16.0,
                children: [
                  Text(
                    'Customize your account',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.add_card),
                    ),
                    onChanged: (value) {
                      setState(() {
                        account.name = value;
                      });
                    },
                  ),

                  /// Extract this gradient picker widget
                  GradientPicker(
                    gradients: gradients,
                    selectedColor: account.accentColor,
                    onSelected: (color) {
                      setState(() {
                        account.accentColor = color;
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
                        flex: 3,
                        child: CurrencyPickerDropdown(
                          initialValue: 'INR',
                          itemBuilder: _buildCurrencyDropdownItem,
                          onValuePicked: (Country? country) {
                            if (country != null) {
                              print("${country.name}");
                            }
                          },
                        ),
                      ),
                      Flexible(
                        flex: 5,
                        child: TextField(
                          inputFormatters: [
                            CurrencyTextInputFormatter.simpleCurrency(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Account Balance',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              account.balance = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Handle account creation
                      print('Account Created');
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
          ),
          // Add your form or other widgets here
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

class GradientPicker extends StatelessWidget {
  final List<TwoColorGradient> gradients;
  final int selectedColor;
  final ValueChanged<int> onSelected;
  const GradientPicker({
    super.key,
    required this.gradients,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gradients.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16.0),
        itemBuilder: (context, index) {
          final isSelected =
              selectedColor == gradients[index].topLeftColor.toARGB32();
          return InkWell(
            onTap: () => onSelected(gradients[index].topLeftColor.toARGB32()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
              ),
              child: GradientCircle(gradient: gradients[index]),
            ),
          );
        },
      ),
    );
  }
}
