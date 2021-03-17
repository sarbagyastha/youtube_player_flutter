import 'package:youtube_player_iframe/youtube_player_iframe.dart';

///
String youtubeIFrameTag(YoutubePlayerController controller) {
  final params = <String, String>{
    'autoplay': _boolean(controller.params.autoPlay),
    'mute': _boolean(controller.params.mute),
    'controls': _boolean(controller.params.showControls),
    'playsinline': _boolean(controller.params.playsInline),
    'enablejsapi': _boolean(controller.params.enableJavaScript),
    'fs': _boolean(controller.params.showFullscreenButton),
    'rel': _boolean(!controller.params.strictRelatedVideos),
    'showinfo': '0',
    'iv_load_policy': '${controller.params.showVideoAnnotations ? 1 : 3}',
    'modestbranding': '1',
    'cc_load_policy': _boolean(controller.params.enableCaption),
    'cc_lang_pref': controller.params.captionLanguage,
    'start': '${controller.params.startAt.inSeconds}',
    if (controller.params.endAt != null)
      'end': '${controller.params.endAt!.inSeconds}',
    'disablekb': _boolean(!controller.params.enableKeyboard),
    'color': controller.params.color,
    'hl': controller.params.interfaceLanguage,
    'loop': _boolean(controller.params.loop),
    if (controller.params.playlist.isNotEmpty)
      'playlist': '${controller.params.playlist.join(',')}'
  };
  final youtubeAuthority = controller.params.privacyEnhanced
      ? 'www.youtube-nocookie.com'
      : 'www.youtube.com';
  final sourceUri = Uri.https(
    youtubeAuthority,
    'embed/${controller.initialVideoId}',
    params,
  );
  return '<iframe id="player" type="text/html"'
      ' style="position:absolute; top:0px; left:0px; bottom:0px; right:10px;'
      ' width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999;"'
      ' src="$sourceUri" frameborder="0" allowfullscreen></iframe>';
}

///
String get youtubeIFrameFunctions => '''
function play() {
  player.playVideo();
  return '';
}
function pause() {
  player.pauseVideo();
  return '';
}
function loadById(loadSettings) {
  player.loadVideoById(loadSettings);
  return '';
}
function cueById(cueSettings) {
  player.cueVideoById(cueSettings);
  return '';
}
function loadPlaylist(loadSettings) {
  player.loadPlaylist(loadSettings);
  return '';
}
function cuePlaylist(loadSettings) {
  player.cuePlaylist(loadSettings);
  return '';
}
function mute() {
  player.mute();
  return '';
}
function unMute() {
  player.unMute();
  return '';
}
function setVolume(volume) {
  player.setVolume(volume);
  return '';
}
function seekTo(position, seekAhead) {
  player.seekTo(position, seekAhead);
  return '';
}
function setSize(width, height) {
  player.setSize(width, height);
  return '';
}
function setPlaybackRate(rate) {
  player.setPlaybackRate(rate);
  return '';
}
function setLoop(loopPlaylists) {
  player.setLoop(loopPlaylists);
  return '';
}
function setShuffle(shufflePlaylist) {
  player.setShuffle(shufflePlaylist);
  return '';
}
function previous() {
  player.previousVideo();
  return '';
}
function next() {
  player.nextVideo();
  return '';
}
function playVideoAt(index) {
  player.playVideoAt(index);
  return '';
}
function stop() {
  player.stopVideo();
  return '';
}
function isMuted() {
  return player.isMuted();
}
function hideTopMenu() {
  try { document.querySelector('#player').contentDocument.querySelector('.ytp-chrome-top').style.display = 'none'; } catch(e) { }
  return '';
}
function hidePauseOverlay() {
  try { document.querySelector('#player').contentDocument.querySelector('.ytp-pause-overlay').style.display = 'none'; } catch(e) { }
  return '';
}
''';

///
String get initPlayerIFrame => '''
var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
''';

String _boolean(bool value) => value ? '1' : '0';
