import 'package:arabic_teacher_demo/widgets/selective_text_widget.dart'
    show SelectiveTextData;
import 'package:arabic_teacher_demo/widgets/color_text_widget.dart'
    show ColorTextData; // + NEW
import 'package:arabic_teacher_demo/widgets/bullet_points_widget.dart'
    show BulletPointsData;
import 'graph.dart';

enum BlockType {
  text,
  example,
  footnote,
  graph,
  animation,
  heading,
  quiz,
  info,
  multiStepQuiz,
  selectiveText,
  colorText,
  bulletPoints,
}

class ContentBlock {
  final BlockType type;
  final dynamic data;
  final Map<String, dynamic>? style;

  ContentBlock({required this.type, required this.data, this.style});

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    BlockType type = BlockType.values.firstWhere(
      (e) => e.toString() == 'BlockType.${json['type']}',
    );

    dynamic parsedData;
    if (type == BlockType.graph) {
      parsedData = GraphContent.fromJson(json['data']);
    } else if ((type == BlockType.text ||
            type == BlockType.quiz ||
            type == BlockType.info) &&
        json['data'] is List) {
      parsedData = List<Map<String, dynamic>>.from(json['data']);
    } else if (type == BlockType.selectiveText && json['data'] is Map) {
      parsedData = SelectiveTextData.fromMap(
        Map<String, dynamic>.from(json['data']),
      );
    } else if (type == BlockType.colorText && json['data'] is Map) {
      // + NEW
      parsedData = ColorTextData.fromMap(
        Map<String, dynamic>.from(json['data']),
      );
    } else if (type == BlockType.bulletPoints && json['data'] is Map) {
      parsedData = BulletPointsData.fromJson(
        Map<String, dynamic>.from(json['data']),
      );
    } else {
      parsedData = json['data'];
    }

    return ContentBlock(
      type: type,
      data: parsedData,
      style: json['style'] as Map<String, dynamic>?,
    );
  }
}
