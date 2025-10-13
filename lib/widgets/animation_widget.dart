import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AnimationWidget extends StatefulWidget {
  final String animationName;
  final String animationType;
  const AnimationWidget({
    super.key,
    required this.animationName,
    required this.animationType,
  });

  @override
  State<AnimationWidget> createState() => _AnimationWidgetState();
}

class _AnimationWidgetState extends State<AnimationWidget> {
  late StateMachineController ctrl;
  bool isAnimating = false;

  void onRivInit(Artboard artboard) {
    // toggleTrigger = ctrl.getTriggerInput('Trigger_Toggle');
    // isDarkModeInput = ctrl.getBoolInput('Is_Dark_Mode');

    // final Quranpageprovider quranpageprovider =
    //     Provider.of<Quranpageprovider>(context, listen: false);

    // if (isDarkModeInput != null) {
    //   // Directly set the state of the animation to match the current theme
    //   isDarkModeInput!.value = quranpageprovider.isDarkMode;
    // }
  }

  @override
  Widget build(BuildContext context) {
    final String animationName = widget.animationName;
    final double animationBoxHeight =
        widget.animationType == "large" ? 300 : 100;
    if (animationName == "") {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          height: animationBoxHeight,
          width: double.infinity,
          child: RiveAnimation.asset(
            'assets/animations/arabic_app_animations.riv',
            // clipRect: Rect.fromLTWH(0, 0, 200, 100),
            artboard: 'ab_$animationName',
            stateMachines: ['sm_$animationName'],
            fit: BoxFit.contain,
            // speedMultiplier: 2.0,
            onInit: onRivInit,
          ),
        );
      },
    );
  }
}
