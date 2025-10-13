// lib/widgets/animated_block_text.dart
// Updated: scramble shows nothing until each char starts scrambling; wave/slide hide words until reveal and preserve spaces.
// Place this file at: lib/widgets/animated_block_text.dart

import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum AnimatedTextMode {
  none,
  typewriter,
  // wave,
  scramble,
  slide,
  boom, // per-word particle "boom"
}

class AnimatedBlockText extends StatefulWidget {
  final dynamic blockData; // String or List (segments)
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final AnimatedTextMode mode;
  final Duration typeCharDelay;
  final Duration
  staggerDuration; // used by word-level staggers (wave/slide/boom)
  final Duration scrambleInterval; // internal ticks during scramble
  final Duration scrambleDuration; // how long a single-char scramble lasts
  final bool showCursor;

  const AnimatedBlockText({
    Key? key,
    required this.blockData,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.mode = AnimatedTextMode.typewriter,
    this.typeCharDelay = const Duration(milliseconds: 30),
    this.staggerDuration = const Duration(milliseconds: 700),
    this.scrambleInterval = const Duration(milliseconds: 40),
    this.scrambleDuration = const Duration(milliseconds: 220),
    this.showCursor = false,
  }) : super(key: key);

  @override
  State<AnimatedBlockText> createState() => _AnimatedBlockTextState();
}

class _AnimatedBlockTextState extends State<AnimatedBlockText>
    with TickerProviderStateMixin {
  // Content
  String _fullText = '';
  List<Map<String, dynamic>> _segments = [];
  final List<TapGestureRecognizer?> _recognizers = [];

  // grapheme aware
  List<String> _graphemes = [];
  int _visibleGraphemes =
      0; // how many have been *scheduled* to reveal (scramble stage starts)

  // timers
  Timer? _typeTimer;

  // scramble machinery
  Timer?
  _scrambleTicker; // updates random glyphs for currently scrambling indices
  final Set<int> _scrambling = {}; // indices currently in scramble animation
  final List<String> _scrambleBuffer =
      []; // current display for scramble indices
  final List<Timer> _scrambleEndTimers = [];

  // controller for word-level stagger animations (wave/slide/boom)
  AnimationController? _wordController;

  final Random _rand = Random();

  // Arabic detection
  final RegExp _arabicRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  bool get _isArabic => _arabicRegex.hasMatch(_fullText);

  // Boom threshold reused for wave/slide reveal decisions (token hidden until threshold)
  static const double _wordShowThreshold = 0.45;

  @override
  void initState() {
    super.initState();
    _initFromBlock();
    _setupControllers();
    _startAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AnimatedBlockText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final modeChanged =
        widget.mode != oldWidget.mode ||
        widget.typeCharDelay != oldWidget.typeCharDelay ||
        widget.staggerDuration != oldWidget.staggerDuration;

    if (widget.blockData != oldWidget.blockData || modeChanged) {
      _resetAll();
      _initFromBlock();
      _setupControllers();
      _startAnimationIfNeeded();
    }
  }

  void _initFromBlock() {
    for (final r in _recognizers) {
      r?.dispose();
    }
    _recognizers.clear();
    _segments.clear();
    _fullText = '';

    if (widget.blockData is List) {
      final raw = widget.blockData as List;
      for (final seg in raw) {
        final text = (seg['text'] ?? '').toString();
        final note = seg.containsKey('note') ? seg['note'] : null;
        _segments.add({'text': text, 'note': note});
        _fullText += text;
        if (note != null) {
          final recognizer =
              TapGestureRecognizer()
                ..onTap = () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(content: Text(note.toString())),
                    );
                  });
                };
          _recognizers.add(recognizer);
        } else {
          _recognizers.add(null);
        }
      }
    } else if (widget.blockData is String) {
      _fullText = widget.blockData as String;
    } else {
      _fullText = '';
    }

    _graphemes = _fullText.characters.toList();
    _visibleGraphemes = 0;
    _scrambling.clear();
    _scrambleBuffer.clear();
    _scrambleBuffer.addAll(List<String>.filled(_graphemes.length, ''));
  }

  void _setupControllers() {
    _wordController?.dispose();
    _wordController = null;

    // if (widget.mode == AnimatedTextMode.wave ||
    if (widget.mode == AnimatedTextMode.slide ||
        widget.mode == AnimatedTextMode.boom) {
      final tokens = _wordTokens(_fullText).length;
      final base = widget.staggerDuration.inMilliseconds;
      final durationMs = max(500, base + (tokens * 60));
      _wordController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durationMs),
      )..addListener(() => setState(() {}));
    }
  }

  void _resetAll() {
    _typeTimer?.cancel();
    _scrambleTicker?.cancel();
    for (final t in _scrambleEndTimers) t.cancel();
    _scrambleEndTimers.clear();
    _scrambling.clear();
    _wordController?.stop();
    for (final r in _recognizers) r?.dispose();
    _recognizers.clear();
    _visibleGraphemes = 0;
    for (int i = 0; i < _scrambleBuffer.length; i++) _scrambleBuffer[i] = '';
  }

  void _startAnimationIfNeeded() {
    if (_fullText.isEmpty) return;

    switch (widget.mode) {
      case AnimatedTextMode.none:
        setState(() => _visibleGraphemes = _graphemes.length);
        break;

      case AnimatedTextMode.typewriter:
        _startTypewriter();
        break;

      case AnimatedTextMode.scramble:
        _startScramble();
        break;

      // case AnimatedTextMode.wave:
      case AnimatedTextMode.slide:
      case AnimatedTextMode.boom:
        _wordController?.reset();
        _wordController?.forward();
        break;
    }
  }

  // ---------- typewriter ----------
  void _startTypewriter() {
    _typeTimer?.cancel();
    _visibleGraphemes = 0;
    _typeTimer = Timer.periodic(widget.typeCharDelay, (t) {
      setState(() {
        _visibleGraphemes++;
        if (_visibleGraphemes >= _graphemes.length) {
          _visibleGraphemes = _graphemes.length;
          _typeTimer?.cancel();
        }
      });
    });
  }

  // ---------- scramble (reworked) ----------
  // Behavior:
  // - Unrevealed indices show nothing.
  // - Each index i: when it becomes visible (via _typeTimer increments), we start a short scramble
  //   period where _scrambleBuffer[i] shows random glyphs; after scrambleDuration we set buffer[i] = real grapheme.
  // - A single _scrambleTicker updates random glyphs for all indices currently scrambling.
  void _startScramble() {
    _typeTimer?.cancel();
    _scrambleTicker?.cancel();
    for (final t in _scrambleEndTimers) t.cancel();
    _scrambleEndTimers.clear();
    _scrambling.clear();
    for (int i = 0; i < _scrambleBuffer.length; i++) _scrambleBuffer[i] = '';

    _visibleGraphemes = 0;

    // ticker that updates scramble glyphs for currently scrambling indices
    _scrambleTicker = Timer.periodic(widget.scrambleInterval, (_) {
      if (_scrambling.isEmpty) return;
      setState(() {
        for (final idx in _scrambling) {
          _scrambleBuffer[idx] =
              _isArabic ? _randomArabicLike() : _randomLatinLike();
        }
      });
    });

    // reveal schedule: each tick schedules scramble for the next grapheme
    _typeTimer = Timer.periodic(widget.typeCharDelay, (t) {
      final idx = _visibleGraphemes;
      if (idx >= _graphemes.length) {
        _typeTimer?.cancel();
        // allow remaining scrambles to finish
        return;
      }

      // start scramble for idx
      _scrambling.add(idx);
      // set an immediate random char so UI shows scramble quickly
      _scrambleBuffer[idx] =
          _isArabic ? _randomArabicLike() : _randomLatinLike();

      // schedule the end of scramble for this idx
      final endTimer = Timer(widget.scrambleDuration, () {
        _scrambling.remove(idx);
        _scrambleBuffer[idx] = _graphemes[idx]; // final correct glyph
        setState(() {});
      });
      _scrambleEndTimers.add(endTimer);

      setState(() {
        _visibleGraphemes++;
      });

      if (_visibleGraphemes >= _graphemes.length) {
        _typeTimer?.cancel();
      }
    });
  }

  void _stopTimers() {
    _typeTimer?.cancel();
    _scrambleTicker?.cancel();
    for (final t in _scrambleEndTimers) t.cancel();
    _scrambleEndTimers.clear();
    _scrambling.clear();
  }

  String _randomLatinLike() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%&*~!?';
    return chars[_rand.nextInt(chars.length)];
  }

  String _randomArabicLike() {
    const arab = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';
    if (_rand.nextDouble() < 0.25) return '\u0640'; // tatweel
    return arab[_rand.nextInt(arab.length)];
  }

  @override
  void dispose() {
    _stopTimers();
    for (final r in _recognizers) {
      r?.dispose();
    }
    _wordController?.dispose();
    super.dispose();
  }

  // tokenization helper (keeps spaces/punctuation as separate tokens)
  List<String> _wordTokens(String s) {
    final tokens = <String>[];
    final wordReg = RegExp(r'\s+|[^\s]+');
    for (final m in wordReg.allMatches(s)) {
      tokens.add(m.group(0) ?? '');
    }
    return tokens;
  }

  // compute token start indices (in graphemes) and lengths
  List<int> _tokenStartIndices = [];
  List<int> _tokenLengths = [];
  void _computeTokenIndices() {
    final tokens = _wordTokens(_fullText);
    _tokenStartIndices = [];
    _tokenLengths = [];
    int acc = 0;
    for (final t in tokens) {
      _tokenStartIndices.add(acc);
      final len = t.characters.length;
      _tokenLengths.add(len);
      acc += len;
    }
  }

  // token progress values for controller-driven modes (0..1)
  List<double> _computeTokenProgresses() {
    final tokens = _wordTokens(_fullText);
    if (_wordController == null) {
      return List<double>.filled(tokens.length, 1.0);
    }
    final total = _wordController!.value;
    final n = tokens.length;
    final progresses = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final start = (i / n) * 0.9;
      final end = ((i + 1) / n);
      double p = 0.0;
      if (total <= start)
        p = 0.0;
      else if (total >= end)
        p = 1.0;
      else
        p = (total - start) / (end - start);
      progresses[i] = p.clamp(0.0, 1.0);
    }
    return progresses;
  }

  // substring by grapheme clusters
  String _substringByGraphemes(int n) {
    if (n <= 0) return '';
    if (n >= _graphemes.length) return _graphemes.join();
    return _graphemes.take(n).join();
  }

  // measure text size for a token so we can reserve space while hidden
  Size _measureTextSize(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    return tp.size;
  }

  // Build plain text
  Widget _buildPlain(BuildContext context, TextStyle style) {
    final align = widget.textAlign;

    if (widget.mode == AnimatedTextMode.typewriter) {
      final visible = _substringByGraphemes(_visibleGraphemes);
      final remaining = _substringByGraphemes(
        _graphemes.length,
      ).substring(visible.length);
      final showCursor =
          widget.showCursor && _visibleGraphemes < _graphemes.length;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          showCursor ? '$visible|' : '$visible$remaining',
          style: style,
          textAlign: align,
        ),
      );
    } else if (widget.mode == AnimatedTextMode.scramble) {
      // show: indices not yet started => nothing; indices in _scrambling => scrambleBuffer[idx]; indices finished => grapheme
      final sb = StringBuffer();
      for (int i = 0; i < _graphemes.length; i++) {
        if (_scrambling.contains(i)) {
          sb.write(_scrambleBuffer[i]);
        } else if (i < _visibleGraphemes) {
          // finished scramble for this index
          if (_scrambleBuffer[i].isEmpty) {
            // If some race condition left it empty, fallback to the real grapheme
            sb.write(_graphemes[i]);
          } else {
            sb.write(_scrambleBuffer[i]);
          }
        } else {
          // not yet started: show nothing (i.e., skip)
        }
      }
      final display = sb.toString();
      final showCursor =
          widget.showCursor && _visibleGraphemes < _graphemes.length;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          showCursor ? '$display|' : display,
          style: style,
          textAlign: align,
        ),
      );
      // } else if (widget.mode == AnimatedTextMode.wave ||
    } else if (widget.mode == AnimatedTextMode.slide ||
        widget.mode == AnimatedTextMode.boom) {
      // Word-level animations (safe for Arabic shaping).
      final tokens = _wordTokens(_fullText);
      _computeTokenIndices();
      final progresses = _computeTokenProgresses();
      final children = <Widget>[];

      for (int i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        final p = progresses[i];

        // spaces should always render to preserve layout
        final isSpace = token.trim().isEmpty;
        if (isSpace) {
          children.add(Text(token, style: style)); // keep spaces visible always
          continue;
        }

        // If token is not yet reached the reveal threshold we hide it but reserve space
        if (p < _wordShowThreshold) {
          final sz = _measureTextSize(token, style);
          children.add(SizedBox(width: sz.width, height: sz.height));
          continue;
        }

        // otherwise animate its appearance (pop/slide/boom)
        final norm = ((p - _wordShowThreshold) / (1 - _wordShowThreshold))
            .clamp(0.0, 1.0);
        Widget tokenWidget;
        // if (widget.mode == AnimatedTextMode.wave) {
        //   final translateY = (1 - Curves.elasticOut.transform(norm)) * 10;
        //   final scale = 0.75 + Curves.easeOut.transform(norm) * 0.45;
        //   final opacity = Curves.easeIn.transform(norm);
        //   tokenWidget = Opacity(
        //     opacity: opacity,
        //     child: Transform.translate(
        //       offset: Offset(0, translateY),
        //       child: Transform.scale(
        //         scale: scale,
        //         child: Text(token, style: style),
        //       ),
        //     ),
        //   );
        // } else if (widget.mode == AnimatedTextMode.slide) {
        if (widget.mode == AnimatedTextMode.slide) {
          final tx = (1 - Curves.easeOut.transform(norm)) * -18;
          final opacity = Curves.easeIn.transform(norm);
          tokenWidget = Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(tx, 0),
              child: Text(token, style: style),
            ),
          );
        } else {
          // boom: draw particles and fade-in the word (we reuse p as progress)
          final showP = p;
          double textOpacity = 0.0;
          if (showP >= _wordShowThreshold) {
            final tnorm =
                (showP - _wordShowThreshold) / (1 - _wordShowThreshold);
            textOpacity = Curves.easeIn.transform(tnorm.clamp(0.0, 1.0));
          } else {
            textOpacity = 0.0;
          }
          tokenWidget = SizedBox(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TokenBoomPainter(
                      progress: showP,
                      seed: i,
                      color: style.color ?? Colors.black,
                    ),
                  ),
                ),
                Opacity(opacity: textOpacity, child: Text(token, style: style)),
              ],
            ),
          );
        }

        children.add(tokenWidget);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          textDirection: _isArabic ? TextDirection.rtl : null,
          children: children,
        ),
      );
    } else {
      // none
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(_fullText, style: style, textAlign: align),
      );
    }
  }

  // Build segments (List)
  Widget _buildSegments(BuildContext context, TextStyle style) {
    _computeTokenIndices();
    final progresses = _computeTokenProgresses();
    final tokens = _wordTokens(_fullText);

    // compute segments' grapheme start indices
    final segStartIndices = <int>[];
    int acc = 0;
    for (final seg in _segments) {
      segStartIndices.add(acc);
      acc += seg['text'].toString().characters.length;
    }

    final spans = <TextSpan>[];

    if (widget.mode == AnimatedTextMode.boom) {
      // boom: show token parts only if token progress >= threshold, keep spaces
      for (int si = 0; si < _segments.length; si++) {
        final seg = _segments[si];
        final segText = seg['text'] as String;
        final segLen = segText.characters.length;
        final segStart = segStartIndices[si];
        final segEnd = segStart + segLen;

        for (int ti = 0; ti < tokens.length; ti++) {
          final tStart = _tokenStartIndices[ti];
          final tLen = _tokenLengths[ti];
          final tEnd = tStart + tLen;
          if (tEnd <= segStart || tStart >= segEnd) continue;

          final tokenStr = tokens[ti];
          final tokenIsSpace = tokenStr.trim().isEmpty;

          if (tokenIsSpace) {
            // keep spaces - include them directly
            spans.add(TextSpan(text: tokenStr, style: style));
            continue;
          }

          if (progresses[ti] >= _wordShowThreshold) {
            final tokenGraphemes = tokens[ti].characters.toList();
            // compute portion inside this segment
            final insideStart = max(segStart, tStart);
            final insideEnd = min(segEnd, tEnd);
            final offsetInToken = insideStart - tStart;
            final lengthInToken = insideEnd - insideStart;
            final part =
                tokenGraphemes.skip(offsetInToken).take(lengthInToken).join();
            spans.add(TextSpan(text: part, style: style));
          } else {
            // hidden token => keep spaces only; otherwise add nothing (preserves layout due to space tokens)
          }
        }

        // attach recognizer if entire segment visible (all tokens overlapping seg have progressed)
        bool segFullyVisible = true;
        for (int ti = 0; ti < tokens.length; ti++) {
          final tStart = _tokenStartIndices[ti];
          final tLen = _tokenLengths[ti];
          final tEnd = tStart + tLen;
          if (tEnd <= segStart || tStart >= segEnd) continue;
          if (progresses[ti] < _wordShowThreshold) {
            segFullyVisible = false;
            break;
          }
        }
        if (seg['note'] != null && segFullyVisible) {
          // attach recognizer to last span of this segment (practical compromise)
          if (spans.isNotEmpty) {
            final last = spans.removeLast();
            spans.add(
              TextSpan(
                text: last.text,
                style: last.style,
                recognizer: _recognizers[si],
              ),
            );
          }
        }
      }
    } else {
      // non-boom modes (wave/slide/scramble/typewriter): either char-level reveal or scramble special-case
      if (widget.mode == AnimatedTextMode.scramble) {
        // Build by grapheme index: only include characters that have been scheduled/revealed or currently scrambling
        int len = _graphemes.length;
        // int included = 0;
        for (int i = 0; i < len; i++) {
          if (_scrambling.contains(i)) {
            // find which segment token this index belongs to, add to spans accordingly
            spans.add(TextSpan(text: _scrambleBuffer[i], style: style));
            // included++;
          } else if (i < _visibleGraphemes) {
            // finished scramble for this index
            spans.add(
              TextSpan(
                text:
                    _scrambleBuffer[i].isEmpty
                        ? _graphemes[i]
                        : _scrambleBuffer[i],
                style: style,
              ),
            );
            // included++;
          } else {
            // not started: show nothing (skip)
          }
        }
      } else {
        // typewriter/wave/slide (character or token progress)
        int visible = _visibleGraphemes;
        // if (widget.mode == AnimatedTextMode.wave ||
        if (widget.mode == AnimatedTextMode.slide) {
          final c = _wordController;
          if (c != null) {
            visible = (c.value * _graphemes.length).floor().clamp(
              0,
              _graphemes.length,
            );
          } else {
            visible = _graphemes.length;
          }
        }

        int accumulated = 0;
        for (int i = 0; i < _segments.length; i++) {
          final seg = _segments[i];
          final text = seg['text'] as String;
          final note = seg['note'];
          final segGraphemes = text.characters.toList();
          final segLen = segGraphemes.length;
          final visibleInSeg = (visible - accumulated).clamp(0, segLen).toInt();

          if (visibleInSeg > 0) {
            final visibleText = segGraphemes.take(visibleInSeg).join();
            if (note != null && visibleInSeg == segLen) {
              spans.add(
                TextSpan(
                  text: visibleText,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dashed,
                    color: Colors.blue,
                  ).merge(style),
                  recognizer: _recognizers[i],
                ),
              );
            } else {
              spans.add(TextSpan(text: visibleText, style: style));
            }
          }
          accumulated += segLen;
          if (accumulated >= visible) break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(
          style: style,
          children: spans.isEmpty ? [const TextSpan(text: '')] : spans,
        ),
        textAlign: widget.textAlign,
        textDirection: _isArabic ? TextDirection.rtl : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        widget.textStyle ??
        DefaultTextStyle.of(context).style.copyWith(fontSize: 16);

    if (_fullText.isEmpty) return const SizedBox.shrink();

    if (widget.blockData is String) {
      return _buildPlain(context, defaultStyle);
    } else if (widget.blockData is List) {
      return _buildSegments(context, defaultStyle);
    } else {
      return const SizedBox.shrink();
    }
  }
}

// ----------------- Particle painter for "boom" -----------------
// Simple, deterministic particles per token so each word emits a short burst.
class _TokenBoomPainter extends CustomPainter {
  final double progress; // 0..1
  final int seed;
  final Color color;

  _TokenBoomPainter({
    required this.progress,
    required this.seed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rnd = Random(seed);

    final int n = 8; // particles
    final double maxRadius = min(size.width, size.height) * 0.9;
    final Paint p = Paint();
    for (int i = 0; i < n; i++) {
      final angle = (i / n) * 2 * pi + (rnd.nextDouble() - 0.5) * 0.6;
      final speedFactor = 0.4 + rnd.nextDouble() * 0.9;
      final dist = Curves.easeOut.transform(progress) * maxRadius * speedFactor;
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      final particleRadius = (1.2 + rnd.nextDouble() * 3.6) * (1 - progress);
      final alpha = ((1 - progress) * 255).clamp(0, 255).toInt();
      p.color = color.withAlpha(alpha).withOpacity(0.9);
      canvas.drawCircle(pos, particleRadius, p);

      // small glowing dot
      final glowPaint = Paint()..color = color.withAlpha((alpha * 0.6).toInt());
      canvas.drawCircle(pos, particleRadius * 0.6, glowPaint);
    }

    // small shock ring
    final ringPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * (1 - progress + 0.1)
          ..color = color.withAlpha(
            ((1 - progress) * 120).clamp(0, 120).toInt(),
          );
    final ringRadius = Curves.easeOut.transform(progress) * maxRadius * 0.5;
    canvas.drawCircle(center, ringRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _TokenBoomPainter old) {
    return old.progress != progress || old.seed != seed || old.color != color;
  }
}
