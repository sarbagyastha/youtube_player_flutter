// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

///
class VolumeSlider extends StatefulWidget {
  ///
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  int? _volume;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initVolume();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Volume',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        Expanded(
          child: Slider(
            value: _volume?.toDouble() ?? 100,
            min: 0.0,
            max: 100.0,
            divisions: 10,
            label: '$_volume',
            onChanged: (value) {
              _volume = value.round();
              setState(() {});

              context.ytController.setVolume(_volume!);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _initVolume() async {
    _volume ??= await context.ytController.volume;
  }
}
