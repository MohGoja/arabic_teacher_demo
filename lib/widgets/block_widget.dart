import 'package:arabic_teacher_demo/models/graph.dart';
import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
import 'package:arabic_teacher_demo/models/theme/custom_text_style.dart';
import 'package:arabic_teacher_demo/models/tree_node.dart';
import 'package:arabic_teacher_demo/widgets/animated_text.dart';
import 'package:arabic_teacher_demo/widgets/animated_tree_graph.dart';
import 'package:arabic_teacher_demo/widgets/animation_widget.dart';
import 'package:arabic_teacher_demo/widgets/animation_widget.dart';
import 'package:arabic_teacher_demo/widgets/bullet_points_widget.dart';
import 'package:arabic_teacher_demo/widgets/color_text_widget.dart';
import 'package:arabic_teacher_demo/widgets/footnote_widget.dart';
import 'package:arabic_teacher_demo/widgets/info_carousel_block.dart';
import 'package:arabic_teacher_demo/widgets/lesson_card.dart';
import 'package:arabic_teacher_demo/widgets/matching_quiz_widget.dart';
import 'package:arabic_teacher_demo/widgets/multi_quiz_block.dart';
import 'package:arabic_teacher_demo/widgets/quiz_block.dart';
import 'package:arabic_teacher_demo/widgets/selective_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/content_block.dart';

class BlockWidget extends StatefulWidget {
  final ContentBlock block;
  final AnimatedTextMode animatedTextMode;

  const BlockWidget({
    super.key,
    required this.block,
    required this.animatedTextMode,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  final AnimatedTreeController _controller = AnimatedTreeController();
  late final List<TreeNode> nodes;

  @override
  Widget build(BuildContext context) {
    switch (widget.block.type) {
      case BlockType.colorText:
        return ColorTextWidget(
          model: widget.block.data,
          textDirection: TextDirection.rtl,
          textStyle: const TextStyle(fontSize: 34, color: Colors.black),
        );
      case BlockType.selectiveText:
        return SelectiveText(
          model: widget.block.data,
          textDirection: TextDirection.rtl,
          placement: TooltipPlacement.below, // above | below | left | right
          tooltipGap: 10,
          autoplaySequence: true,
          sequenceOrder: SequenceOrder.inputOrder,
          autoplayDelay: const Duration(seconds: 2),
          eachVisibleFor: const Duration(seconds: 3),
          gapBetweenTooltips: const Duration(milliseconds: 500),
        );
      case BlockType.multiStepQuiz:
        return MultiStepQuizBlockWidget(block: widget.block);
      case BlockType.info:
        return InfoCarouselBlock(
          block: widget.block,
          interval: const Duration(milliseconds: 400),
        );

      case BlockType.quiz:
        return QuizBlockWidget(block: widget.block);
      case BlockType.matchingQuiz:
        return MatchingQuizWidget(block: widget.block);
      case BlockType.animation:
        return AnimationWidget(
          animationName: widget.block.data["name"],
          animationType: widget.block.data["type"],
        );

      case BlockType.text:
        return AnimatedBlockText(
          blockData: widget.block.data,
          textStyle: Theme.of(context).extension<CustomTextStyle>()!.lessonText,
          textAlign:
              (widget.block.style?["text-align"] ?? '') == "justify"
                  ? TextAlign.justify
                  : TextAlign.center,
          mode:
              widget
                  .animatedTextMode, // try: typewriter, wave, scramble, slide, boom
          typeCharDelay: const Duration(milliseconds: 25),
          staggerDuration: const Duration(milliseconds: 700),
          scrambleInterval: const Duration(milliseconds: 35),
          showCursor: true,
        );

      case BlockType.example:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("أمثلة:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...List<String>.from(widget.block.data).map((ex) => Text("• $ex")),
          ],
        );
      case BlockType.footnote:
        return FootnoteWidget(widgetText: widget.block.data);
      case BlockType.graph:
        final graphData = widget.block.data; // contains root & nodes
        final graphTitle = graphData.root;
        final oldNodes = graphData.nodes;
        List<TreeNode> nodes =
            oldNodes.asMap().entries.map<TreeNode>((entry) {
              final index = entry.key;
              final node = entry.value as GraphNode;
              return TreeNode(
                id: index.toString(),
                content: LessonCard(
                  flipImage: index % 2 == 1 ? true : false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // main label
                      Text(
                        node.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // children below the label
                      ...node.children.map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                          child: Text(
                            child.label,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // children:
                //     node.children
                //         .map<TreeNode>(
                //           (child) => TreeNode(
                //             id: '${index}_$child',
                //             content: LessonCard(
                //               child: Text(
                //                 child,
                //                 style: const TextStyle(fontSize: 14),
                //               ),
                //             ),
                //           ),
                //         )
                //         .toList(),
              );
            }).toList();

        return Center(
          child: AnimatedTreeGraph(
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xffd3e8f4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    79,
                    118,
                    141,
                  ), // border color
                  width: 2, // border width
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.85), // shadow color
                    spreadRadius: 1, // how much the shadow spreads
                    blurRadius: 6, // blur amount
                    offset: const Offset(2, 2), // x,y offset
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  graphTitle,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            children: nodes,
            controller: _controller,
            autoPlay: true,
            autoPlayInterval: const Duration(milliseconds: 900),
            nodeAnimationDuration: const Duration(milliseconds: 600),
            rootPadding: const EdgeInsets.only(top: 32, bottom: 8),
          ),
        );

      case BlockType.heading:
        return AnimatedBlockText(
          blockData: widget.block.data,
          textStyle: GoogleFonts.amiri(
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
          textAlign:
              (widget.block.style?["text-align"] ?? '') == "justify"
                  ? TextAlign.justify
                  : TextAlign.center,
          mode:
              AnimatedTextMode
                  .boom, // try: typewriter, wave, scramble, slide, boom
          typeCharDelay: const Duration(milliseconds: 25),
          staggerDuration: const Duration(milliseconds: 700),
          scrambleInterval: const Duration(milliseconds: 35),
          showCursor: true,
        );
      case BlockType.bulletPoints:
        final bulletData = widget.block.data;
        BulletStyle style = BulletStyle.modern; // Default to modern for adults

        // Extract style from data if available
        if (bulletData is BulletPointsData && bulletData.style != null) {
          style = bulletData.style!;
        } else if (bulletData is Map && bulletData['style'] != null) {
          switch (bulletData['style'].toString().toLowerCase()) {
            case 'colorful':
              style = BulletStyle.colorful;
              break;
            case 'minimal':
              style = BulletStyle.minimal;
              break;
            default:
              style = BulletStyle.modern;
          }
        }

        return BulletPointsWidget(
          points:
              bulletData is BulletPointsData
                  ? bulletData.points
                  : (bulletData is Map
                      ? List<String>.from(bulletData['points'] ?? [])
                      : List<String>.from(bulletData ?? [])),
          title:
              bulletData is BulletPointsData
                  ? bulletData.title
                  : (bulletData is Map ? bulletData['title'] : null),
          style: style,
          animationDelay: const Duration(milliseconds: 300),
          staggerDelay: const Duration(milliseconds: 200),
          autoPlay: true,
        );
    }
  }
}
