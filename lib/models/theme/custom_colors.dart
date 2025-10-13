import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? lightBg;
  final Color? darkBg;

  const CustomColors({required this.lightBg, required this.darkBg});

  @override
  CustomColors copyWith({Color? lightBg, Color? darkBg}) {
    return CustomColors(
      lightBg: lightBg ?? this.lightBg,
      darkBg: darkBg ?? this.darkBg,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      lightBg: Color.lerp(lightBg, other.lightBg, t),
      darkBg: Color.lerp(darkBg, other.darkBg, t),
    );
  }
}
