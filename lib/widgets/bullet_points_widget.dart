import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/theme/custom_colors.dart';
import '../models/theme/custom_text_style.dart';

enum BulletStyle {
  modern, // Sophisticated style for adults
  colorful, // Playful style for children
  minimal, // Clean minimal style
}

class BulletPointsWidget extends StatefulWidget {
  final List<String> points;
  final String? title;
  final Duration animationDelay;
  final Duration staggerDelay;
  final bool autoPlay;
  final TextStyle? pointTextStyle;
  final TextStyle? titleTextStyle;
  final Color? bulletColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final BulletStyle style;

  const BulletPointsWidget({
    super.key,
    required this.points,
    this.title,
    this.animationDelay = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 150),
    this.autoPlay = true,
    this.pointTextStyle,
    this.titleTextStyle,
    this.bulletColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.style = BulletStyle.modern,
  });

  @override
  State<BulletPointsWidget> createState() => _BulletPointsWidgetState();
}

class _BulletPointsWidgetState extends State<BulletPointsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;
  late AnimationController _titleController;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.autoPlay) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _titleSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    // Points animations
    _controllers = List.generate(
      widget.points.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _slideAnimations =
        _controllers.map((controller) {
          return Tween<double>(begin: 100.0, end: 0.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          );
        }).toList();

    _fadeAnimations =
        _controllers.map((controller) {
          return Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        }).toList();

    _scaleAnimations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          );
        }).toList();
  }

  void _startAnimations() async {
    // Start title animation
    if (widget.title != null) {
      await Future.delayed(widget.animationDelay);
      _titleController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Start points animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.staggerDelay);
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final customTextStyle = Theme.of(context).extension<CustomTextStyle>();

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _getContainerDecoration(customColors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Section
          if (widget.title != null) ...[
            AnimatedBuilder(
              animation: _titleController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _titleSlideAnimation.value),
                  child: Opacity(
                    opacity: _titleFadeAnimation.value,
                    child: _buildTitleContainer(customTextStyle),
                  ),
                );
              },
            ),
            SizedBox(height: widget.style == BulletStyle.minimal ? 16 : 20),
          ],

          // Points Section
          ...widget.points.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;

            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimations[index].value, 0),
                  child: Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Opacity(
                      opacity: _fadeAnimations[index].value,
                      child: _buildPointContainer(
                        index,
                        point,
                        customTextStyle,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  BoxDecoration _getContainerDecoration(CustomColors? customColors) {
    switch (widget.style) {
      case BulletStyle.modern:
        return BoxDecoration(
          color:
              widget.backgroundColor ??
              customColors?.lightBg ??
              const Color(0xFFFAFAFA),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case BulletStyle.minimal:
        return BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        );
      case BulletStyle.colorful:
        return BoxDecoration(
          color:
              widget.backgroundColor ??
              customColors?.lightBg ??
              const Color(0xFFF8F9FA),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        );
    }
  }

  Widget _buildTitleContainer(CustomTextStyle? customTextStyle) {
    switch (widget.style) {
      case BulletStyle.modern:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.title!,
            style:
                widget.titleTextStyle ??
                GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        );
      case BulletStyle.minimal:
        return Text(
          widget.title!,
          style:
              widget.titleTextStyle ??
              GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        );
      case BulletStyle.colorful:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.title!,
            style:
                widget.titleTextStyle ??
                GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  Widget _buildPointContainer(
    int index,
    String point,
    CustomTextStyle? customTextStyle,
  ) {
    switch (widget.style) {
      case BulletStyle.modern:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, left: 12),
                child: _buildModernBullet(index),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    point,
                    style:
                        widget.pointTextStyle ??
                        customTextStyle?.lessonText ??
                        GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                          height: 1.6,
                        ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),
        );
      case BulletStyle.minimal:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, left: 8),
                child: _buildMinimalBullet(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    point,
                    style:
                        widget.pointTextStyle ??
                        customTextStyle?.lessonText ??
                        GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),
        );
      case BulletStyle.colorful:
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, left: 16),
                child: _buildColorfulBullet(index),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getBulletColor(index).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getBulletColor(index).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    point,
                    style:
                        widget.pointTextStyle ??
                        customTextStyle?.lessonText ??
                        GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                          height: 1.6,
                        ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildModernBullet(int index) {
    final primaryColor = widget.bulletColor ?? const Color(0xFF1F2937);

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBullet() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: widget.bulletColor ?? const Color(0xFF6B7280),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildColorfulBullet(int index) {
    final color = _getBulletColor(index);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Color _getBulletColor(int index) {
    if (widget.bulletColor != null) return widget.bulletColor!;

    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
    ];

    return colors[index % colors.length];
  }

  // Public method to trigger animations manually
  void startAnimations() {
    _startAnimations();
  }

  // Public method to reset animations
  void resetAnimations() {
    _titleController.reset();
    for (var controller in _controllers) {
      controller.reset();
    }
  }
}

// Helper class for bullet points data
class BulletPointsData {
  final List<String> points;
  final String? title;
  final BulletStyle? style;

  BulletPointsData({required this.points, this.title, this.style});

  factory BulletPointsData.fromJson(Map<String, dynamic> json) {
    BulletStyle? style;
    if (json['style'] != null) {
      switch (json['style'].toString().toLowerCase()) {
        case 'modern':
          style = BulletStyle.modern;
          break;
        case 'colorful':
          style = BulletStyle.colorful;
          break;
        case 'minimal':
          style = BulletStyle.minimal;
          break;
      }
    }

    return BulletPointsData(
      points: List<String>.from(json['points'] ?? []),
      title: json['title'],
      style: style,
    );
  }

  Map<String, dynamic> toJson() {
    return {'points': points, 'title': title, 'style': style?.name};
  }
}
