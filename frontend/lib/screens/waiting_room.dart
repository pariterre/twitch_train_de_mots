import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/screens/game_screen.dart';

class WaitingRoom extends StatelessWidget {
  const WaitingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train de mots!'),
      ),
      body: FutureBuilder(
          future: TwitchManager.instance.onFinishedInitializing,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return const GameScreen();
          }),
    );
  }
}
