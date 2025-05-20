import 'dart:ui';

class ColorGradient {
  final String name;
  final List<Color> colors;

  ColorGradient({required this.name, required this.colors});

  ColorGradient.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      colors =
          (json['colors'] as List<dynamic>)
              .map((color) => Color(color as int))
              .toList();

  Map<String, dynamic> toJson() => {
    'name': name,
    'colors': colors.map((color) => color.toARGB32()).toList(),
  };
}
