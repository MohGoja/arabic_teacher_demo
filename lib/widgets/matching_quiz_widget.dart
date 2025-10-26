import 'package:arabic_teacher_demo/models/content_block.dart';
import 'package:flutter/material.dart';

class MatchingQuizData {
  final String prompt;
  final List<String> leftColumn;
  final List<String> rightColumn;
  final Map<int, int> correctMatches; // index in left -> index in right

  MatchingQuizData({
    required this.prompt,
    required this.leftColumn,
    required this.rightColumn,
    required this.correctMatches,
  });

  factory MatchingQuizData.fromMap(Map<String, dynamic> map) {
    return MatchingQuizData(
      prompt: map['prompt'] ?? '',
      leftColumn: List<String>.from(map['leftColumn'] ?? []),
      rightColumn: List<String>.from(map['rightColumn'] ?? []),
      correctMatches: Map<int, int>.from(
        (map['correctMatches'] as Map?)?.map(
              (k, v) =>
                  MapEntry(int.parse(k.toString()), int.parse(v.toString())),
            ) ??
            {},
      ),
    );
  }
}

class MatchingQuizWidget extends StatefulWidget {
  final ContentBlock block;

  const MatchingQuizWidget({super.key, required this.block});

  @override
  State<MatchingQuizWidget> createState() => _MatchingQuizWidgetState();
}

class _MatchingQuizWidgetState extends State<MatchingQuizWidget>
    with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF568DA8);
  static const Color correctColor = Color(0xFF10B981);
  static const Color incorrectColor = Color(0xFFEF4444);

  late final MatchingQuizData quizData;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Map<int, int?> userMatches = {}; // left index -> right index
  Map<int, bool> matchStatus = {}; // left index -> isCorrect
  int? selectedLeft;
  int? selectedRight;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Parse the data - it's already parsed as MatchingQuizData in ContentBlock.fromJson()
    if (widget.block.data is MatchingQuizData) {
      quizData = widget.block.data as MatchingQuizData;
    } else {
      // Fallback in case it's still a Map (shouldn't happen with current setup)
      final data = widget.block.data as Map<String, dynamic>;
      quizData = MatchingQuizData.fromMap(data);
    }

    // Initialize shake animation for wrong answers
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _selectLeft(int index) {
    if (isCompleted || matchStatus.containsKey(index)) return;

    setState(() {
      selectedLeft = selectedLeft == index ? null : index;
      selectedRight = null;
    });
  }

  void _selectRight(int index) {
    if (isCompleted || userMatches.values.contains(index)) return;

    setState(() {
      selectedRight = selectedRight == index ? null : index;
    });

    // If both left and right are selected, make the match
    if (selectedLeft != null && selectedRight != null) {
      _makeMatch(selectedLeft!, selectedRight!);
    }
  }

  void _makeMatch(int leftIndex, int rightIndex) {
    final isCorrect = quizData.correctMatches[leftIndex] == rightIndex;

    setState(() {
      if (isCorrect) {
        userMatches[leftIndex] = rightIndex;
        matchStatus[leftIndex] = true;
        selectedLeft = null;
        selectedRight = null;

        // Check if quiz is completed
        if (userMatches.length == quizData.leftColumn.length) {
          isCompleted = true;
          _showCompletionDialog();
        }
      } else {
        matchStatus[leftIndex] = false;
        // Shake animation for wrong answer
        _shakeController.forward().then((_) {
          _shakeController.reverse();
          setState(() {
            matchStatus.remove(leftIndex);
            selectedLeft = null;
            selectedRight = null;
          });
        });
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.celebration, color: correctColor, size: 28),
                SizedBox(width: 8),
                Text('أحسنت!'),
              ],
            ),
            content: const Text(
              'لقد أكملت التمرين بنجاح!\nجميع الإجابات صحيحة.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('متابعة'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetQuiz();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
    );
  }

  void _resetQuiz() {
    setState(() {
      userMatches.clear();
      matchStatus.clear();
      selectedLeft = null;
      selectedRight = null;
      isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quiz prompt
            if (quizData.prompt.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  quizData.prompt,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Progress indicator
            if (userMatches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: userMatches.length / quizData.leftColumn.length,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          correctColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${userMatches.length}/${quizData.leftColumn.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Matching columns
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children:
                            quizData.leftColumn.asMap().entries.map((entry) {
                              final index = entry.key;
                              final text = entry.value;
                              final isMatched = userMatches.containsKey(index);
                              final isSelected = selectedLeft == index;
                              final hasError = matchStatus[index] == false;

                              return AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset:
                                        hasError
                                            ? Offset(
                                              _shakeAnimation.value *
                                                  (index % 2 == 0 ? 1 : -1),
                                              0,
                                            )
                                            : Offset.zero,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Material(
                                        elevation:
                                            isSelected
                                                ? 6
                                                : (isMatched ? 3 : 2),
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap: () => _selectLeft(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color:
                                                  isMatched
                                                      ? correctColor
                                                          .withOpacity(0.1)
                                                      : isSelected
                                                      ? primaryColor
                                                          .withOpacity(0.2)
                                                      : hasError
                                                      ? incorrectColor
                                                          .withOpacity(0.1)
                                                      : Colors.white,
                                              border: Border.all(
                                                color:
                                                    isMatched
                                                        ? correctColor
                                                        : isSelected
                                                        ? primaryColor
                                                        : hasError
                                                        ? incorrectColor
                                                        : Colors.grey.shade300,
                                                width:
                                                    isSelected || isMatched
                                                        ? 2
                                                        : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    text,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          isMatched ||
                                                                  isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                      color:
                                                          isMatched
                                                              ? correctColor
                                                              : hasError
                                                              ? incorrectColor
                                                              : Colors.black87,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                if (isMatched)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: correctColor,
                                                    size: 20,
                                                  )
                                                else if (isSelected)
                                                  Icon(
                                                    Icons.radio_button_checked,
                                                    color: primaryColor,
                                                    size: 20,
                                                  )
                                                else if (hasError)
                                                  const Icon(
                                                    Icons.cancel,
                                                    color: incorrectColor,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      ),
                    ),

                    // Connection lines area
                    Container(
                      width: 40,
                      child: Column(
                        children:
                            quizData.leftColumn.asMap().entries.map((entry) {
                              final leftIndex = entry.key;
                              final rightIndex = userMatches[leftIndex];

                              if (rightIndex != null) {
                                return Container(
                                  height: 68, // Match the item height + margin
                                  child: CustomPaint(
                                    painter: ConnectionLinePainter(
                                      leftIndex: leftIndex,
                                      rightIndex: rightIndex,
                                      totalLeft: quizData.leftColumn.length,
                                      totalRight: quizData.rightColumn.length,
                                      color: correctColor,
                                    ),
                                  ),
                                );
                              }
                              return Container(height: 68);
                            }).toList(),
                      ),
                    ),

                    // Right column
                    Expanded(
                      child: Column(
                        children:
                            quizData.rightColumn.asMap().entries.map((entry) {
                              final index = entry.key;
                              final text = entry.value;
                              final isMatched = userMatches.values.contains(
                                index,
                              );
                              final isSelected = selectedRight == index;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  elevation:
                                      isSelected ? 6 : (isMatched ? 3 : 2),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectRight(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color:
                                            isMatched
                                                ? correctColor.withOpacity(0.1)
                                                : isSelected
                                                ? primaryColor.withOpacity(0.2)
                                                : Colors.white,
                                        border: Border.all(
                                          color:
                                              isMatched
                                                  ? correctColor
                                                  : isSelected
                                                  ? primaryColor
                                                  : Colors.grey.shade300,
                                          width:
                                              isSelected || isMatched ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          if (isMatched)
                                            const Icon(
                                              Icons.check_circle,
                                              color: correctColor,
                                              size: 20,
                                            )
                                          else if (isSelected)
                                            Icon(
                                              Icons.radio_button_checked,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                          if (isMatched || isSelected)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    isMatched || isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                color:
                                                    isMatched
                                                        ? correctColor
                                                        : Colors.black87,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Reset button
            if (userMatches.isNotEmpty && !isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _resetQuiz,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConnectionLinePainter extends CustomPainter {
  final int leftIndex;
  final int rightIndex;
  final int totalLeft;
  final int totalRight;
  final Color color;

  ConnectionLinePainter({
    required this.leftIndex,
    required this.rightIndex,
    required this.totalLeft,
    required this.totalRight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Calculate positions
    final leftY = size.height * 0.5;
    final rightY = size.height * 0.5;

    // Draw curved connection line
    final path = Path();
    path.moveTo(0, leftY);
    path.cubicTo(
      size.width * 0.3,
      leftY,
      size.width * 0.7,
      rightY,
      size.width,
      rightY,
    );

    canvas.drawPath(path, paint);

    // Draw small circles at endpoints
    final circlePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, leftY), 3, circlePaint);
    canvas.drawCircle(Offset(size.width, rightY), 3, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
