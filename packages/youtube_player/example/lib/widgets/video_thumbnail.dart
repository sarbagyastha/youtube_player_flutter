import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// A rounded YouTube thumbnail, built with
/// [YoutubePlayerController.getThumbnail].
class const VideoThumbnail(
  final String videoId, {
  super.key,
  final ThumbnailQuality quality = .medium,
  final ThumbnailFormat format = .jpeg,
  final double radius = 12,
  final bool selected = false,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        position: .foreground,
        decoration: BoxDecoration(
          borderRadius: .circular(radius),
          border: selected ? Border.all(color: scheme.primary, width: 3) : null,
        ),
        child: ClipRRect(
          borderRadius: .circular(radius),
          child: Material(
            color: scheme.surfaceContainerHighest,
            child: Ink.image(
              image: NetworkImage(
                YoutubePlayerController.getThumbnail(
                  videoId: videoId,
                  quality: quality,
                  format: format,
                ),
              ),
              fit: .cover,
              onImageError: (_, _) {},
              child: InkWell(onTap: onTap),
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal strip of tappable thumbnails.
class const VideoStrip({
  super.key,
  required final List<String> videoIds,
  required final ValueChanged<int> onSelected,
  final int? selectedIndex,
  final double height = 90,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: .horizontal,
      itemCount: videoIds.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => VideoThumbnail(
        videoIds[i],
        selected: i == selectedIndex,
        onTap: () => onSelected(i),
      ),
    ),
  );
}
