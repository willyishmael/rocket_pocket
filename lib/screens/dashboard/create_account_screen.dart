import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/account.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final Account account = Account(
    id: 1,
    name: 'William',
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

class AccountCard extends StatelessWidget {
  final Account account;
  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    account.balance.toString(),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    account.currency,
                    style: const TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Column(
              children: [
                Icon(Icons.arrow_forward, color: Colors.white, size: 28.0),
                Icon(Icons.credit_card, color: Colors.white, size: 28.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
