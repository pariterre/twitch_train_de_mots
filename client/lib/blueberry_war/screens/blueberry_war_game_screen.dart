import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_animated_text_overlay.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_header.dart';
import 'package:train_de_mots/generic/managers/game_round_manager.dart';
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

    Managers.instance.tickerManager.onClockTicked.listen(_clockTicked);
  }

  // Dispose
  @override
  void dispose() {
    Managers.instance.tickerManager.onClockTicked.cancel(_clockTicked);

    super.dispose();
  }

  void _clockTicked(Duration deltaTime) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bwm = Managers.instance.miniGames.blueberryWar;

    return Stack(
      children: [
        Column(
          children: [
            const BlueberryWarHeader(),
            Expanded(
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha(50), BlendMode.srcIn),
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  backgroundBlendMode: BlendMode.dstOut),
                              width: BlueberryWarConfig.fieldSize.x,
                              height: BlueberryWarConfig.fieldSize.y,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: BlueberryWarPlayingField(
                          blueberries: bwm.blueberries,
                          letters: bwm.letters,
                          isRoundInProgress:
                              bwm.roundStatus == GameRoundStatus.inProgress,
                          clockTicker:
                              Managers.instance.tickerManager.onClockTicked,
                          onBlueberrySlingShoot: (blueberry, newVelocity) {
                            bwm.slingShoot(
                                blueberry: blueberry, newVelocity: newVelocity);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const BlueberryWarAnimatedTextOverlay(),
      ],
    );
  }
}
