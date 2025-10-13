// lib/widgets/quiz_block.dart
import 'package:arabic_teacher_demo/models/content_block.dart';
import 'package:flutter/material.dart';
// <-- UPDATE this to your ContentBlock file path:

class QuizBlockWidget extends StatefulWidget {
  final ContentBlock block;
  const QuizBlockWidget({Key? key, required this.block}) : super(key: key);

  @override
  State<QuizBlockWidget> createState() => _QuizBlockWidgetState();
}

class _QuizBlockWidgetState extends State<QuizBlockWidget>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF568DA8);

  late final List<Map<String, dynamic>> items;
  int index = 0;

  String? selectedKey;
  bool answered = false;
  bool correct = false;

  String?
  quizPrompt; // <-- persistent title (e.g. "ميز الأفعال في الجمل التالية")

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    final raw = widget.block.data;
    if (raw is List<Map<String, dynamic>>) {
      items = raw;
    } else if (raw is List) {
      items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      items = [];
    }

    // If first item is an instruction (no options), use it as the persistent prompt/title.
    if (items.isNotEmpty) {
      final first = items.first;
      final firstOpts = (first['options'] as List?) ?? [];
      if (firstOpts.isEmpty) {
        final maybeText = (first['data'] ?? '') as String;
        if (maybeText.trim().isNotEmpty) {
          quizPrompt = maybeText.trim();
        }
      }
    }

    // find first item that actually has options (a real question)
    final firstQ = items.indexWhere((it) {
      final opts = it['options'];
      return opts is List && opts.isNotEmpty;
    });

    if (firstQ >= 0) {
      index = firstQ;
    } else {
      // no questions — start at 0 (will show whatever exists)
      index = 0;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // If current item has no options, schedule a skip to the next question (if any)
  void _maybeSkipNonQuestion() {
    if (items.isEmpty) return;
    final opts = (items[index]['options'] as List?) ?? [];
    if (opts.isEmpty) {
      final next = items.indexWhere((it) {
        final o = it['options'];
        return o is List && o.isNotEmpty;
      }, index + 1);
      if (next != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              index = next;
              selectedKey = null;
              answered = false;
              correct = false;
            });
          }
        });
      } else {
        // no question ahead — try find any question in the block (already handled on init)
        final any = items.indexWhere((it) {
          final o = it['options'];
          return o is List && o.isNotEmpty;
        });
        if (any != -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                index = any;
                selectedKey = null;
                answered = false;
                correct = false;
              });
            }
          });
        }
      }
    }
  }

  void _onSelectOption(String key, String? correctKey) {
    if (answered) return;
    setState(() {
      selectedKey = key;
      answered = true;
      correct = correctKey != null && correctKey == key;
    });
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  void _continue() {
    final next = items.indexWhere((it) {
      final o = it['options'];
      return o is List && o.isNotEmpty;
    }, index + 1);

    if (next != -1) {
      setState(() {
        index = next;
        selectedKey = null;
        answered = false;
        correct = false;
      });
    } else {
      // finished: dialog then restart to first question (if any)
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('انتهى الاختبار'),
              content: const Text(
                'أكملت جميع العناصر. هل تريد إعادة المحاولة؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final firstQ = items.indexWhere((it) {
                      final o = it['options'];
                      return o is List && o.isNotEmpty;
                    });
                    setState(() {
                      if (firstQ >= 0) {
                        index = firstQ;
                      } else {
                        index = 0;
                      }
                      selectedKey = null;
                      answered = false;
                      correct = false;
                    });
                  },
                  child: const Text('إعادة'),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildHighlightedSentence({
    required String sentence,
    String? highlightedWord,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    if (highlightedWord == null || highlightedWord.trim().isEmpty) {
      return Text(sentence, style: normalStyle, textAlign: TextAlign.right);
    }
    final found = sentence.indexOf(highlightedWord);
    if (found == -1) {
      return Text(sentence, style: normalStyle, textAlign: TextAlign.right);
    }
    final before = sentence.substring(0, found);
    final match = sentence.substring(found, found + highlightedWord.length);
    final after = sentence.substring(found + highlightedWord.length);

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        children: [
          TextSpan(text: before, style: normalStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(match, style: highlightStyle),
            ),
          ),
          TextSpan(text: after, style: normalStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // ensure we skip any non-question slides automatically
    _maybeSkipNonQuestion();

    final item = items[index];
    final sentence = (item['data'] ?? '') as String;
    final highlighted = (item['highlightedWord'] as String?)?.trim();
    final optionsRaw = (item['options'] as List?) ?? [];
    final options =
        optionsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final correctKey = (item['correctAnswer'] as String?);
    final feedbackCorrect = (item['feedbackCorrect'] as String?) ?? 'صحيح!';
    final feedbackWrong =
        (item['feedbackWrong'] as String?) ?? 'خطأ — حاول مرة أخرى';

    final theme = Theme.of(context);
    final normalStyle =
        theme.textTheme.bodyLarge?.copyWith(fontSize: 20) ??
        const TextStyle(fontSize: 20);
    final highlightStyle = normalStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );

    // choose persistent title: block.style.title -> quizPrompt -> null
    final persistentTitle =
        (widget.block.style != null && widget.block.style!['title'] != null)
            ? (widget.block.style!['title'] as String)
            : quizPrompt;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isNarrow = maxW < 520;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              (index + 1) /
                              (items.isNotEmpty
                                  ? items.length.toDouble()
                                  : 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$index/${items.length - 1}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (persistentTitle != null &&
                      persistentTitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        persistentTitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),

                  // sentence card with persistent title shown at top
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHighlightedSentence(
                            sentence: sentence,
                            highlightedWord: highlighted,
                            normalStyle: normalStyle,
                            highlightStyle: highlightStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // options (should be present, since we auto-skip if not)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children:
                        options.map((opt) {
                          final key = opt['key'] as String;
                          final label = opt['label'] as String;
                          final isSelected = selectedKey == key;
                          final showCorrect = answered && correctKey == key;
                          final showWrong =
                              answered && isSelected && correctKey != key;

                          Color bg;
                          Color fg = Colors.white;
                          double elevation = 2;
                          if (showCorrect) {
                            bg = Colors.green.shade600;
                            elevation = 6;
                          } else if (showWrong) {
                            bg = Colors.red.shade600;
                            elevation = 6;
                          } else if (isSelected) {
                            bg = primaryColor;
                            elevation = 6;
                          } else {
                            bg = Colors.white;
                            fg = Colors.black87;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width:
                                isNarrow ? double.infinity : (maxW - 48) / 2.6,
                            child: Material(
                              elevation: elevation,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap:
                                    answered
                                        ? null
                                        : () =>
                                            _onSelectOption(key, correctKey),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          (isSelected || showCorrect)
                                              ? Colors.transparent
                                              : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: fg,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (showCorrect)
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                        )
                                      else if (showWrong)
                                        const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.white,
                                        )
                                      else if (isSelected)
                                        Icon(
                                          Icons.radio_button_checked,
                                          color: fg,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // feedback + continue (only after answer)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    child:
                        answered
                            ? ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _pulseController,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: Container(
                                key: ValueKey('feedback-$index-$selectedKey'),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            correct
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        correct
                                            ? Icons.thumb_up_alt_outlined
                                            : Icons.thumb_down_outlined,
                                        color:
                                            correct
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            correct
                                                ? feedbackCorrect
                                                : feedbackWrong,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  correct
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (!correct && correctKey != null)
                                            Text(
                                              'الإجابة الصحيحة: ' +
                                                  (options.firstWhere(
                                                        (o) =>
                                                            o['key'] ==
                                                            correctKey,
                                                      )['label']
                                                      as String),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 14,
                                        ),
                                      ),
                                      onPressed: _continue,
                                      child: const Text('متابعة'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
