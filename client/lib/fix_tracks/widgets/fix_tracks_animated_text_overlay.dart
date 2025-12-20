import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class FixTracksAnimatedTextOverlay extends StatefulWidget {
  const FixTracksAnimatedTextOverlay({super.key});

  @override
  State<FixTracksAnimatedTextOverlay> createState() =>
      _FixTracksAnimatedTextOverlayState();
}

class _FixTracksAnimatedTextOverlayState
    extends State<FixTracksAnimatedTextOverlay> {
  final _fixTracksWrongWordController = BouncyContainerController(
      bounceCount: 1,
      easingInDuration: 600,
      bouncingDuration: 1400,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.1,
      maxScale: 1.2,
      maxOpacity: 0.9);
  final _fixTracksHasWonController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _fixTracksHasLostController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);

  @override
  void initState() {
    super.initState();

    final fgm = Managers.instance.miniGames.fixTracks;
    fgm.onTrySolution.listen(_fixTracksTrySolution);
    fgm.onGameEnded.listen(_fixTracksFailed);
  }

  @override
  void dispose() {
    final fgm = Managers.instance.miniGames.fixTracks;
    fgm.onTrySolution.cancel(_fixTracksTrySolution);
    fgm.onGameEnded.cancel(_fixTracksFailed);

    super.dispose();
  }

  void _fixTracksTrySolution({
    required String playerName,
    required String word,
    required FixTracksSolutionStatus solutionStatus,
    required int pointsAwarded,
  }) {
    switch (solutionStatus) {
      case FixTracksSolutionStatus.isValid:
      case FixTracksSolutionStatus.noMoreSegmentsToFix:
      case FixTracksSolutionStatus.unknown:
        return;
      case FixTracksSolutionStatus.hasMisplacedLetters:
      case FixTracksSolutionStatus.isNotTheRightLength:
      case FixTracksSolutionStatus.isAlreadyUsed:
      case FixTracksSolutionStatus.isNotInDictionary:
      case FixTracksSolutionStatus.wordIsTooShort:
        _fixTracksWrongWordController.triggerAnimation(
            _FixTracksWrongWord(playerName, word, solutionStatus));
        break;
    }
  }

  void _fixTracksFailed({required bool hasWon}) {
    if (hasWon) {
      _fixTracksHasWonController.triggerAnimation(_FixTracksHasWon());
    } else {
      _fixTracksHasLostController.triggerAnimation(const _FixTracksHasLost());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            child: BouncyContainer(controller: _fixTracksWrongWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _fixTracksHasWonController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _fixTracksHasLostController),
          ),
        ],
      ),
    );
  }
}

class _FixTracksWrongWord extends StatelessWidget {
  const _FixTracksWrongWord(this.playerName, this.word, this.solutionStatus);

  final String playerName;
  final String word;
  final FixTracksSolutionStatus solutionStatus;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    const textColor = Color.fromARGB(255, 243, 157, 151);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 23, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10),
          Text(
            switch (solutionStatus) {
              FixTracksSolutionStatus.hasMisplacedLetters =>
                '$word contient des lettres mal placées...',
              FixTracksSolutionStatus.isNotTheRightLength =>
                '$word n\'est pas de la bonne longueur...',
              FixTracksSolutionStatus.isAlreadyUsed =>
                '$word a déjà été utilisé...',
              FixTracksSolutionStatus.isNotInDictionary =>
                '$word n\'existe pas...',
              FixTracksSolutionStatus.wordIsTooShort =>
                '$word est trop court...',
              _ => '$word n\'est pas un mot valide...',
            },
            textAlign: TextAlign.center,
            style:
                tm.clientMainTextStyle.copyWith(fontSize: 24, color: textColor),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _FixTracksHasWon extends StatelessWidget {
  const _FixTracksHasWon();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 10),
          Text(
            'Vous avez réparé la voie!\n'
            'Le train peut continuer son chemin!',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 157, 243, 151)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}

class _FixTracksHasLost extends StatelessWidget {
  const _FixTracksHasLost();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    const textColor = Color.fromARGB(255, 243, 157, 151);
    final tmg = Managers.instance.miniGames.fixTracks;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 23, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: textColor, size: 32),
          const SizedBox(width: 10),
          Text(
            '${tmg.endGameStatus == EndGameStatus.lostOnDeadEnd ? 'Il n\'y a plus de mots valides possibles\n' : 'Vous n\'avez pas pu réparer la voie à temps!\n'}'
            'Votre chemin s\'arrête ici...',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: textColor, size: 32),
        ],
      ),
    );
  }
}
