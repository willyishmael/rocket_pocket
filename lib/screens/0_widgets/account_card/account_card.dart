import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: account.colorGradient.colors,
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
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Savings Account',
                    style: const TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    account.balance.toString(),
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Text(
                        '💳', // Example emoticon
                        style: const TextStyle(
                          fontSize: 28.0, // Adjust the size as needed
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        account.currency,
                        style: const TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Text(
              '➡️', // Example emoticon
              style: const TextStyle(
                fontSize: 80.0, // Adjust the size as needed
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

