// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'enums.dart';
import 'types.dart';

/// An event pushed by the player.
///
/// Mirrors the IFrame API events, plus [TickEvent] which the plugin emits
/// while the media clock advances.
sealed class const PlayerEvent() {
  /// Decodes the compact wire form `{e: name, d: data}` used by the native
  /// player page. Returns `null` for unknown events (forward compatibility).
  static PlayerEvent? fromWire(String name, Object? data) => switch ((
    name,
    data,
  )) {
    ('ready', _) => const ReadyEvent(),
    ('state', final Map<Object?, Object?> d) => StateChangeEvent.fromWire(d),
    ('rate', final num rate) => PlaybackRateChangeEvent(rate.toDouble()),
    ('quality', final String quality) => PlaybackQualityChangeEvent(quality),
    ('error', final int code) => ErrorEvent(.fromCode(code)),
    ('api', _) => const ApiChangeEvent(),
    ('autoplayBlocked', _) => const AutoplayBlockedEvent(),
    ('tick', final List<Object?> d) => TickEvent.fromWire(d),
    ('loadError', final String description) => LoadErrorEvent(
      YoutubeLoadError(description: description),
    ),
    _ => null,
  };
}

/// `onReady`: the player accepts API calls from now on.
final class const ReadyEvent() extends PlayerEvent;

/// `onStateChange`, enriched with best-effort video info and duration.
final class const StateChangeEvent(
  /// The new state.
  final PlayerState state, {

  /// Video info, sent on `unstarted`, `cued` and `playing`.
  final VideoData? videoData,

  /// Duration in seconds, when known.
  final double? duration,
}) extends PlayerEvent {
  /// Decodes `{s, v?, du?}`.
  factory StateChangeEvent.fromWire(Map<Object?, Object?> d) =>
      StateChangeEvent(
        .fromCode((d['s'] as num?)?.toInt() ?? -2),
        videoData: switch (d['v']) {
          final Map<Object?, Object?> v => .fromWire(v),
          _ => null,
        },
        duration: (d['du'] as num?)?.toDouble(),
      );
}

/// `onPlaybackRateChange`.
final class const PlaybackRateChangeEvent(
  /// The new rate.
  final double rate,
) extends PlayerEvent;

/// `onPlaybackQualityChange` (informational; quality cannot be set).
final class const PlaybackQualityChangeEvent(
  /// e.g. `hd720`.
  final String quality,
) extends PlayerEvent;

/// `onError`.
final class const ErrorEvent(
  /// The error.
  final YoutubeError error,
) extends PlayerEvent;

/// `onApiChange`: a module (e.g. captions) loaded or unloaded.
final class const ApiChangeEvent() extends PlayerEvent;

/// `onAutoplayBlocked`: the platform refused scripted or automatic playback.
final class const AutoplayBlockedEvent() extends PlayerEvent;

/// The page or the IFrame API script failed to load.
final class const LoadErrorEvent(
  /// Details.
  final YoutubeLoadError error,
) extends PlayerEvent;

/// Periodic progress while playing or buffering, plus one final tick when the
/// clock stops and after seeks / volume changes.
final class const TickEvent({
  /// Seconds elapsed.
  required final double currentTime,

  /// Buffered fraction, `0..1`.
  required final double loadedFraction,

  /// Duration in seconds (grows for live streams).
  required final double duration,

  /// Volume `0..100` (reported even when muted).
  required final int volume,

  /// Whether the player is muted.
  required final bool muted,
}) extends PlayerEvent {
  /// Decodes `[currentTime, loadedFraction, duration, volume, muted]`.
  factory TickEvent.fromWire(List<Object?> d) => TickEvent(
    currentTime: _num(d, 0),
    loadedFraction: _num(d, 1),
    duration: _num(d, 2),
    volume: _num(d, 3).round(),
    muted: _num(d, 4) != 0,
  );

  static double _num(List<Object?> d, int i) =>
      i < d.length ? (d[i] as num?)?.toDouble() ?? 0 : 0;
}
