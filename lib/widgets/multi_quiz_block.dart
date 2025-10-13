import 'package:arabic_teacher_demo/models/content_block.dart';
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

class MultiStepQuizBlockWidget extends StatefulWidget {
  final ContentBlock block;
  const MultiStepQuizBlockWidget({super.key, required this.block});

  @override
  State<MultiStepQuizBlockWidget> createState() =>
      _MultiStepQuizBlockWidgetState();
}

class _MultiStepQuizBlockWidgetState extends State<MultiStepQuizBlockWidget> {
  static const Color primaryColor = Color(0xFF568DA8);
  // Dark blue for tiny highlight visibility
  static const Color strongBg = Color.fromARGB(255, 6, 28, 66);

  late final String prompt;
  late final String text;
  late final List<Map<String, dynamic>> highlights;
  late final TextAlign textAlign;

  int current = 0;
  String? selected;
  bool answered = false;
  bool correct = false;

  @override
  void initState() {
    super.initState();
    final data = widget.block.data as Map<String, dynamic>;
    prompt = data['prompt'] ?? '';
    text = data['text'] ?? '';
    highlights = List<Map<String, dynamic>>.from(data['highlights']);
    final align = (data['style']?['text-align'] ?? 'justify') as String;
    textAlign =
        align == 'center'
            ? TextAlign.center
            : align == 'start'
            ? TextAlign.start
            : TextAlign.justify;
  }

  void selectAnswer(String key) {
    if (answered) return;
    final correctKey = highlights[current]['correctAnswer'] as String?;
    setState(() {
      selected = key;
      answered = true;
      correct = correctKey != null && correctKey == key;
    });
  }

  void nextHighlight() {
    if (current < highlights.length - 1) {
      setState(() {
        current++;
        selected = null;
        answered = false;
        correct = false;
      });
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("انتهى التمرين"),
              content: const Text("أكملت جميع الأجزاء من سورة الفاتحة 🎉"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إغلاق"),
                ),
              ],
            ),
      );
    }
  }

  // Arabic-range check (for safe ZWJ insertion)
  bool _isArabic(String g) {
    if (g.isEmpty) return false;
    final ch = g.characters.first;
    return RegExp(r'[\u0600-\u06FF]').hasMatch(ch);
  }

  @override
  Widget build(BuildContext context) {
    final highlight = highlights[current];
    final start = highlight['start'] as int;
    final length = highlight['length'] as int;

    // Grapheme-safe slicing + ZWJ to preserve joining
    final all = text.characters;
    final before = all.take(start).toString();
    final middle = all.skip(start).take(length).toString();
    final after = all.skip(start + length).toString();

    const zwj = '\u200D';
    final beforeChars = before.characters;
    final middleChars = middle.characters;
    final afterChars = after.characters;

    final joinLeft =
        beforeChars.isNotEmpty &&
        middleChars.isNotEmpty &&
        _isArabic(beforeChars.last) &&
        _isArabic(middleChars.first);

    final joinRight =
        middleChars.isNotEmpty &&
        afterChars.isNotEmpty &&
        _isArabic(middleChars.last) &&
        _isArabic(afterChars.first);

    final middleJoined =
        (joinLeft ? zwj : '') + middle + (joinRight ? zwj : '');

    // Strong, visible style for very short highlights (e.g., single letter)
    final bool isTiny = length <= 2;
    final TextStyle tinyStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      backgroundColor: strongBg, // dark blue block behind the letter(s)
    );

    final TextStyle normalHighlightStyle = TextStyle(
      color: primaryColor,
      fontWeight: FontWeight.bold,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prompt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  prompt,
                  textAlign: textAlign,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.8,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: before),
                    TextSpan(
                      text: middleJoined,
                      style: isTiny ? tinyStyle : normalHighlightStyle,
                    ),
                    TextSpan(text: after),
                  ],
                ),
                textAlign: TextAlign.center, // unchanged
                textDirection: TextDirection.rtl,
                softWrap: true,
              ),
            ),

            const SizedBox(height: 20),

            // options (unchanged)
            Column(
              children:
                  List<Map<String, dynamic>>.from(highlight['options']).map((
                    opt,
                  ) {
                    final key = opt['key'] as String;
                    final label = opt['label'] as String;
                    final isSelected = selected == key;
                    final isCorrect =
                        answered && highlight['correctAnswer'] == key;
                    final isWrong = answered && isSelected && !isCorrect;

                    Color bg;
                    Color fg = Colors.black;
                    if (isCorrect) {
                      bg = Colors.green.shade600;
                      fg = Colors.white;
                    } else if (isWrong) {
                      bg = Colors.red.shade600;
                      fg = Colors.white;
                    } else if (isSelected) {
                      bg = primaryColor;
                      fg = Colors.white;
                    } else {
                      bg = Colors.white;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bg,
                          foregroundColor: fg,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        onPressed: answered ? null : () => selectAnswer(key),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 12),

            if (answered)
              Column(
                children: [
                  Text(
                    correct ? "✔ أحسنت!" : "✘ خطأ، حاول مرة أخرى",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: correct ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: nextHighlight,
                    child: const Text("متابعة"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
