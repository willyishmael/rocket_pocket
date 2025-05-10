import 'package:flutter/material.dart';

class AccountCard extends StatelessWidget {
  final int index;
  const AccountCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: SizedBox(
        width: 150.0,
        child: Center(child: Text('Account ${index + 1}')),
      ),
    );
  }
}
