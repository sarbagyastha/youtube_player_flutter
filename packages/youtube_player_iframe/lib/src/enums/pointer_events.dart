/// An enum for the set of pointer-events available to be passed in to `player.html`
enum PointerEvents {
  /// An enum for `pointer-events: auto`
  auto,

  /// An enum for `pointer-events: none`
  none,

  /// An enum for `pointer-events: inherit`
  inherit,

  /// An enum for `pointer-events: initial`
  initial,

  /// An enum for `pointer-events: revert`
  revert,

  /// An enum for `pointer-events: unset`
  unset,

  /// An enum for `pointer-events: revertLayer`
  revertLayer,
}

/// Function to get the string value of the pointer event based on the enum provided
String getPointerEvent(PointerEvents event) {
  switch (event) {
    case (PointerEvents.auto):
      {
        return 'auto';
      }
    case (PointerEvents.none):
      {
        return 'none';
      }
    case (PointerEvents.inherit):
      {
        return 'inherit';
      }
    case (PointerEvents.initial):
      {
        return 'initial';
      }
    case (PointerEvents.revert):
      {
        return 'revert';
      }
    case (PointerEvents.unset):
      {
        return 'unset';
      }
    case (PointerEvents.revertLayer):
      {
        return 'revert-layer';
      }
    default:
      return 'auto';
  }
}
