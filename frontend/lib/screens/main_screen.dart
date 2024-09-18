import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/screens/play_screen.dart';
import 'package:frontend/screens/waiting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_refresh);
    gm.onRoundEnded.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_refresh);
    gm.onRoundEnded.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (TwitchManager.instance is TwitchManagerMock) ? 320 : null,
      height: (TwitchManager.instance is TwitchManagerMock) ? 300 : null,
      child: Background(
        backgroundLayer: Image.asset(
          'assets/images/train.png',
          height: MediaQuery.of(context).size.height,
          opacity: const AlwaysStoppedAnimation(0.05),
          fit: BoxFit.cover,
        ),
        child: GameManager.instance.isRoundRunning
            ? const PlayScreen()
            : const WaitingScreen(),
      ),
    );
  }
}
