import 'dart:async';
import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
import 'package:arabic_teacher_demo/widgets/animated_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
import '../models/lesson.dart';
import '../widgets/slide_widget.dart';

final Map<String, String> items = {
  "khalid": "خالد",
  "mark": "مارك",
  "anas": "أنس",
  "hamid": "حامد",
  "mazen": "مازن",
  "moncellence": "منذر",
};
String? selectedNarrator = "khalid";

final Map<dynamic, String> animatedTextModes = {
  AnimatedTextMode.none: "بدون تأثير",
  AnimatedTextMode.boom: "انفجار",

  AnimatedTextMode.scramble: "خلط",
  AnimatedTextMode.slide: "انزلاق",
  AnimatedTextMode.typewriter: "آلة كاتبة",
  // AnimatedTextMode.wave: "موجة",
};

AnimatedTextMode? animatedTextMode = AnimatedTextMode.typewriter;

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({super.key, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> with TickerProviderStateMixin {
  int _currentIndex = 41;
  late int slidesLength;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _showSettings = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // COMMENTED OUT: Arrow button configuration - moved to SlideWidget
  // static const double _arrowIconSize = 16.0;
  // static const double _arrowButtonPadding = 6.0;
  // static const double _arrowButtonSize = 36.0;
  // static const double _arrowSpacing = 6.0;

  double _playbackRate = 1.0; // normal speed
  final double _minRate = 0.9;
  final double _maxRate = 1.5;
  final double _rateStep = 0.1;

  static const double _minBottomHeight =
      50; // height while collapsed (progress row)
  static const double _maxBottomHeight = 210; // full expanded height
  late final AnimationController _expandController;
  late final Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    slidesLength = widget.lesson.slides.length;
    // Listen for state changes
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // animation controller for AppBar.bottom height
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(
      begin: _minBottomHeight,
      end: _maxBottomHeight,
    ).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    // set initial controller state according to _showSettings (false by default)
    if (_showSettings) {
      _expandController.value = 1.0;
    } else {
      _expandController.value = 0.0;
    }

    // keep UI in sync with animation
    _heightAnimation.addListener(() => setState(() {}));
  }

  void _nextSlide() {
    if (_currentIndex < widget.lesson.slides.length - 1) {
      setState(() => _currentIndex++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End of lesson! Go to next lesson...")),
      );
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _playAudio() async {
    // final slide = widget.lesson.slides[_currentIndex];
    final int currentSlide = _currentIndex + 1;
    final String lessonAudioSource =
        "https://bnmalek.com/wp-content/uploads/language-app/lessons-audio/lesson-1/$selectedNarrator/$currentSlide.mp3";
    // if (slide.audio != null) {
    await _player.stop();
    await _player.play(UrlSource(lessonAudioSource));
    await _player.setPlaybackRate(_playbackRate);
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("لا يوجد ملف صوتي لهذه الشريحة")),
    //   );
    // }
  }

  void _stopAudio() async {
    await _player.stop();
  }

  // call this when user changes speed
  Future<void> _updatePlaybackRate(double newRate) async {
    setState(() => _playbackRate = newRate);

    // if audio is currently playing, update it live
    if (_isPlaying) {
      try {
        await _player.setPlaybackRate(_playbackRate);
      } catch (e) {
        // handle errors (some platforms / codecs might behave differently)
        debugPrint('Failed to set playback rate: $e');
      }
    }
  }

  // COMMENTED OUT: convenience helpers for +/- buttons - no longer used
  // void _increaseRate() => _updatePlaybackRate(
  //   (_playbackRate + _rateStep).clamp(_minRate, _maxRate),
  // );
  // void _decreaseRate() => _updatePlaybackRate(
  //   (_playbackRate - _rateStep).clamp(_minRate, _maxRate),
  // );

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    final actualWidth = mediaQuery.width;
    final slide = widget.lesson.slides[_currentIndex];
    final int progressPercent = ((_currentIndex / slidesLength) * 100).toInt();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).extension<CustomColors>()!.lightBg,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_heightAnimation.value),
          child: Container(
            height: _heightAnimation.value,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- always visible progress row (kept intact) ---
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / slidesLength,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$progressPercent%'),
                  ],
                ),

                // --- settings area height is derived from the height animation ---
                Builder(
                  builder: (context) {
                    final double settingsMaxHeight =
                        _maxBottomHeight - _minBottomHeight;
                    final double settingsHeight = (_heightAnimation.value -
                            _minBottomHeight)
                        .clamp(0.0, settingsMaxHeight);

                    return SizedBox(
                      height: settingsHeight,
                      // ClipRect prevents any temporary overflow during animation
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          // heightFactor animates the child content smoothly
                          heightFactor:
                              settingsMaxHeight > 0
                                  ? (settingsHeight / settingsMaxHeight)
                                  : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    DropdownButton<String>(
                                      hint: const Text("اختر صوت الاستاذ"),
                                      value: selectedNarrator,
                                      onChanged:
                                          _isPlaying
                                              ? null
                                              : (String? newValue) {
                                                setState(() {
                                                  selectedNarrator = newValue;
                                                });
                                              },
                                      items:
                                          items.entries.map((entry) {
                                            return DropdownMenuItem<String>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            );
                                          }).toList(),
                                    ),
                                    if (_isPlaying)
                                      IconButton(
                                        onPressed: _stopAudio,
                                        icon: const Icon(Icons.stop),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text('سرعة تشغيل الصوت'),
                                    Expanded(
                                      child: Slider(
                                        min: _minRate,
                                        max: _maxRate,
                                        divisions:
                                            ((_maxRate - _minRate) / _rateStep)
                                                .round(),
                                        value: _playbackRate,
                                        onChanged:
                                            (v) => _updatePlaybackRate(v),
                                      ),
                                    ),
                                  ],
                                ),
                                DropdownButton<String>(
                                  hint: const Text("شكل حركة الكلام"),
                                  value:
                                      animatedTextMode != null
                                          ? animatedTextModes[animatedTextMode]
                                          : "آلة كاتبة",
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      animatedTextMode =
                                          animatedTextModes.entries
                                                  .firstWhere(
                                                    (entry) =>
                                                        entry.value == newValue,
                                                  )
                                                  .key
                                              as AnimatedTextMode;
                                    });
                                  },
                                  items:
                                      animatedTextModes.entries.map((entry) {
                                        return DropdownMenuItem<String>(
                                          value: entry.value,
                                          child: Text(entry.value),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // leading: const CloseButton(),
        actions: [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.auto_awesome)),
          IconButton(
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
                if (_showSettings) {
                  _expandController.forward();
                } else {
                  _expandController.reverse();
                }
              });
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: actualWidth < 400 ? 7 : actualWidth * 0.05,
            ),
            child:
            // AnimatedSwitcher only wraps the card content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: Card(
                key: ValueKey(_currentIndex),
                clipBehavior: Clip.hardEdge,
                margin: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 5,
                  bottom: MediaQuery.paddingOf(context).bottom + 15,
                ),
                elevation: 10,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SlideWidget(
                  index: _currentIndex,
                  slide: slide,
                  animatedTextMode: animatedTextMode!,
                  isPlaying: _isPlaying,
                  onPlayAudio: _playAudio,
                  onStopAudio: _stopAudio,
                  onNextSlide: _nextSlide,
                  onPrevSlide: _prevSlide,
                  currentIndex: _currentIndex,
                  totalSlides: slidesLength,
                ),
              ),
            ),

            // COMMENTED OUT: Previous/Next navigation buttons - moved to SlideWidget
            /*
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Previous arrow button (on the right in RTL layout) - always visible
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: IconButton(
                        onPressed: _currentIndex == 0 ? null : _prevSlide,
                        icon: const Icon(Icons.arrow_back_ios_new),
                        iconSize: _arrowIconSize,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          foregroundColor:
                              _currentIndex == 0
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                          padding: EdgeInsets.all(_arrowButtonPadding),
                          minimumSize: Size(_arrowButtonSize, _arrowButtonSize),
                          maximumSize: Size(_arrowButtonSize, _arrowButtonSize),
                        ),
                      ),
                    ),
                    const SizedBox(width: _arrowSpacing),
                    // AnimatedSwitcher only wraps the card content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                        child: Card(
                          key: ValueKey(_currentIndex),
                          clipBehavior: Clip.hardEdge,
                          margin: EdgeInsets.only(
                            top: MediaQuery.paddingOf(context).top + 5,
                            bottom: MediaQuery.paddingOf(context).bottom + 15,
                          ),
                          elevation: 10,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: SlideWidget(
                            index: _currentIndex,
                            slide: slide,
                            animatedTextMode: animatedTextMode!,
                            isPlaying: _isPlaying,
                            onPlayAudio: _playAudio,
                            onStopAudio: _stopAudio,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: _arrowSpacing),
                    // Next arrow button (on the left in RTL layout) - always visible
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: IconButton(
                        onPressed: _nextSlide,
                        icon: const Icon(Icons.arrow_forward_ios),
                        iconSize: _arrowIconSize,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.all(_arrowButtonPadding),
                          minimumSize: Size(_arrowButtonSize, _arrowButtonSize),
                          maximumSize: Size(_arrowButtonSize, _arrowButtonSize),
                        ),
                      ),
                    ),
                  ],
                ),
                */
          ),
        ),
      ),
    );
  }
}

ButtonStyle actionButtonsStyle = ElevatedButton.styleFrom(
  shadowColor: const Color(0xffd3e8f4),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero, // ✅ no rounding
    side: BorderSide(
      width: 1,
      color: Color(0xffd3e8f4),
      style: BorderStyle.solid,
    ),
  ),
);
