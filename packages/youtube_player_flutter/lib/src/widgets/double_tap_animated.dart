import 'package:flutter/material.dart';
import '../utils/skip_button.dart';
import 'circular_reveal_animation.dart';
import 'oval_left_border_clipper.dart';
import 'oval_right_border_clipper.dart';

/// A custom widget for providing double-tap animations with skip functionality.
class DoubleTapAnimated extends StatefulWidget {

  /// Create [DoubleTapAnimated] widget
  const DoubleTapAnimated({
    required this.skipButtonNotify,
    required this.rippleExpansionTime,
    required this.expansionHoldingTime,
    required this.fadeTime,
    required this.countOfSkip,
    required this.curveBank,
    required this.ovalColor,
    required this.textOfSkip,
    required this.icon,
    required this.isRight,
    required this.labelStyle,
    Key? key,
  }) : super(key: key);

  /// is the widget in right or left of screen
  final bool isRight;

  /// class notifier
  final SkipButtonNotifier skipButtonNotify;

  /// text will show on skip
  final String textOfSkip;

  /// Duration for the ripple expansion animation and the time a skip button stays expanded.
  final Duration rippleExpansionTime, expansionHoldingTime;

  /// duration of FadeTransition
  final Duration fadeTime;

  /// icon of skip button
  final Widget icon;

  /// count of seconds will skip
  final int countOfSkip;

  /// style of text show on skip
  final TextStyle labelStyle;

  /// radios of skip button
  final double curveBank;

  /// background of circle button
  final Color ovalColor;

  @override
  _DoubleTapAnimatedState createState() => _DoubleTapAnimatedState();
}

class _DoubleTapAnimatedState extends State<DoubleTapAnimated>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  bool showInRight = false;
  bool showInLeft = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.rippleExpansionTime,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeTime,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.linear,
    );
    widget.skipButtonNotify.addListener(() {
      _onChange(context);
    });
  }

  Future<void> _onChange(BuildContext context) async
  {
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reset();
    }
    if (_fadeController.status == AnimationStatus.reverse) {
      _fadeController.reset();
    }
    try {
      _fadeController.value = 1;
      await _animationController.forward().orCancel;
      await Future.delayed(widget.expansionHoldingTime);
      _animationController.reset();
      await _fadeController.reverse().orCancel;
      _fadeController.reset();
    } on TickerCanceled {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _animationController.status == AnimationStatus.dismissed?const SizedBox(): AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: widget.isRight == true? widget.skipButtonNotify.showSkipToForward == true ? 1 : 0:widget.skipButtonNotify.showSkipToPrevious == true ? 1 : 0,
          child:ColoredBox(
            color:Colors.transparent,
            child:   FadeTransition(
              opacity: _fadeAnimation,
              child: ClipPath(
                clipper: widget.isRight == true
                    ? OvalRightBorderClipper(curveHeight: widget.curveBank)
                    : OvalLeftBorderClipper(curveHeight: widget.curveBank),
                child:
                    CircularRevealAnimation(
                      animation: _animation,
                      child: SizedBox.expand(
                        child: _IconWithShade(
                          countOfSkip: widget.countOfSkip,
                          textOfSkip: widget.textOfSkip,
                          ovalColor: widget.ovalColor,
                          // textBuilder: widget.labelBuilder,
                          icon: widget.icon,
                          textStyle: widget.labelStyle,
                        ),
                      ),
                    ),


              )),
        ));
  }
}

class _IconWithShade extends StatelessWidget {
  const _IconWithShade({
    required this.ovalColor,
    required this.countOfSkip,
    required this.icon,
    required this.textOfSkip,
    required this.textStyle,
    Key? key,
  }) : super(key: key);

  final String textOfSkip;
  final Widget icon;
  final int countOfSkip;
  final TextStyle textStyle;
  final Color ovalColor;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
            height: double.infinity,
            width: double.infinity,
            color: ovalColor,
            child: _DefaultChild(
              textOfSkip:textOfSkip,
              countOfSkip: countOfSkip,
              textStyle: textStyle,
              icon: icon,
            )),
      );
}

class _DefaultChild extends StatelessWidget {
  const _DefaultChild({
    required this.icon,
    required this.countOfSkip,
    required this.textOfSkip,
    required this.textStyle,
    Key? key,
  }) : super(key: key);

  final String textOfSkip;
  final Widget icon;
  final int countOfSkip;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.ltr,
        children: [
          const SizedBox(height: 24),
          icon,
          Text('$countOfSkip $textOfSkip', style: textStyle,)
        ],
      );
}
