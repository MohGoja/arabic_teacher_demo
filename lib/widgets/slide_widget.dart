// import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
// import 'package:arabic_teacher_demo/models/theme/custom_text_style.dart';
// import 'package:arabic_teacher_demo/widgets/animated_text.dart';
// import 'package:flutter/material.dart';
// import '../models/slide.dart';
// import 'block_widget.dart';

// class SlideWidget extends StatelessWidget {
//   final Slide slide;
//   final AnimatedTextMode animatedTextMode;
//   const SlideWidget({
//     super.key,
//     required this.slide,
//     required this.animatedTextMode,
//   });
//   static const double thisIconSize = 20.0;

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       // padding: const EdgeInsets.all(16),
//       children: [
//         Container(
//           height: 100,
//           color: Theme.of(context).extension<CustomColors>()!.lightBg,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 slide.title,
//                 style:
//                     Theme.of(context).extension<CustomTextStyle>()!.lessonTitle,
//               ),

//               // const SizedBox(height: 10),
//               // Row(
//               //   mainAxisAlignment: MainAxisAlignment.center,
//               //   children: [
//               //     IconButton(
//               //       onPressed: () {},
//               //       icon: const Icon(Icons.bookmark_add_outlined),
//               //       iconSize: thisIconSize,
//               //     ),
//               //     const SizedBox(width: 10),
//               //     IconButton(
//               //       onPressed: () {},
//               //       icon: const Icon(Icons.menu_book_rounded),
//               //       iconSize: thisIconSize,
//               //     ),
//               //   ],
//               // ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               ...slide.blocks.map(
//                 (b) => Center(
//                   child: BlockWidget(
//                     block: b,
//                     animatedTextMode: animatedTextMode,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//       ],
//     );
//   }
// }

// lib/widgets/slide_widget.dart

import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
import 'package:arabic_teacher_demo/models/theme/custom_text_style.dart';
import 'package:arabic_teacher_demo/widgets/animated_text.dart';
import 'package:flutter/material.dart';
import '../models/slide.dart';
import 'block_widget.dart';

class SlideWidget extends StatelessWidget {
  final Slide slide;
  final AnimatedTextMode animatedTextMode;
  final int index;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onStopAudio;
  final VoidCallback? onNextSlide;
  final VoidCallback? onPrevSlide;
  final int currentIndex;
  final int totalSlides;

  const SlideWidget({
    super.key,
    required this.slide,
    required this.animatedTextMode,
    required this.index,
    required this.isPlaying,
    this.onPlayAudio,
    this.onStopAudio,
    this.onNextSlide,
    this.onPrevSlide,
    required this.currentIndex,
    required this.totalSlides,
  });
  static const double thisIconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    // Use Column as parent because the parent of SlideWidget in the page
    // already gives it a bounded height (you used Expanded there).
    return Column(
      children: [
        // top fixed header
        Container(
          height: 100,
          width: double.infinity,
          color: Theme.of(context).extension<CustomColors>()!.lightBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: isPlaying ? onStopAudio : onPlayAudio,
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.volume_up_rounded,
                        size: 40,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          '${slide.title} $index',
                          // slide.title,
                          style:
                              Theme.of(
                                context,
                              ).extension<CustomTextStyle>()!.lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 10),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     IconButton(
                //       onPressed: () {},
                //       icon: const Icon(Icons.bookmark_add_outlined),
                //       iconSize: thisIconSize,
                //     ),
                //     const SizedBox(width: 10),
                //     IconButton(
                //       onPressed: () {},
                //       icon: const Icon(Icons.menu_book_rounded),
                //       iconSize: thisIconSize,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // The flexible area that should distribute blocks evenly.
        // LayoutBuilder gives us the available height; ConstrainedBox with
        // minHeight = constraints.maxHeight forces the inner Column
        // to expand to the available height, so spaceBetween works.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // SingleChildScrollView allows scrolling when blocks exceed height
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // This is the key: make the inner Column at least the height
                    // available to this widget.
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    // Now this Column will take the full available height and
                    // spaceBetween will distribute the children across it.
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:
                        slide.blocks
                            .map(
                              (b) => Center(
                                child: BlockWidget(
                                  block: b,
                                  animatedTextMode: animatedTextMode,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              );
            },
          ),
        ),

        // Navigation buttons at the bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Previous button - takes half the row
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentIndex == 0 ? null : onPrevSlide,
                  icon: const Icon(Icons.arrow_back_ios),
                  label: const Text('السابق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        currentIndex == 0
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color:
                            currentIndex == 0
                                ? Colors.grey.withOpacity(0.3)
                                : Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Next button - takes half the row
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNextSlide,
                  icon: const Icon(Icons.arrow_forward_ios),
                  label: const Text('التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
