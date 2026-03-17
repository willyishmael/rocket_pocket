import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/utils/currency_utils.dart';

class PocketHeader extends StatelessWidget {
  final Pocket pocket;

  const PocketHeader({super.key, required this.pocket});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pocket.colorGradient.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: topPadding,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pocket.purpose,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyUtils.format(pocket.balance, pocket.currency),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('💳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      pocket.currency,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(pocket.emoticon, style: const TextStyle(fontSize: 64)),
        ],
      ),
    );
  }
}
