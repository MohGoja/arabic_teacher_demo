// lib/widgets/info_carousel_block.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arabic_teacher_demo/models/content_block.dart';

class InfoCarouselBlock extends StatefulWidget {
  final ContentBlock block;

  /// milliseconds between revealing answer segments (adjust as desired)
  final Duration interval;
  const InfoCarouselBlock({
    Key? key,
    required this.block,
    this.interval = const Duration(milliseconds: 900),
  }) : super(key: key);

  @override
  State<InfoCarouselBlock> createState() => _InfoCarouselBlockState();
}

class _InfoCarouselBlockState extends State<InfoCarouselBlock> {
  static const Color primaryColor = Color(0xFF568DA8);

  final PageController _pageController = PageController();
  final GlobalKey _pageViewKey = GlobalKey();
  late final List<Map<String, dynamic>> items;

  // Title template mapping
  Map<String, Map<String, dynamic>> get titleTemplates => {
    "think": {'text': 'فكر', 'icon': Icons.lightbulb, 'color': Colors.amber},
    'war': {
      'text': 'تنبيه',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
    },
    'wars': {
      'text': 'تنبيهات',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
    },
    'info': {
      'text': 'معلومة',
      'icon': Icons.info_outline,
      'color': primaryColor,
    },
    'tip': {
      'text': 'نصيحة',
      'icon': Icons.lightbulb_outline,
      'color': Colors.amber,
    },
    'note': {
      'text': 'ملاحظة',
      'icon': Icons.note_alt_outlined,
      'color': Colors.green,
    },
    'important': {
      'text': 'مهم',
      'icon': Icons.priority_high,
      'color': Colors.red,
    },
    'question': {
      'text': 'سؤال',
      'icon': Icons.quiz_outlined,
      'color': Colors.purple,
    },
    'definition': {
      'text': 'تعريف',
      'icon': Icons.book_outlined,
      'color': Colors.indigo,
    },
    'remember': {
      'text': 'تذكير',
      'icon': Icons.psychology_outlined,
      'color': Colors.teal,
    },
  };

  // Get template data for a given title key
  Map<String, dynamic>? _getTitleTemplate(String? title) {
    if (title == null || title.trim().isEmpty) return null;
    return titleTemplates[title.toLowerCase()];
  }

  int currentPage = 0;
  int revealCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // normalize the data as List<Map>
    final raw = widget.block.data;
    if (raw is List<Map<String, dynamic>>) {
      items = raw;
    } else if (raw is List) {
      items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      items = [];
    }
    _startReveal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Get the segments for the currently visible page
  List<String> get _currentSegments {
    if (items.isEmpty || currentPage >= items.length) return [];
    final raw = (items[currentPage]['answerSegments'] ?? []) as List;
    return raw.map((e) => e.toString()).toList();
  }

  void _startReveal() {
    _timer?.cancel();
    final segments = _currentSegments;
    if (segments.isEmpty) return;

    // Reset reveal count for current page
    revealCount = 0;

    // reveal segments one-by-one automatically
    _timer = Timer.periodic(widget.interval, (t) {
      if (!mounted) return;
      setState(() {
        revealCount++;
        if (revealCount >= segments.length) {
          t.cancel();
        }
      });
    });
  }

  void _onPageChanged(int page) {
    if (page == currentPage) return;
    setState(() {
      currentPage = page;
    });
    _startReveal();
  }

  void _goToPage(int page) {
    if (page == currentPage) return;

    // Force the page controller to the correct page first
    if (_pageController.hasClients) {
      _pageController
          .animateToPage(
            page,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          )
          .then((_) {
            // Force update if needed
            if (currentPage != page) {
              setState(() {
                currentPage = page;
              });
              _startReveal();
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final title = widget.block.style?['title']?.toString();
    // Calculate height once and cache it to prevent rebuilds
    final screenHeight = MediaQuery.of(context).size.height;
    final baseHeight = screenHeight * 0.5;
    final titleHeight = (title != null && title.trim().isNotEmpty) ? 36.0 : 0.0;
    final indicatorHeight = items.length > 1 ? 24.0 : 0.0;
    final carouselHeight = (baseHeight - titleHeight - indicatorHeight).clamp(
      300.0,
      double.infinity,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title.trim().isNotEmpty) ...[
            _buildTitleSection(title),
            const SizedBox(height: 20),
          ],

          // PageView with navigation buttons beside it
          SizedBox(
            height: carouselHeight,
            child: Row(
              children: [
                // Previous button on the right (RTL logic)
                if (items.length > 1 && currentPage > 0)
                  Container(
                    width: 32,
                    child: Center(
                      child: IconButton(
                        onPressed: () => _goToPage(currentPage - 1),
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        color: primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ),
                  )
                else if (items.length > 1)
                  const SizedBox(width: 32), // Maintain spacing
                const SizedBox(width: 5),
                // PageView (expanded to fill remaining space)
                Expanded(
                  child: PageView.builder(
                    key: _pageViewKey,
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: _onPageChanged,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) => _buildPage(index),
                  ),
                ),
                const SizedBox(width: 5),
                // Next button on the left (RTL logic)
                if (items.length > 1 && currentPage < items.length - 1)
                  Container(
                    width: 32,
                    child: Center(
                      child: IconButton(
                        onPressed: () => _goToPage(currentPage + 1),
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        color: primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ),
                  )
                else if (items.length > 1)
                  const SizedBox(width: 32), // Maintain spacing
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dot indicators
          if (items.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == currentPage;
                return GestureDetector(
                  onTap: () => _goToPage(i),
                  child: Container(
                    width: active ? 12 : 8,
                    height: active ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? primaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  /// Builds a single page showing a question and its answer segments.
  Widget _buildPage(int index) {
    final question = (items[index]['question'] ?? '').toString();
    final rawSegs = (items[index]['answerSegments'] ?? []) as List;
    final segments = rawSegs.map((e) => e.toString()).toList();
    final showCount = index == currentPage ? revealCount : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // question pill
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // const SizedBox(width: 12),
                // Text(
                //   'السؤال',
                //   style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // answers expand naturally
          ...List.generate(segments.length, (i) {
            final visible = i < showCount;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              opacity: visible ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                offset: visible ? Offset.zero : const Offset(0, 0.04),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSegmentCard(segments[i]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Single answer segment card with icon
  Widget _buildSegmentCard(String text) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the title section with template support
  Widget _buildTitleSection(String title) {
    final template = _getTitleTemplate(title);

    if (template != null) {
      // Use template with custom text, icon, and color
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: items.length > 1 ? 14 + 24 : 4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (template['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (template['color'] as Color).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                template['text'] as String,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: template['color'] as Color,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                template['icon'] as IconData,
                color: template['color'] as Color,
                size: 24,
              ),
            ],
          ),
        ),
      );
    } else {
      // Fallback to original title display
      return Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
      );
    }
  }
}
