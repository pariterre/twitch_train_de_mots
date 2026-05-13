import 'dart:math';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/widgets/warehouse_cleaning_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';

class WarehouseCleaningPlayScreen extends StatelessWidget {
  const WarehouseCleaningPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: _Header(),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: const _AvatarField(),
              ),
            ),
          ),
        ],
      ),
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
    GameManager.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);
    GameManager.instance.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onClockTicked(Duration deltaTime) {
    if (!mounted) return;

    final mgm = GameManager.instance.miniGameState;
    final timeRemaining = mgm.roundTimer.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgm = GameManager.instance.miniGameState
        as SerializableWarehouseCleaningGameState;
    final tm = ThemeManager.instance;

    if (mgm.triesRemaining <= 0) {
      return Text('Vous avez épuisé vos essais!', style: tm.textFrontendSc);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final time = max((mgm.roundTimer.timeRemaining?.inSeconds ?? -1) + 1, 0);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temps restant $time',
                  style: tm.textFrontendSc
                      .copyWith(fontSize: constraints.maxWidth * 0.05)),
              const SizedBox(width: 20),
              Text('Essais restants ${mgm.triesRemaining}',
                  style: tm.textFrontendSc
                      .copyWith(fontSize: constraints.maxWidth * 0.05)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: constraints.maxWidth,
              child: const _LetterDisplayer(),
            ),
          ),
        ],
      );
    });
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
    final mgm = GameManager.instance.miniGameState
        as SerializableWarehouseCleaningGameState;
    return LetterDisplayerCommon(letterProblem: mgm.problem);
  }
}

class _AvatarField extends StatefulWidget {
  const _AvatarField();

  @override
  State<_AvatarField> createState() => _AvatarFieldState();
}

class _AvatarFieldState extends State<_AvatarField> {
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
    final mgm = GameManager.instance.miniGameState
        as SerializableWarehouseCleaningGameState;
    final twitchManager = TwitchManager.instance;

    return WarehouseCleaningGameGrid(
      rowCount: mgm.grid.rowCount,
      columnCount: mgm.grid.columnCount,
      getTileAt: mgm.grid.tileAt,
      avatars: mgm.avatars,
      boxes: mgm.boxes,
      letters: mgm.letters,
      isRoundInProgress: gm.status == WordsTrainGameStatus.roundStarted,
      clockTicker: gm.tickerManager.onClockTicked,
      onAvatarSlingShot: (avatar, newVelocity) {
        twitchManager.slingShotAvatarWareHouse(
            avatar: avatar, requestedVelocity: newVelocity);
      },
    );
  }
}
