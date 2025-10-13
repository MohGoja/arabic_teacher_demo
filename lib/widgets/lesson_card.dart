import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final double? height; // allow setting height explicitly
  final Color shadowColor;
  final double blurRadius;
  final double? width;
  final Offset offset;
  final bool flipImage;

  const LessonCard({
    super.key,
    required this.child,
    this.padding = 22.0,
    this.height,
    this.width,
    this.shadowColor = Colors.black26,
    this.blurRadius = 6.0,
    this.offset = const Offset(2, 2),
    required this.flipImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: blurRadius, offset: offset),
        ],
      ),
      child: Stack(
        children: [
          // Fill parent card entirely
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform:
                  flipImage ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
              child: Image.asset(
                'assets/images/lesson_card.png',

                fit: BoxFit.fill, // stretch to fill
              ),
            ),
          ),

          // Card content on top
          Padding(padding: EdgeInsets.all(padding), child: child),
        ],
      ),
    );
  }
}
