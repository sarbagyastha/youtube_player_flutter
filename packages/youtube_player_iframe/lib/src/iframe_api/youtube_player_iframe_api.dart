import 'package:youtube_player_iframe/src/iframe_api/src/functions/video_information.dart';

import 'src/functions/queueing_functions.dart';

export 'src/functions/queueing_functions.dart' show ListType;

abstract class YoutubePlayerIFrameAPI
    implements QueueingFunctions, VideoInformation {}
