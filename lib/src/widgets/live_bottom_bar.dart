import 'package:flutter/material.dart';

import '../../youtube_player_flutter.dart';

class LiveBottomBar extends StatefulWidget {
  final double aspectRatio;
  final Color liveUIColor;
  final bool hideFullScreenButton;

  LiveBottomBar({
    @required this.aspectRatio,
    @required this.liveUIColor,
    @required this.hideFullScreenButton,
  });

  @override
  _LiveBottomBarState createState() => _LiveBottomBarState();
}

class _LiveBottomBarState extends State<LiveBottomBar> {
  double _currentSliderPosition = 0.0;

  YoutubePlayerController controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= YoutubePlayerController.of(context)..addListener(listener);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void listener() {
    if (mounted) {
      setState(() {
        _currentSliderPosition = controller.value.duration.inMilliseconds == 0
            ? 0
            : controller.value.position.inMilliseconds /
                controller.value.duration.inMilliseconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: controller.value.showControls,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 14.0,
          ),
          CurrentPosition(),
          Expanded(
            child: Padding(
              child: Slider(
                value: _currentSliderPosition,
                onChanged: (value) {
                  controller.seekTo(
                    Duration(
                      milliseconds:
                          (controller.value.duration.inMilliseconds * value)
                              .round(),
                    ),
                  );
                },
                activeColor: widget.liveUIColor,
                inactiveColor: Colors.transparent,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
            ),
          ),
          InkWell(
            onTap: () => controller.seekTo(controller.value.duration),
            child: Material(
              color: widget.liveUIColor,
              child: Text(
                " LIVE ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          FullScreenButton(),
        ],
      ),
    );
  }
}
