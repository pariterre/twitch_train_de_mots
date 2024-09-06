import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GameScreen');

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _canPlayerPardon = false;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onGameStarted.addListener(_refresh);
    gm.onPardonnersChanged.addListener(_updatePlayersWhoCanPardon);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onGameStarted.removeListener(_refresh);
    gm.onPardonnersChanged.removeListener(_updatePlayersWhoCanPardon);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _updatePlayersWhoCanPardon(List<String> pardonners) {
    _logger.info('Update current pardonners to: $pardonners');
    final myId = TwitchManager.instance.opaqueUserId;
    _canPlayerPardon = pardonners.any((id) => id == myId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('My user ID: ${TwitchManager.instance.opaqueUserId}'),
        ElevatedButton(
          onPressed: _canPlayerPardon
              ? () => TwitchManager.instance.pardonStealer()
              : null,
          child: const Text('Pardon'),
        ),
      ],
    ));
  }
}
