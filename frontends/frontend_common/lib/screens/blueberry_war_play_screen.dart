import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';

class BlueberryWarPlayScreen extends StatefulWidget {
  const BlueberryWarPlayScreen({super.key});

  @override
  State<BlueberryWarPlayScreen> createState() => _BlueberryWarPlayScreenState();
}

class _BlueberryWarPlayScreenState extends State<BlueberryWarPlayScreen> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_onMiniGameStateUpdated);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_onMiniGameStateUpdated);
    super.dispose();
  }

  void _onMiniGameStateUpdated() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final thm = gm.miniGameState as SerializableBlueberryWarGameState;
    final twitchManager = TwitchManager.instance;

    return Column(
      children: [
        const Center(child: _Header()),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: BlueberryWarGameManagerHelpers.playerFieldSize.x,
                height: BlueberryWarGameManagerHelpers.playerFieldSize.y,
                child: BlueberryWarFieldAgentsOverlay(
                  players: thm.players,
                  letters: thm.letters,
                  isGameOver: thm.isOver,
                  clockTicker: gm.onGameTicked,
                  onPlayerSlingShoot: (player, newVelocity) {
                    twitchManager.slingShootPlayerAgent(
                        player: player, requestedVelocity: newVelocity);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(refresh);

    super.dispose();
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final thm =
        GameManager.instance.miniGameState as SerializableBlueberryWarGameState;
    final tm = ThemeManager.instance;

    return LayoutBuilder(builder: (context, constraints) {
      return thm.timeRemaining.inSeconds > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Temps restant ${thm.timeRemaining.inSeconds}',
                    style: tm.textFrontendSc
                        .copyWith(fontSize: constraints.maxWidth * 0.05)),
                const SizedBox(width: 20),
              ],
            )
          : Text('Retournons à la gare!',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05));
    });
  }
}
