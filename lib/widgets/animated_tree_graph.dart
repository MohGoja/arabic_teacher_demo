// lib/widgets/animated_tree_graph.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import 'dart:math' as math;

/// Controller (same public API you already use).
class AnimatedTreeController {
  VoidCallback? _revealNext;
  void Function(String id)? _revealById;
  VoidCallback? _play;
  VoidCallback? _pause;
  VoidCallback? _reset;
  VoidCallback? _revealAll;

  void _attach({
    required VoidCallback revealNext,
    required void Function(String id) revealById,
    required VoidCallback play,
    required VoidCallback pause,
    required VoidCallback reset,
    required VoidCallback revealAll,
  }) {
    _revealNext = revealNext;
    _revealById = revealById;
    _play = play;
    _pause = pause;
    _reset = reset;
    _revealAll = revealAll;
  }

  void revealNext() => _revealNext?.call();
  void revealId(String id) => _revealById?.call(id);
  void play() => _play?.call();
  void pause() => _pause?.call();
  void reset() => _reset?.call();
  void revealAll() => _revealAll?.call();
}

/// New layout:
/// - Column of rows, each row = two columns (left / right).
/// - Left column width = 50% of available width, right = 50%.
class AnimatedTreeGraph extends StatefulWidget {
  final Widget title;
  final List<TreeNode> children;
  final AnimatedTreeController? controller;
  final double sameColumnMinGap;

  /// 0.0 = no overlap (current behavior), 0.5 = start at previous center.
  final double rowOverlapFactor;

  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration nodeAnimationDuration;

  final EdgeInsets rootPadding;
  final double rootHeight;
  final double rowVerticalGap;

  AnimatedTreeGraph({
    Key? key,
    required this.title,
    required this.children,
    this.controller,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(milliseconds: 900),
    this.nodeAnimationDuration = const Duration(milliseconds: 560),
    this.rootPadding = const EdgeInsets.symmetric(vertical: 16),
    this.rootHeight = 56.0,
    this.rowVerticalGap = 5.0,
    this.rowOverlapFactor = 0.5,
    this.sameColumnMinGap = 16.0,
  }) : super(key: key);

  @override
  _AnimatedTreeGraphState createState() => _AnimatedTreeGraphState();
}

class _AnimatedTreeGraphState extends State<AnimatedTreeGraph>
    with TickerProviderStateMixin {
  // revealed flag per node
  final Map<String, bool> _revealed = {};
  // animation controllers: drive connector and card intro (scale & fade)
  final Map<String, AnimationController> _controllers = {};
  Timer? _autoplayTimer;
  bool _isPlaying = false;
  final Map<String, double> _cardHeights = {};
  // NEW: absolute Y for each revealed node
  final Map<String, double> _tops = {};
  double _firstChildTop() =>
      widget.rootPadding.top + widget.rootHeight + widget.rowVerticalGap;
  // keys for measuring card positions (used by connector painter)
  final Map<String, GlobalKey> _cardKeys = {};
  final GlobalKey _containerKey = GlobalKey();
  _CardSide _sideForIndex(int i) =>
      (i % 2 == 0) ? _CardSide.right : _CardSide.left;
  late List<String> _order;

  // Helper: current (synchronous) height of a card (RenderBox if ready, else measured cache)
  double _measureHeightSync(String id) {
    final ctx = _cardKeys[id]?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box != null) return box.size.height;
    return _cardHeights[id] ?? 0.0;
  }

  /// Return the nearest previous revealed card on the same column's bottom (top+height).
  /// If none, returns double.negativeInfinity (so it won't clamp).
  double _prevSameColumnBottom(int idx) {
    final side = _sideForIndex(idx);
    for (int j = idx - 2; j >= 0; j -= 2) {
      final prevId = _order[j];
      if (!(_revealed[prevId] ?? false)) continue;

      final prevTop = _tops[prevId];
      if (prevTop == null) continue;

      final prevH = _measureHeightSync(prevId);
      if (prevH > 0) return prevTop + prevH;
    }
    return double.negativeInfinity;
  }

  // Helper: compute the Y for a node based on previous revealed node
  double _computeTopFor(String id) {
    final idx = _order.indexOf(id);
    if (idx <= 0) return _firstChildTop();

    // Candidate A: anchor to center of previous row
    final prevId = _order[idx - 1];
    final prevTop = _tops[prevId] ?? _firstChildTop();
    final prevH = _measureHeightSync(prevId);
    final f = widget.rowOverlapFactor.clamp(0.0, 1.0);
    final centerCandidate =
        (prevH > 0) ? (prevTop + f * prevH) : (prevTop + widget.rowVerticalGap);

    // Candidate B: avoid overlap with previous card on the same column
    final sameColBottom = _prevSameColumnBottom(idx);
    final avoidOverlapCandidate =
        sameColBottom.isFinite
            ? sameColBottom + widget.sameColumnMinGap
            : double.negativeInfinity;

    // Final
    return math.max(centerCandidate, avoidOverlapCandidate);
  }

  @override
  void initState() {
    super.initState();
    _order = widget.children.map((c) => c.id).toList();

    for (final c in widget.children) {
      _revealed[c.id] = false;
      _controllers[c.id] = AnimationController(
        vsync: this,
        duration: widget.nodeAnimationDuration,
      );
      _cardKeys[c.id] = GlobalKey();
      _cardHeights[c.id] = 0.0;
    }

    widget.controller?._attach(
      revealNext: _revealNext,
      revealById: _revealById,
      play: _startAutoplay,
      pause: _stopAutoplay,
      reset: _reset,
      revealAll: _revealAll,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeightsAndMaybeSetState();
      if (widget.autoPlay) _startAutoplay();
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedTreeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keep controllers / keys in sync with children list
    final newIds = widget.children.map((c) => c.id).toSet();
    final oldIds = _controllers.keys.toSet();

    for (final id in newIds.difference(oldIds)) {
      _revealed[id] = false;
      _controllers[id] = AnimationController(
        vsync: this,
        duration: widget.nodeAnimationDuration,
      );
      _cardKeys[id] = GlobalKey();
      _cardHeights[id] = 0.0; // <- added
    }
    for (final id in oldIds.difference(newIds)) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
      _cardKeys.remove(id);
      _revealed.remove(id);
      _cardHeights.remove(id); // <- added
    }

    _order = widget.children.map((c) => c.id).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _measureHeightsAndMaybeSetState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bool changed = false;
      for (final id in _order) {
        final ctx = _cardKeys[id]?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        if (box != null) {
          final h = box.size.height;
          if ((_cardHeights[id] ?? 0) != h) {
            _cardHeights[id] = h;
            changed = true;
          }
        }
      }
      if (changed && mounted) setState(() {});
    });
  }

  void _revealNext() {
    final next = _order.firstWhere((id) => !_revealed[id]!, orElse: () => '');
    if (next.isEmpty) {
      _stopAutoplay();
      return;
    }
    _revealById(next);
  }

  void _revealById(String id) {
    if (!_controllers.containsKey(id)) return;
    if (_revealed[id] == true) return;

    // Compute the intended top BEFORE inserting the widget
    _tops[id] = _computeTopFor(id);

    // Make it appear in layout
    setState(() => _revealed[id] = true);

    // After this frame, refine the top (in case prev height just changed) and animate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final refinedTop = _computeTopFor(id);
      if ((_tops[id] ?? refinedTop) != refinedTop) {
        setState(() => _tops[id] = refinedTop);
      }
      _controllers[id]!.forward(from: 0.0);
      _measureHeightsAndMaybeSetState(); // keep cache fresh for later nodes
    });
  }

  void _revealAll() {
    for (final id in _order) {
      if (!_revealed[id]!) _revealById(id);
    }
  }

  void _reset() {
    for (final id in _order) {
      _controllers[id]?.stop();
      _controllers[id]?.reset();
      _revealed[id] = false;
    }
    _stopAutoplay();
    setState(() {});
  }

  void _startAutoplay() {
    if (_isPlaying) return;
    _isPlaying = true;
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      final next = _order.firstWhere((id) => !_revealed[id]!, orElse: () => '');
      if (next.isEmpty) {
        _stopAutoplay();
      } else {
        _revealById(next);
      }
    });
  }

  void _stopAutoplay() {
    if (!_isPlaying && _autoplayTimer == null) return;
    _isPlaying = false;
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
  }

  /// Helper to compute card's center local position relative to the overall container.
  /// Returns null if the card is not laid out yet.
  Offset? _cardCenterLocal(String id) {
    final cardKey = _cardKeys[id];
    final cctx = cardKey?.currentContext;
    final containerCtx = _containerKey.currentContext;
    if (cctx == null || containerCtx == null) return null;

    final cardBox = cctx.findRenderObject() as RenderBox?;
    final containerBox = containerCtx.findRenderObject() as RenderBox?;
    if (cardBox == null || containerBox == null) return null;

    final globalCenter = cardBox.localToGlobal(
      cardBox.size.center(Offset.zero),
    );
    return containerBox.globalToLocal(globalCenter);
  }

  /// root center local position inside container
  Offset _rootCenterOffset(double width) {
    return Offset(width / 2, widget.rootPadding.top + widget.rootHeight / 2);
  }

  // lib/widgets/animated_tree_graph.dart
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

        final columnWidth = availableWidth / 2;

        // Position only revealed nodes using their stored tops.
        final positioned = <Widget>[];
        double totalHeight =
            widget.rootPadding.top +
            widget.rootHeight +
            widget.rootPadding.bottom;

        for (int i = 0; i < widget.children.length; i++) {
          final node = widget.children[i];
          if (!(_revealed[node.id] ?? false)) continue;
          final isRight = (i % 2 == 0);

          final top = _tops[node.id] ?? _firstChildTop();

          positioned.add(
            Positioned(
              top: top,
              left: isRight ? columnWidth : 0.0,
              width: columnWidth,
              child: _buildCardCell(
                node,
                columnWidth,
                side: isRight ? _CardSide.right : _CardSide.left,
              ),
            ),
          );

          // track total height so the container is tall enough
          final h = _measureHeightSync(node.id);
          final bottom = top + (h > 0 ? h : 0);
          totalHeight =
              bottom + widget.rowVerticalGap + widget.rootPadding.bottom >
                      totalHeight
                  ? bottom + widget.rowVerticalGap + widget.rootPadding.bottom
                  : totalHeight;
        }

        // Root and connectors in a Stack
        return SizedBox(
          key: _containerKey,
          width: double.infinity,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // connectors behind
              Positioned.fill(
                child: CustomPaint(
                  painter: _TreeConnectorPainter(
                    getNodeEnd: (id) => _cardCenterLocal(id),
                    getRoot: (size) => _rootCenterOffset(size.width),
                    controllers: _controllers.map((k, v) => MapEntry(k, v)),
                  ),
                ),
              ),

              // root title
              Positioned(
                top: widget.rootPadding.top,
                left: 0,
                right: 0,
                height: widget.rootHeight,
                child: Center(child: widget.title),
              ),

              // children
              ...positioned,
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCell() => const SizedBox.shrink();

  Widget _buildCardCell(TreeNode node, double width, {_CardSide? side}) {
    // each card cell has a GlobalKey even when not revealed so that when it's revealed we can measure it.
    final key = _cardKeys[node.id]!;

    // When not revealed we render an empty SizedBox (zero height) so layout collapses.
    // When revealed we render the actual card content. We wrap with AnimatedSize so height changes animate,
    // and we use Fade/Scale transitions driven by the node's controller for a nice entrance.
    final revealed = _revealed[node.id] ?? false;
    final controller = _controllers[node.id]!;

    final animatedCard = AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child:
          revealed
              ? Container(
                key: key,
                // give the card some internal horizontal padding so it doesn't touch the center line
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: FadeTransition(
                  opacity: controller.drive(
                    Tween(
                      begin: 0.0,
                      end: 1.0,
                    ).chain(CurveTween(curve: Curves.easeIn)),
                  ),
                  child: ScaleTransition(
                    scale: controller.drive(
                      Tween(
                        begin: 0.96,
                        end: 1.0,
                      ).chain(CurveTween(curve: Curves.easeOutBack)),
                    ),
                    child: node.content,
                  ),
                ),
              )
              : SizedBox(key: key, height: 0),
    );

    // Ensure the card cell fills the column width: wrap in Align + IntrinsicWidth if needed,
    // but user requested full column width: we'll put the card inside an Align/stretch.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: animatedCard,
      ),
    );
  }
}

/// Which side the card occupies (left or right) — used for future extensions if needed.
enum _CardSide { left, right }

/// Painter that draws connectors from a root point to each node's center.
/// It uses the given per-node controllers to animate the connector progress (0..1).
class _TreeConnectorPainter extends CustomPainter {
  final Offset? Function(String id) getNodeEnd;
  final Offset Function(Size size) getRoot;
  final Map<String, AnimationController> controllers;

  _TreeConnectorPainter({
    required this.getNodeEnd,
    required this.getRoot,
    required this.controllers,
  }) : super(repaint: Listenable.merge(controllers.values.toList()));

  @override
  void paint(Canvas canvas, Size size) {
    final root = getRoot(size);

    final basePaint =
        Paint()
          ..color = Colors.grey.shade700
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    for (final entry in controllers.entries) {
      final id = entry.key;
      final controller = entry.value;
      final progress = controller.value;
      if (progress <= 0.0001) continue;

      final end = getNodeEnd(id);
      if (end == null) continue; // node not laid out yet
      final paint =
          basePaint
            ..shader = const LinearGradient(
              colors: [
                Color.fromARGB(255, 69, 111, 136),
                Color.fromARGB(255, 124, 156, 175),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromPoints(root, end));
      // Draw a cubic curved path from root -> end
      final path = Path();
      path.moveTo(root.dx, root.dy);

      // choose control points to create a gentle branch: control points at midY,
      // and control X biased towards the side (left or right) for nicer curvature.
      final midY = (root.dy + end.dy) / 2;
      final control1 = Offset(root.dx, midY);
      final control2 = Offset(end.dx, midY);

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );

      // draw only the portion according to progress
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      final sub = metric.extractPath(
        0.0,
        metric.length * progress.clamp(0.0, 1.0),
      );
      canvas.drawPath(sub, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    // repaint handled by Listenable.merge of controllers; return true if controllers map changed identity.
    return oldDelegate.controllers != controllers;
  }
}
