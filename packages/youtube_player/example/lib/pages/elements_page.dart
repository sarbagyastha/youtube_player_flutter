import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/event_log.dart';
import '../widgets/section_card.dart';

/// The player's top bar, as an element beyond the built-in ones.
const _topBar = PlayerElement.custom('.ytp-chrome-top');

/// Hides YouTube's own UI elements and decides what clicks on them do.
class const ElementsPage({super.key}) extends StatefulWidget {
  @override
  State<ElementsPage> createState() => _ElementsPageState();
}

class _ElementsPageState extends State<ElementsPage> {
  /// Names of the elements whose clicks are blocked.
  final _blocked = <String>{
    PlayerElement.youtubeLogo.name,
    PlayerElement.channel.name,
  };
  final _log = ValueNotifier<List<LogEntry>>(const []);

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    final blocked = _blocked.contains(request.element.name);
    final message =
        '${blocked ? 'blocked' : 'allowed'} ${request.element.name}'
        '${request.uri == null ? '' : ' → ${request.uri}'}';
    _log.value = [..._log.value, (time: DateTime.now(), message: message)];
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    return blocked ? .prevent : .navigate;
  }

  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Player elements',
    create: () => YoutubePlayerController.fromVideoId(
      videoId: videoIds[3],
      params: const YoutubePlayerParams(customElements: {_topBar}),
      elementVisibility: (element) => element != PlayerElement.watchLaterButton,
      onNavigationRequest: _onNavigation,
    ),
    children: [
      SectionCard(
        title: 'Elements',
        icon: Icons.visibility_outlined,
        note:
            'Switch: shown or hidden. Block: clicks are prevented. '
            'Android, iOS and macOS only. YouTube\'s terms restrict hiding '
            'branding.',
        child: _ElementList(
          blocked: _blocked,
          onBlock: (name, block) => setState(
            () => block ? _blocked.add(name) : _blocked.remove(name),
          ),
        ),
      ),
      SectionCard(
        title: 'Click log',
        icon: Icons.ads_click,
        note: 'Click the title, channel, logo or a related video.',
        child: ValueListenableBuilder(
          valueListenable: _log,
          builder: (_, entries, _) => LogView(entries),
        ),
      ),
    ],
  );
}

class const _ElementList({
  required final Set<String> blocked,
  required final void Function(String name, bool block) onBlock,
}) extends StatefulWidget {
  @override
  State<_ElementList> createState() => _ElementListState();
}

class _ElementListState extends State<_ElementList> {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return Column(
      children: [
        for (final element in [...PlayerElement.values, _topBar])
          ListTile(
            dense: true,
            title: Text(
              element == _topBar ? 'custom: top bar' : element.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Row(
              mainAxisSize: .min,
              children: [
                FilterChip(
                  label: const Text('Block'),
                  avatar: widget.blocked.contains(element.name)
                      ? const Icon(Icons.block, size: 16)
                      : null,
                  selected: widget.blocked.contains(element.name),
                  onSelected: (block) => widget.onBlock(element.name, block),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: controller.isElementVisible(element),
                  onChanged: (visible) => setState(
                    () => controller.setElementVisible(element, visible),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
