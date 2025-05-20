import 'dart:ui';

class TwoColorGradient {
  final String name;
  final Color topLeftColor;
  final Color bottomRightColor;

  TwoColorGradient({
    required this.name,
    required this.topLeftColor,
    required this.bottomRightColor,
  });

  TwoColorGradient.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        topLeftColor = Color(json['topLeftColor']),
        bottomRightColor = Color(json['bottomRightColor']);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'topLeftColor': topLeftColor.toARGB32(),
      'bottomRightColor': bottomRightColor.toARGB32(),
    };
  }
}
