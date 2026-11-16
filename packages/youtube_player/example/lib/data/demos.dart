import 'package:material_ui/material_ui.dart';

import '../pages/custom_controls_page.dart';
import '../pages/elements_page.dart';
import '../pages/info_page.dart';
import '../pages/live_page.dart';
import '../pages/params_page.dart';
import '../pages/playback_page.dart';
import '../pages/player_list_page.dart';
import '../pages/playlist_page.dart';
import '../pages/spherical_page.dart';
import '../pages/thumbnails_page.dart';
import 'videos.dart';

/// One entry of the home gallery.
final class const Demo({
  required final String title,
  required final String description,
  required final IconData icon,
  required final String thumbnailId,
  required final WidgetBuilder builder,
  final String? badge,
  final Color? badgeColor,
});

/// Every demo, in gallery order.
final demos = <Demo>[
  Demo(
    title: 'Playback',
    description:
        'Play, pause, seek, skip, volume, speed, fullscreen and loading '
        'videos by URL.',
    icon: Icons.play_arrow_rounded,
    thumbnailId: videoIds[0],
    builder: (_) => const PlaybackPage(),
  ),
  Demo(
    title: 'Live stream',
    description: 'A 24/7 live stream with a live badge and jump to live edge.',
    icon: Icons.sensors,
    thumbnailId: liveVideoId,
    badge: 'LIVE',
    badgeColor: const Color(0xFFE62117),
    builder: (_) => const LivePage(),
  ),
  Demo(
    title: '360° video',
    description:
        'Pan, tilt, roll and zoom a spherical video from Flutter. Android '
        'and Chromium browsers.',
    icon: Icons.threesixty,
    thumbnailId: sphericalVideoId,
    badge: '360°',
    builder: (_) => const SphericalPage(),
  ),
  Demo(
    title: 'Playlists',
    description:
        'Video id lists and YouTube playlists, with a queue, loop and '
        'shuffle.',
    icon: Icons.playlist_play_rounded,
    thumbnailId: videoIds[4],
    builder: (_) => const PlaylistPage(),
  ),
  Demo(
    title: 'Custom controls',
    description:
        'Replace YouTube\'s controls with a Flutter overlay via '
        'controlsBuilder.',
    icon: Icons.tune,
    thumbnailId: videoIds[2],
    builder: (_) => const CustomControlsPage(),
  ),
  Demo(
    title: 'Player elements',
    description:
        'Hide YouTube\'s own UI elements and decide what clicks on them do.',
    icon: Icons.visibility_outlined,
    thumbnailId: videoIds[3],
    badge: 'Android · iOS · macOS',
    builder: (_) => const ElementsPage(),
  ),
  Demo(
    title: 'Player parameters',
    description:
        'Try every YoutubePlayerParams option and copy the resulting code.',
    icon: Icons.settings_suggest_outlined,
    thumbnailId: videoIds[5],
    builder: (_) => const ParamsPage(),
  ),
  Demo(
    title: 'Info & events',
    description:
        'Video data, embed code, captions, modules, errors and a live event '
        'log.',
    icon: Icons.data_object,
    thumbnailId: videoIds[1],
    builder: (_) => const InfoPage(),
  ),
  Demo(
    title: 'Players in a list',
    description:
        'Many players in a scroll view; each autoplays once it is half '
        'visible.',
    icon: Icons.view_agenda_outlined,
    thumbnailId: videoIds[6],
    builder: (_) => const PlayerListPage(),
  ),
  Demo(
    title: 'Thumbnails',
    description: 'Every thumbnail quality and format from getThumbnail.',
    icon: Icons.image_outlined,
    thumbnailId: videoIds[7],
    builder: (_) => const ThumbnailsPage(),
  ),
];
