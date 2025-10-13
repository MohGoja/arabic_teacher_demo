import 'package:flutter/material.dart';

@immutable
class CustomTextStyle extends ThemeExtension<CustomTextStyle> {
  final TextStyle? lessonTitle;
  final TextStyle? lessonText;

  const CustomTextStyle({this.lessonTitle, this.lessonText});

  @override
  CustomTextStyle copyWith({TextStyle? lessonTitle}) {
    return CustomTextStyle(lessonTitle: lessonTitle ?? this.lessonTitle);
  }

  @override
  CustomTextStyle lerp(ThemeExtension<CustomTextStyle>? other, double t) {
    if (other is! CustomTextStyle) return this;
    return CustomTextStyle(
      lessonTitle: TextStyle.lerp(lessonTitle, other.lessonTitle, t),
    );
  }
}
