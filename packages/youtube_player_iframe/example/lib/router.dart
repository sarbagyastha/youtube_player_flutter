// Copyright 2024 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe_example/pages/home_page.dart';
import 'package:youtube_player_iframe_example/pages/video_list_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePage(),
      routes: [
        GoRoute(
          path: 'playlist',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: VideoListPage()),
        ),
        GoRoute(
          path: 'watch',
          pageBuilder: (_, GoRouterState state) {
            return NoTransitionPage(
              child: HomePage(videoId: state.uri.queryParameters['v']),
            );
          },
        ),
      ],
    ),
  ],
);
