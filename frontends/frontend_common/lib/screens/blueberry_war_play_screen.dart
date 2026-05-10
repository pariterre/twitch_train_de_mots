import 'dart:math';

import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
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
    final mgm = gm.miniGameState as SerializableBlueberryWarGameState;
    final twitchManager = TwitchManager.instance;
    const headerHeight = 70.0;

    return Stack(
      children: [
        const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(height: headerHeight, child: _Header())),
        ColorFiltered(
            colorFilter:
                ColorFilter.mode(Colors.black.withAlpha(50), BlendMode.srcIn),
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  children: [
                    Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            backgroundBlendMode: BlendMode.dstOut),
                        height: headerHeight),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              backgroundBlendMode: BlendMode.dstOut),
                          width: BlueberryWarConfig.blueberryFieldSize.x,
                          height: BlueberryWarConfig.fieldSize.y,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        Center(
          child: Column(
            children: [
              Container(height: headerHeight),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BlueberryWarPlayingField(
                    blueberries: mgm.blueberries,
                    letters: mgm.letters,
                    isRoundInProgress: mgm.roundTimer.status ==
                        ControllableTimerStatus.inProgress,
                    clockTicker: gm.tickerManager.onClockTicked,
                    onBlueberrySlingShoot: (blueberry, newVelocity) {
                      twitchManager.slingShootBlueberry(
                          blueberry: blueberry, requestedVelocity: newVelocity);
                    },
                    drawBlueberryFieldOnly: true,
                  ),
                ),
              ),
            ],
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
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_refresh);

    gm.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);
    gm.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onClockTicked(Duration deltaTime) {
    if (!mounted) return;

    final mgm =
        GameManager.instance.miniGameState as SerializableBlueberryWarGameState;

    final timeRemaining = mgm.roundTimer.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgm =
        GameManager.instance.miniGameState as SerializableBlueberryWarGameState;
    final tm = ThemeManager.instance;

    return LayoutBuilder(builder: (context, constraints) {
      final time = max((mgm.roundTimer.timeRemaining?.inSeconds ?? -1) + 1, 0);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Temps restant $time',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05)),
          const SizedBox(width: 20),
        ],
      );
    });
  }
}
