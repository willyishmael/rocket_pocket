import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/two_color_gradient.dart';

class GradientCircle extends StatelessWidget {
  final TwoColorGradient gradient;

  const GradientCircle({
    super.key,
    required this.gradient,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [gradient.topLeftColor, gradient.bottomRightColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          gradient.name,
          style: Theme.of(context).textTheme.labelSmall
        ),
      ],
    );
  }
}