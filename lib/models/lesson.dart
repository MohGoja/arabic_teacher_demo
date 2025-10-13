import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'slide.dart';

class Lesson {
  final String id;
  final String title;
  final List<Slide> slides;

  Lesson({required this.id, required this.title, required this.slides});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      slides: (json['slides'] as List).map((s) => Slide.fromJson(s)).toList(),
    );
  }
}

/// Call this to get all lessons from assets/lessons.json
Future<List<Lesson>> loadLessons() async {
  final String response = await rootBundle.loadString(
    'assets/lesson_sample.json',
    // 'assets/test_lesson.json',
  );
  final dynamic decoded = json.decode(response);

  if (decoded is List) {
    // Top-level array
    return decoded
        .map<Lesson>((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  } else if (decoded is Map<String, dynamic>) {
    if (decoded.containsKey('lessons') && decoded['lessons'] is List) {
      // Wrapped object with "lessons"
      return (decoded['lessons'] as List)
          .map<Lesson>((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Single lesson object (backward compatible)
      return [Lesson.fromJson(decoded)];
    }
  } else {
    throw const FormatException('Unexpected JSON format for lessons');
  }
}

/// Load a specific lesson by its ID
Future<Lesson> loadLessonById(String lessonId) async {
  final String response = await rootBundle.loadString(
    'assets/lessons/$lessonId.json',
  );
  final Map<String, dynamic> decoded = json.decode(response);
  return Lesson.fromJson(decoded);
}
