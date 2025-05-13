import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/account.dart';
import 'package:rocket_pocket/screens/dashboard/account_card.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final Account account = Account(
    id: 1,
    name: 'Main Account',
    balance: 1000.0,
    currency: 'USD',
    accentColor: Colors.blue.value,
  );

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
                spacing: 16.0,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.add_card),
                    ),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Balance',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Currency',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.monetization_on),
                    ),
                  ),
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'Accent Color',
                      border: OutlineInputBorder(),
                      icon: const Icon(Icons.color_lens),
                    ),
                    items: [
                      DropdownMenuItem(value: Colors.red, child: Text('Red')),
                      DropdownMenuItem(
                        value: Colors.green,
                        child: Text('Green'),
                      ),
                      DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                    ],
                    onChanged: (value) {
                      // Handle color selection
                    },
                  ),
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
}
