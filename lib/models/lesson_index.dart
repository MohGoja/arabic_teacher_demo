import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LessonIndex {
  final String id;
  final String title;
  final int slideCount;

  LessonIndex({
    required this.id,
    required this.title,
    required this.slideCount,
  });

  factory LessonIndex.fromJson(Map<String, dynamic> json) {
    return LessonIndex(
      id: json['id'] as String,
      title: json['title'] as String,
      slideCount: json['slideCount'] as int,
    );
  }
}

/// Load the lesson index for the main screen
Future<List<LessonIndex>> loadLessonIndex() async {
  final String response = await rootBundle.loadString(
    'assets/lesson_index.json',
  );
  final Map<String, dynamic> decoded = json.decode(response);

  return (decoded['lessons'] as List)
      .map<LessonIndex>((e) => LessonIndex.fromJson(e as Map<String, dynamic>))
      .toList();
}
