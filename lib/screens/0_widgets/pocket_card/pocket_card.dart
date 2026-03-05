import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/pocket.dart';

class PocketCard extends StatelessWidget {
  final Pocket pocket;
  const PocketCard({super.key, required this.pocket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pocket.colorGradient.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                    pocket.name,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    pocket.purpose,
                    style: const TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    pocket.balance.toString(),
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
                        '💳',
                        style: const TextStyle(
                          fontSize: 28.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        pocket.currency,
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
              pocket.emoticon,
              style: const TextStyle(fontSize: 80.0, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
