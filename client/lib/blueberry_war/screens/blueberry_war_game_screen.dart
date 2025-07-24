import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_animated_text_overlay.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_header.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class BlueberryWarGameScreen extends StatefulWidget {
  const BlueberryWarGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<BlueberryWarGameScreen> createState() => _BlueberryWarGameScreenState();
}

class _BlueberryWarGameScreenState extends State<BlueberryWarGameScreen> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.listen(_clockTicked);
  }

  // Dispose
  @override
  void dispose() {
    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.cancel(_clockTicked);

    super.dispose();
  }

  void _clockTicked() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bwm = Managers.instance.miniGames.blueberryWar;
    final headerHeight = 180.0;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: headerHeight,
            child: const BlueberryWarHeader(),
          ),
        ),
        ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.black.withAlpha(50), BlendMode.srcIn),
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                children: [
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          backgroundBlendMode: BlendMode.dstOut),
                      height: headerHeight),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            backgroundBlendMode: BlendMode.dstOut),
                        child: SizedBox(
                          width: BlueberryWarGameManagerHelpers.fieldSize.x,
                          height: BlueberryWarGameManagerHelpers.fieldSize.y,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            children: [
              Container(height: headerHeight),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BlueberryWarPlayingField(
                    players: bwm.players,
                    letters: bwm.letters,
                    isGameOver: bwm.isGameOver,
                    clockTicker: bwm.onClockTicked,
                    onPlayerSlingShoot: (player, newVelocity) {
                      bwm.slingShoot(player: player, newVelocity: newVelocity);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const BluberryWarAnimatedTextOverlay(),
      ],
    );
  }
}
