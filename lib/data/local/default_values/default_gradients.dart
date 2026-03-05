import 'package:flutter/material.dart' as material;
import 'package:rocket_pocket/data/local/database.dart';

final defaultGradients = [
        ColorGradientsCompanion.insert(
          name: 'Platinum',
          colors: [
            material.Colors.grey.shade900,
            const material.Color.fromARGB(255, 91, 94, 106),
          ],
        ),
        ColorGradientsCompanion.insert(
          name: 'Blueberry',
          colors: [material.Colors.blueAccent, material.Colors.purpleAccent],
        ),
        ColorGradientsCompanion.insert(
          name: 'Fire',
          colors: [material.Colors.redAccent, material.Colors.orangeAccent],
        ),
        ColorGradientsCompanion.insert(
          name: 'Mint',
          colors: [material.Colors.greenAccent, material.Colors.tealAccent],
        ),
        ColorGradientsCompanion.insert(
          name: 'Peach',
          colors: [material.Colors.pinkAccent, material.Colors.orangeAccent],
        ),
        ColorGradientsCompanion.insert(
          name: 'Lavender',
          colors: [material.Colors.purpleAccent, material.Colors.blueAccent],
        ),
        ColorGradientsCompanion.insert(
          name: 'Lemonade',
          colors: [material.Colors.yellowAccent, material.Colors.pinkAccent],
        ),
      ];