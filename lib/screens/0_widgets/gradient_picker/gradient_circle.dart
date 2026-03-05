import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';

class GradientCircle extends StatelessWidget {
  final ColorGradient gradient;
  final bool isSelected;

  const GradientCircle({
    super.key,
    required this.gradient,
    this.isSelected = false,
  });

  static const double outerSize = 70.0;
  static const double middleSize = 64.0;
  static const double innerSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Gradient: ${gradient.name}',
          selected: isSelected,
          child: Container(
            width: outerSize,
            height: outerSize,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  )
                : null,
            child: Container(
              width: middleSize,
              height: middleSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradient.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        SizedBox(
          width: 80.0,
          child: Text(
            gradient.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            softWrap: true,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}