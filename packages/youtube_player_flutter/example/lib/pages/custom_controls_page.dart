// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';

import '../widgets/custom_builder_demo.dart';

/// Demonstrates `YoutubePlayer.builder` with fully custom controls.
///
/// On its own page so the main page holds a single native player; this
/// page's player is released when it is popped.
class CustomControlsPage extends StatelessWidget {
  const CustomControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Controls'), centerTitle: true),
      body: Column(
        children: [
          const CustomBuilderDemo(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Built with YoutubePlayer.builder', style: tt.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'The builder receives the player surface and its '
                  'controller, and lays its own controls over it with a '
                  'Stack. The same builder runs in fullscreen, where the '
                  'player fills the screen.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
