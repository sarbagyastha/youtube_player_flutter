/// Current state of the player. Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#Playback_status)
enum PlayerState {
  unknown,
  unStarted,
  ended,
  playing,
  paused,
  buffering,
  cued,
}
