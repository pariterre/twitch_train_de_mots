import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';

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

  void _updatePlayersWhoCanPardon(List<int> userIds) {
    final currentUserId = TwitchManager.instance.obfucatedUserId;
    _currentPlayerCanPardon = userIds.any((id) => id == currentUserId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('My user ID: ${TwitchManager.instance.obfucatedUserId}'),
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
