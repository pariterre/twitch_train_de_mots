import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';

class FixTracksHeader extends StatefulWidget {
  const FixTracksHeader({super.key});

  @override
  State<FixTracksHeader> createState() => _FixTracksHeaderState();
}

class _FixTracksHeaderState extends State<FixTracksHeader> {
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.fixTracks;
    gm.onRoundInitialized.listen(_onGameStarted);
    gm.onTrySolution.listen(_onSolutionTried);

    Managers.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    Managers.instance.tickerManager.onClockTicked.cancel(_onClockTicked);
    final gm = Managers.instance.miniGames.fixTracks;
    gm.onRoundInitialized.cancel(_onGameStarted);
    gm.onTrySolution.cancel(_onSolutionTried);

    super.dispose();
  }

  void _onGameStarted() {
    setState(() {});
  }

  void _onClockTicked(Duration deltaTime) {
    final timeRemaining =
        Managers.instance.miniGames.fixTracks.timeRemaining ?? Duration.zero;
    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  void _onSolutionTried(
      {required String playerName,
      required String word,
      required FixTracksSolutionStatus solutionStatus,
      required int pointsAwarded}) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final nextSegment =
        Managers.instance.miniGames.fixTracks.grid.nextEmptySegment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 75.0),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemeCard(
              child: Text(
                'Temps restant: ${Managers.instance.miniGames.fixTracks.timeRemaining?.inSeconds ?? 0}',
                style: tm.clientMainTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: tm.textColor),
              ),
            ),
            ThemeCard(
              child: Text(
                nextSegment == null
                    ? 'Au bout du rail!'
                    : 'Prochain mot: ${nextSegment.length} lettres',
                style: tm.clientMainTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: tm.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
