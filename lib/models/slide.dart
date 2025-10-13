import 'content_block.dart';

class Slide {
  final String title;
  final List<ContentBlock> blocks;

  Slide({required this.title, required this.blocks});

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      title: json['title'],
      blocks:
          (json['blocks'] as List)
              .map((b) => ContentBlock.fromJson(b))
              .toList(),
    );
  }
}
