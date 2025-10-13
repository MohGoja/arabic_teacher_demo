import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;

class SelectiveTextData {
  final String fullText;
  final List<SelectionItem> selections;
  SelectiveTextData({required this.fullText, required this.selections});

  factory SelectiveTextData.fromMap(Map<String, dynamic> data) {
    final full = data['full_text']?.toString() ?? '';
    final List<SelectionItem> sels = [];
    final raw = data['selectedText'];
    int order = 0;

    if (raw is Map) {
      raw.forEach((k, v) {
        final phrase = k.toString();
        final expl = v?.toString() ?? '';
        if (phrase.isNotEmpty) {
          sels.add(
            SelectionItem(
              phrase: phrase,
              explanation: expl,
              inputOrder: order++,
            ),
          );
        }
      });
    } else if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          e.forEach((k, v) {
            final phrase = k.toString();
            final expl = v?.toString() ?? '';
            if (phrase.isNotEmpty) {
              sels.add(
                SelectionItem(
                  phrase: phrase,
                  explanation: expl,
                  inputOrder: order++,
                ),
              );
            }
          });
        }
      }
    }

    return SelectiveTextData(fullText: full, selections: sels);
  }
}

class SelectionItem {
  final String phrase;
  final String explanation;
  final int inputOrder;
  SelectionItem({
    required this.phrase,
    required this.explanation,
    required this.inputOrder,
  });
}

enum TooltipPlacement { above, below, left, right }

enum SequenceOrder { inputOrder, textPosition }

class SelectiveText extends StatefulWidget {
  final SelectiveTextData model;
  final TextStyle? textStyle;
  final TextDirection textDirection;

  // Tooltip controls
  final TooltipPlacement placement;
  final double tooltipGap;
  final double tooltipMaxWidth;
  final bool clampToContainer; // clamp inside container if bounded

  // Autoplay sequence
  final bool autoplaySequence;
  final SequenceOrder sequenceOrder; // input order or first-appearance order
  final Duration autoplayDelay;
  final Duration eachVisibleFor;
  final Duration gapBetweenTooltips;

  // After user tap, hide automatically after:
  final Duration tapVisibleFor;

  const SelectiveText({
    super.key,
    required this.model,
    this.textStyle,
    this.textDirection = TextDirection.rtl,
    this.placement = TooltipPlacement.above,
    this.tooltipGap = 8,
    this.tooltipMaxWidth = 360,
    this.clampToContainer = true,
    this.autoplaySequence = true,
    this.sequenceOrder = SequenceOrder.inputOrder,
    this.autoplayDelay = const Duration(seconds: 5),
    this.eachVisibleFor = const Duration(milliseconds: 2000),
    this.gapBetweenTooltips = const Duration(milliseconds: 250),
    this.tapVisibleFor = const Duration(milliseconds: 1800),
  });

  @override
  State<SelectiveText> createState() => _SelectiveTextState();
}

class _SelectiveTextState extends State<SelectiveText>
    with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _richKey = GlobalKey();

  final List<_Anchor> _anchors = [];
  final List<TapGestureRecognizer> _recognizers = [];
  List<int> _sequence = [];
  int _cancelToken = 0;

  Size? _lastRichSize;

  @override
  void initState() {
    super.initState();
    _initAnchorsAndSequence();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeRects());
    _maybeRunAutoplay();
  }

  @override
  void didUpdateWidget(covariant SelectiveText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final dataChanged =
        oldWidget.model.fullText != widget.model.fullText ||
        !_sameSelections(oldWidget.model.selections, widget.model.selections);

    final behaviorChanged =
        oldWidget.sequenceOrder != widget.sequenceOrder ||
        oldWidget.autoplaySequence != widget.autoplaySequence ||
        oldWidget.autoplayDelay != widget.autoplayDelay ||
        oldWidget.eachVisibleFor != widget.eachVisibleFor ||
        oldWidget.gapBetweenTooltips != widget.gapBetweenTooltips ||
        oldWidget.placement != widget.placement ||
        oldWidget.tooltipGap != widget.tooltipGap ||
        oldWidget.tooltipMaxWidth != widget.tooltipMaxWidth ||
        oldWidget.textDirection != widget.textDirection ||
        oldWidget.tapVisibleFor != widget.tapVisibleFor ||
        oldWidget.clampToContainer != widget.clampToContainer;

    if (dataChanged) {
      _disposeRecognizers();
      _disposeAnchors();
      _initAnchorsAndSequence();
      WidgetsBinding.instance.addPostFrameCallback((_) => _computeRects());
    } else if (behaviorChanged) {
      _recomputeSequenceOnly();
      WidgetsBinding.instance.addPostFrameCallback((_) => _computeRects());
    }

    if (dataChanged || behaviorChanged) {
      _cancelAutoplay();
      _maybeRunAutoplay();
    }
  }

  @override
  void dispose() {
    _cancelAutoplay();
    _disposeRecognizers();
    _disposeAnchors();
    super.dispose();
  }

  bool _sameSelections(List<SelectionItem> a, List<SelectionItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].phrase != b[i].phrase ||
          a[i].explanation != b[i].explanation ||
          a[i].inputOrder != b[i].inputOrder)
        return false;
    }
    return true;
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _disposeAnchors() {
    for (final a in _anchors) {
      a.ctrl.dispose();
      a.tapHideTimer?.cancel();
    }
    _anchors.clear();
    _sequence.clear();
  }

  void _initAnchorsAndSequence() {
    final text = widget.model.fullText;
    final items = widget.model.selections;

    final matches = <_Match>[];
    for (var i = 0; i < items.length; i++) {
      final phrase = items[i].phrase;
      if (phrase.isEmpty) continue;
      final idx = text.indexOf(phrase);
      if (idx >= 0) {
        matches.add(_Match(start: idx, end: idx + phrase.length, selIndex: i));
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    final filtered = <_Match>[];
    int lastEnd = -1;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        filtered.add(m);
        lastEnd = m.end;
      }
    }

    for (final m in filtered) {
      final it = items[m.selIndex];
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
      );

      final anchorIndex = _anchors.length; // capture stable index
      _anchors.add(
        _Anchor(
          start: m.start,
          end: m.end,
          phrase: it.phrase,
          explanation: it.explanation,
          inputOrder: it.inputOrder,
          ctrl: ctrl,
          fade: CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
          scale: CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack),
          tooltipKey: GlobalKey(),
        ),
      );

      _recognizers.add(
        TapGestureRecognizer()..onTap = () => _onUserTap(anchorIndex),
      );
    }

    _recomputeSequenceOnly();
  }

  void _recomputeSequenceOnly() {
    _sequence = List<int>.generate(_anchors.length, (i) => i); // text order
    if (widget.sequenceOrder == SequenceOrder.inputOrder) {
      _sequence.sort(
        (a, b) => _anchors[a].inputOrder.compareTo(_anchors[b].inputOrder),
      );
    }
    setState(() {});
  }

  // Measure rects (phrase boxes) and map to Stack coords.
  void _computeRects() {
    final richCtx = _richKey.currentContext;
    final stackCtx = _stackKey.currentContext;
    if (richCtx == null || stackCtx == null) return;

    final render = richCtx.findRenderObject();
    final stackBox = stackCtx.findRenderObject();
    if (render is! RenderParagraph || stackBox is! RenderBox) return;

    final newSize = render.size;
    if (_lastRichSize == newSize && _anchors.every((a) => a.rect != null))
      return;
    _lastRichSize = newSize;

    for (final a in _anchors) {
      final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: a.start, extentOffset: a.end),
      );
      if (boxes.isEmpty) {
        a.rect = null;
        continue;
      }
      final b = boxes.first;
      final globalTopLeft = render.localToGlobal(Offset(b.left, b.top));
      final topLeftInStack = (stackBox).globalToLocal(globalTopLeft);
      a.rect = Rect.fromLTWH(
        topLeftInStack.dx,
        topLeftInStack.dy,
        b.right - b.left,
        b.bottom - b.top,
      );
    }
    setState(() {});
  }

  void _cancelAutoplay() => _cancelToken++;

  void _maybeRunAutoplay() {
    if (!widget.autoplaySequence || _anchors.isEmpty) return;
    final my = ++_cancelToken;
    () async {
      await Future.delayed(widget.autoplayDelay);
      if (!mounted || my != _cancelToken) return;

      for (final idx in _sequence) {
        _show(idx);
        await Future.delayed(widget.eachVisibleFor);
        if (!mounted || my != _cancelToken) return;

        _hide(idx);
        if (idx != _sequence.last) {
          await Future.delayed(widget.gapBetweenTooltips);
          if (!mounted || my != _cancelToken) return;
        }
      }
    }();
  }

  void _show(int i) {
    if (i < 0 || i >= _anchors.length) return;

    // hide others
    for (var j = 0; j < _anchors.length; j++) {
      if (j != i && _anchors[j].visible) {
        _anchors[j].ctrl.reverse();
        _anchors[j].visible = false;
        _anchors[j].tapHideTimer?.cancel();
      }
    }

    final a = _anchors[i];
    if (!a.visible) {
      setState(() => a.visible = true);
      a.ctrl.forward(from: 0);

      // measure tooltip after it appears to center it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = a.tooltipKey.currentContext;
        if (ctx != null && mounted) {
          final box = ctx.findRenderObject() as RenderBox?;
          final size = box?.size;
          if (size != null && size != a.tooltipSize) {
            setState(() => a.tooltipSize = size);
          }
        }
      });
    }
  }

  void _hide(int i) {
    if (i < 0 || i >= _anchors.length) return;
    final a = _anchors[i];
    if (a.visible) {
      a.ctrl.reverse();
      setState(() => a.visible = false);
      a.tapHideTimer?.cancel();
      a.tapHideTimer = null;
    }
  }

  void _onUserTap(int i) {
    _show(i);
    final a = _anchors[i];
    a.tapHideTimer?.cancel();
    a.tapHideTimer = Timer(widget.tapVisibleFor, () {
      if (!mounted) return;
      _hide(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.textStyle ??
        DefaultTextStyle.of(context).style.copyWith(height: 1.4);
    final full = widget.model.fullText;

    if (_anchors.isEmpty) {
      return Directionality(
        textDirection: widget.textDirection,
        child: Text(full, style: style),
      );
    }

    // Pure TextSpans (no WidgetSpan) so RTL order stays intact.
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (var i = 0; i < _anchors.length; i++) {
      final a = _anchors[i];
      if (cursor < a.start)
        spans.add(TextSpan(text: full.substring(cursor, a.start)));
      spans.add(
        TextSpan(
          text: full.substring(a.start, a.end),
          style: style.copyWith(
            fontWeight: FontWeight.w600,
            backgroundColor: const Color(0xFF568da8).withValues(alpha: 0.3),
          ),
          recognizer: _recognizers[i],
        ),
      );
      cursor = a.end;
    }
    if (cursor < full.length) spans.add(TextSpan(text: full.substring(cursor)));

    final mq = MediaQuery.of(context);

    // Use LayoutBuilder to AVOID reading size during build.
    return Directionality(
      textDirection: widget.textDirection,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW =
              constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : mq.size.width;
          final hasBoundedH = constraints.hasBoundedHeight;
          final maxH = hasBoundedH ? constraints.maxHeight : double.infinity;
          final maxTooltipWidth = widget.tooltipMaxWidth.clamp(120, maxW - 24);

          Offset _centeredPositionFor(_Anchor a) {
            final r = a.rect!;
            final w =
                a.tooltipSize?.width ??
                maxTooltipWidth.toDouble(); // fallback until measured
            final h = a.tooltipSize?.height ?? 40.0;

            double left, top;
            switch (widget.placement) {
              case TooltipPlacement.above:
                left = r.center.dx - (w / 2);
                top = r.top - widget.tooltipGap - h;
                break;
              case TooltipPlacement.below:
                left = r.center.dx - (w / 2);
                top = r.bottom + widget.tooltipGap;
                break;
              case TooltipPlacement.left:
                left = r.left - widget.tooltipGap - w;
                top = r.center.dy - (h / 2);
                break;
              case TooltipPlacement.right:
                left = r.right + widget.tooltipGap;
                top = r.center.dy - (h / 2);
                break;
            }

            if (widget.clampToContainer) {
              left = left.clamp(0.0, (maxW - w).clamp(0.0, double.infinity));
              if (hasBoundedH) {
                top = top.clamp(0.0, (maxH - h).clamp(0.0, double.infinity));
              }
            }
            return Offset(left, top);
          }

          return RepaintBoundary(
            key: _stackKey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Paragraph to measure
                RichText(
                  key: _richKey,
                  text: TextSpan(style: style, children: spans),
                  textScaleFactor: mq.textScaleFactor,
                ),

                // Tooltips
                ..._anchors.map((a) {
                  if (a.rect == null || !a.visible)
                    return const SizedBox.shrink();
                  final pos = _centeredPositionFor(a);

                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: IgnorePointer(
                      ignoring: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxTooltipWidth.toDouble(),
                        ),
                        child: FadeTransition(
                          opacity: a.fade,
                          child: ScaleTransition(
                            scale: a.scale,
                            child: _TooltipBox(
                              key: a.tooltipKey,
                              text: a.explanation,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TooltipBox extends StatelessWidget {
  final String text;
  const _TooltipBox({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: ShapeDecoration(
          color: Colors.black.withOpacity(0.92),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              blurRadius: 8,
              color: Color(0x33000000),
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: style.copyWith(
            color: Colors.white,
            height: 1.25,
            fontSize: (style.fontSize ?? 14) * 0.95,
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}

class _Match {
  final int start, end, selIndex;
  _Match({required this.start, required this.end, required this.selIndex});
}

class _Anchor {
  final int start, end;
  final String phrase, explanation;
  final int inputOrder;
  final AnimationController ctrl;
  final Animation<double> fade;
  final Animation<double> scale;

  Rect? rect; // phrase rect in Stack coordinates
  bool visible = false;

  // For centering:
  final GlobalKey tooltipKey;
  Size? tooltipSize;

  // Auto-hide after tap
  Timer? tapHideTimer;

  _Anchor({
    required this.start,
    required this.end,
    required this.phrase,
    required this.explanation,
    required this.inputOrder,
    required this.ctrl,
    required this.fade,
    required this.scale,
    required this.tooltipKey,
  });
}
