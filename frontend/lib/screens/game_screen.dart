import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GameScreen');

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _currentPlayerCanPardon = false;

  @override
  void initState() {
    super.initState();

    TwitchManager.instance.onPardonStatusUpdate
        .startListening(_updatePlayersWhoCanPardon);
  }

  @override
  void dispose() {
    TwitchManager.instance.onPardonStatusUpdate
        .stopListening(_updatePlayersWhoCanPardon);

    super.dispose();
  }

  void _updatePlayersWhoCanPardon(List<String> userIds) {
    _logger.info('Update current pardonners to: $userIds');
    final myId = TwitchManager.instance.opaqueUserId;
    _currentPlayerCanPardon = userIds.any((id) => id == myId);
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
          onPressed: _currentPlayerCanPardon
              ? () => TwitchManager.instance.pardonStealer()
              : null,
          child: const Text('Pardon'),
        ),
      ],
    ));
  }
}
