import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_circle.dart';

class GradientPicker extends StatelessWidget {
  final List<ColorGradient> gradients;
  final ColorGradient selectedColor;
  final ValueChanged<ColorGradient> onSelected;
  const GradientPicker({
    super.key,
    required this.gradients,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gradients.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4.0),
        itemBuilder: (context, index) {
          final isSelected = gradients[index].name == selectedColor.name;
          return InkWell(
            onTap: () => onSelected(gradients[index]),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: GradientCircle(
                gradient: gradients[index],
                isSelected: isSelected,
              ),
            ),
          );
        },
      ),
    );
  }
}
