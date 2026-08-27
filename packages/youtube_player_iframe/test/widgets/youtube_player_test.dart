import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/src/widgets/player_loading_overlay.dart'
    show shouldShowPlayerLoadingOverlay;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  group('shouldShowPlayerLoadingOverlay', () {
    test('shows while the player is initializing without an error', () {
      expect(shouldShowPlayerLoadingOverlay(YoutubePlayerValue()), isTrue);
      expect(
        shouldShowPlayerLoadingOverlay(
          YoutubePlayerValue(playerState: PlayerState.unStarted),
        ),
        isTrue,
      );
    });

    test('hides when initialization fails', () {
      expect(
        shouldShowPlayerLoadingOverlay(
          YoutubePlayerValue(error: YoutubeError.videoNotFound),
        ),
        isFalse,
      );
      expect(
        shouldShowPlayerLoadingOverlay(
          YoutubePlayerValue(
            playerState: PlayerState.unStarted,
            error: YoutubeError.notEmbeddable,
          ),
        ),
        isFalse,
      );
    });

    test('hides after initialization completes', () {
      expect(
        shouldShowPlayerLoadingOverlay(
          YoutubePlayerValue(playerState: PlayerState.cued),
        ),
        isFalse,
      );
      expect(
        shouldShowPlayerLoadingOverlay(
          YoutubePlayerValue(playerState: PlayerState.playing),
        ),
        isFalse,
      );
    });
  });
}
