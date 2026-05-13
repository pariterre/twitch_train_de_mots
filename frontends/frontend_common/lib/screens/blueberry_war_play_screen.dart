import 'dart:math';

import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';

class BlueberryWarPlayScreen extends StatelessWidget {
  const BlueberryWarPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(alignment: Alignment.topCenter, child: _Header()),
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
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              backgroundBlendMode: BlendMode.dstOut),
                          width: BlueberryWarConfig.blueberryFieldSize.x,
                          height: BlueberryWarConfig.fieldSize.y,
                        ),
                      ),
                    ),
                  )),
              const Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _BlueberryField(),
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

      return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temps restant $time',
                  style: tm.textFrontendSc
                      .copyWith(fontSize: constraints.maxWidth * 0.05)),
              const SizedBox(width: 20),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: SizedBox(
                width: constraints.maxWidth, child: const _LetterDisplayer()),
          ),
        ],
      );
    });
  }
}

class _BlueberryField extends StatefulWidget {
  const _BlueberryField();

  @override
  State<_BlueberryField> createState() => _BlueberryFieldState();
}

class _BlueberryFieldState extends State<_BlueberryField> {
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

    return BlueberryWarPlayingField(
      blueberries: mgm.blueberries,
      letters: mgm.letters,
      isRoundInProgress:
          mgm.roundTimer.status == ControllableTimerStatus.inProgress,
      clockTicker: gm.tickerManager.onClockTicked,
      onBlueberrySlingShot: (blueberry, newVelocity) {
        twitchManager.slingShotBlueberryWar(
            blueberry: blueberry, requestedVelocity: newVelocity);
      },
      drawBlueberryFieldOnly: true,
    );
  }
}

class _LetterDisplayer extends StatefulWidget {
  const _LetterDisplayer();

  @override
  State<_LetterDisplayer> createState() => _LetterDisplayerState();
}

class _LetterDisplayerState extends State<_LetterDisplayer> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final mgm =
        GameManager.instance.miniGameState as SerializableBlueberryWarGameState;
    return LetterDisplayerCommon(letterProblem: mgm.problem);
  }
}
