import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_animated_text_overlay.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_header.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

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
    final tm = ThemeManager.instance;
    final twitchManager = Managers.instance.twitch;
    final headerHeight = 180.0;

    return twitchManager.isNotConnected
        ? Center(child: CircularProgressIndicator(color: tm.mainColor))
        : twitchManager.debugOverlay(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: headerHeight,
                    child: const BlueberryWarHeader(),
                  ),
                ),
                Positioned(
                  top: headerHeight,
                  left: MediaQuery.of(context).size.width / 5,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - headerHeight,
                    child: VerticalDivider(
                      thickness: 2,
                      endIndent: 10,
                      color: Colors.white.withAlpha(100),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    children: [
                      SizedBox(height: headerHeight),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bwm =
                                Managers.instance.miniGames.blueberryWar;
                            bwm.fieldSize = vector_math.Vector2(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );

                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: BlueberryWarPlayingField(
                                players: bwm.players,
                                letters: bwm.letters,
                                isGameOver: bwm.isGameOver,
                                clockTicker: bwm.onClockTicked,
                                onPlayerSlingShoot: (player, newVelocity) {
                                  bwm.slingShoot(
                                      player: player, newVelocity: newVelocity);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const BluberryWarAnimatedTextOverlay(),
              ],
            ),
          );
  }
}
