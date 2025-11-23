import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/track_fix/managers/track_fix_game_manager.dart';

class TrackFixHeader extends StatefulWidget {
  const TrackFixHeader({super.key});

  @override
  State<TrackFixHeader> createState() => _TrackFixHeaderState();
}

class _TrackFixHeaderState extends State<TrackFixHeader> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.trackFix;
    gm.onGameStarted.listen(_onGameStarted);
    gm.onClockTicked.listen(_onClockTicked);
    gm.onTrySolution.listen(_onSolutionTried);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.trackFix;
    gm.onGameStarted.cancel(_onGameStarted);
    gm.onClockTicked.cancel(_onClockTicked);
    gm.onTrySolution.cancel(_onSolutionTried);

    super.dispose();
  }

  void _onGameStarted() {
    setState(() {});
  }

  void _onClockTicked(Duration timeRemaining) {
    setState(() {});
  }

  void _onSolutionTried(
      {required String playerName,
      required String word,
      required TrackFixSolutionStatus solutionStatus,
      required int pointsAwarded}) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final nextSegment =
        Managers.instance.miniGames.trackFix.grid.nextEmptySegment;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeCard(
          child: Text(
            'Temps restant: ${Managers.instance.miniGames.trackFix.timeRemaining.inSeconds}',
            style: tm.clientMainTextStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
          ),
        ),
        ThemeCard(
          child: Text(
            nextSegment == null
                ? 'Au bout du rail!'
                : 'Prochain mot: ${nextSegment.length} lettres',
            style: tm.clientMainTextStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
          ),
        ),
      ],
    );
  }
}
