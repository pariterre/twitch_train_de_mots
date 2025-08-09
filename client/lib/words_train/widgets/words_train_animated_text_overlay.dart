import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

class WordsTrainAnimatedTextOverlay extends StatefulWidget {
  const WordsTrainAnimatedTextOverlay({super.key});

  @override
  State<WordsTrainAnimatedTextOverlay> createState() =>
      _WordsTrainAnimatedTextOverlayState();
}

class _WordsTrainAnimatedTextOverlayState
    extends State<WordsTrainAnimatedTextOverlay> {
  // Words train messages
  final _stolenController = BouncyContainerController(
      minScale: 0.5, bouncyScale: 1.4, maxScale: 1.5, maxOpacity: 0.9);
  final _pardonedController = BouncyContainerController(
      bounceCount: 1,
      easingInDuration: 700,
      bouncingDuration: 3000,
      easingOutDuration: 300,
      minScale: 0.5,
      bouncyScale: 1.4,
      maxScale: 1.5,
      maxOpacity: 0.9);
  final _newGoldenController = BouncyContainerController(
      bounceCount: 1,
      easingInDuration: 1000,
      bouncingDuration: 3000,
      easingOutDuration: 1000,
      minScale: 0.5,
      bouncyScale: 1.0,
      maxScale: 1.1,
      maxOpacity: 0.9);
  final _miniGameGrantedController = BouncyContainerController(
      bounceCount: 5,
      easingInDuration: 300,
      bouncingDuration: 1000,
      easingOutDuration: 300,
      minScale: 0.8,
      bouncyScale: 1.2,
      maxScale: 1.3,
      maxOpacity: 0.9);
  final _newBoostGrantedController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _trainGotBoostedController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _bigHeistSuccessController = BouncyContainerController(
      bounceCount: 4,
      easingInDuration: 600,
      bouncingDuration: 1000,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.1,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _bigHeistFailedController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 4000,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.1,
      maxScale: 1.2,
      maxOpacity: 0.9);
  final _changeLaneController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1000,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onSolutionWasStolen.listen(_showSolutionWasStolen);
    gm.onGoldenSolutionAppeared.listen(_showNewGoldenSolutionAppeared);
    gm.onStealerPardoned.listen(_showStealerWasPardoned);
    gm.onMiniGameGranted.listen(_showGoToMinigame);
    gm.onNewBoostGranted.listen(_showNewBoostGranted);
    gm.onTrainGotBoosted.listen(_showTrainGotBoosted);
    gm.onBigHeistSuccess.listen(_showBigHeistSuccess);
    gm.onBigHeistFailed.listen(_showBigHeistFailed);
    gm.onChangingLane.listen(_showChangeLane);
  }

  @override
  void dispose() {
    _stolenController.dispose();
    _pardonedController.dispose();
    _newGoldenController.dispose();
    _miniGameGrantedController.dispose();
    _newBoostGrantedController.dispose();
    _trainGotBoostedController.dispose();
    _bigHeistSuccessController.dispose();
    _bigHeistFailedController.dispose();
    _changeLaneController.dispose();

    final gm = Managers.instance.train;
    gm.onSolutionWasStolen.cancel(_showSolutionWasStolen);
    gm.onGoldenSolutionAppeared.cancel(_showNewGoldenSolutionAppeared);
    gm.onStealerPardoned.cancel(_showStealerWasPardoned);
    gm.onMiniGameGranted.cancel(_showGoToMinigame);
    gm.onNewBoostGranted.cancel(_showNewBoostGranted);
    gm.onTrainGotBoosted.cancel(_showTrainGotBoosted);
    gm.onBigHeistSuccess.cancel(_showBigHeistSuccess);
    gm.onBigHeistFailed.cancel(_showBigHeistFailed);
    gm.onChangingLane.cancel(_showChangeLane);

    super.dispose();
  }

  void _showSolutionWasStolen(WordSolution solution) {
    _stolenController.triggerAnimation(_ASolutionWasStolen(solution: solution));
  }

  void _showNewGoldenSolutionAppeared(WordSolution solution) {
    _newGoldenController.triggerAnimation(const _ANewGoldenSolutionAppeared());
  }

  void _showStealerWasPardoned(WordSolution? solution) {
    _pardonedController
        .triggerAnimation(_AStealerWasPardoned(solution: solution));
  }

  void _showGoToMinigame(MiniGames miniGame) {
    _miniGameGrantedController
        .triggerAnimation(_MiniGameGranted(miniGame: miniGame));
  }

  void _showNewBoostGranted() {
    _newBoostGrantedController.triggerAnimation(_NewBoostGranted());
  }

  void _showTrainGotBoosted(int boostRemaining) {
    _trainGotBoostedController
        .triggerAnimation(_TrainGotBoosted(boostRemaining: boostRemaining));
  }

  void _showBigHeistSuccess() {
    _bigHeistSuccessController.triggerAnimation(const _BigHeistSuccess());
  }

  void _showBigHeistFailed() {
    _bigHeistFailedController.triggerAnimation(const _BigHeistFailed());
  }

  void _showChangeLane() {
    _changeLaneController.triggerAnimation(const _ChangeLane());
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
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _stolenController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.165,
            child: BouncyContainer(controller: _pardonedController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
            child: BouncyContainer(controller: _newGoldenController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            child: BouncyContainer(controller: _miniGameGrantedController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.165,
            child: BouncyContainer(controller: _newBoostGrantedController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.165,
            child: BouncyContainer(controller: _trainGotBoostedController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _bigHeistSuccessController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _bigHeistFailedController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
            child: BouncyContainer(controller: _changeLaneController),
          ),
        ],
      ),
    );
  }
}

class _ASolutionWasStolen extends StatelessWidget {
  const _ASolutionWasStolen({required this.solution});

  final WordSolution solution;

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
          const Icon(Icons.star, color: textColor, size: 32),
          const SizedBox(width: 10),
          Text(
            '${solution.foundBy.name} a volé le mot de ${solution.stolenFrom.name}',
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

class _ANewGoldenSolutionAppeared extends StatelessWidget {
  const _ANewGoldenSolutionAppeared();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(
        color: tm.solutionIsGoldenDark,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 10),
          Text(
            'Une étoile au Nord apparaît\n'
            'Attrapez-la pour multiplier vos points!',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tm.solutionIsGoldenLight),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}

class _AStealerWasPardoned extends StatelessWidget {
  const _AStealerWasPardoned({required this.solution});

  final WordSolution? solution;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    const textColor = Color.fromARGB(255, 237, 243, 151);

    late final String text;
    if (solution == null) {
      text = 'Il n\'y a aucun vol à pardonner!';
    } else {
      if (solution!.isStolen) {
        text = 'Seul ${solution!.stolenFrom.name} peut pardonner le vol...';
      } else {
        text = 'Le joueur ${solution!.foundBy.name} a été pardonné de son vol!';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 91, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: textColor, size: 32),
          const SizedBox(width: 10),
          Text(
            text,
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

class _MiniGameGranted extends StatelessWidget {
  const _MiniGameGranted({required this.miniGame});

  final MiniGames miniGame;

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
            'Bravo cheminot\u00b7e\u00b7s! Votre efficacité vous laisse le temps de relaxer un peu!\n'
            '${switch (miniGame) {
              MiniGames.blueberryWar =>
                'Affûtez vos armes, la guerre des bleuets est lancée!',
              MiniGames.treasureHunt =>
                'Partez à la grande cueillette de bleuets!',
            }}',
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

class _NewBoostGranted extends StatelessWidget {
  const _NewBoostGranted();

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
            'Vous avez trouvé du charbon ultra-performant!\n'
            'Utilisez-le pour booster le Petit Train du Nord!',
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

class _TrainGotBoosted extends StatelessWidget {
  const _TrainGotBoosted({required this.boostRemaining});

  final int boostRemaining;

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
            boostRemaining > 0
                ? 'Plus que $boostRemaining boost${boostRemaining > 1 ? 's' : ''} avant la prochaine accélération!'
                : 'Le Petit Train du Nord file à toute vitesse!',
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

class _BigHeistSuccess extends StatelessWidget {
  const _BigHeistSuccess();

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
            'Vous avez braqué le train avec succès!\n'
            'Le Petit Train de Nord s\'envole pour 6 stations!',
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

class _BigHeistFailed extends StatelessWidget {
  const _BigHeistFailed();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

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
            'Vous vous êtes faits prendre en plein braquage\n'
            'Votre voyage au Nord s\'arrête maintenant...',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 243, 157, 151)),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ChangeLane extends StatelessWidget {
  const _ChangeLane();

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
            'Changement de voie! Accrochez-vous!',
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
