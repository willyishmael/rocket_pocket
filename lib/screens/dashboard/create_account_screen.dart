import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/account.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/screens/0_widgets/account_card/account_card.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';

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
    colorGradient: ColorGradient(
      name: 'Platinum',
      colors: [Colors.grey.shade900, Colors.grey.shade800],
    ),
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
                    selectedColor: account.colorGradient,
                    onSelected: (color) {
                      setState(() {
                        account.colorGradient = color;
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
