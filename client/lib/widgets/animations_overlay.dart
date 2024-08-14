import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:train_de_mots/widgets/bouncy_container.dart';

class AnimationOverlay extends StatefulWidget {
  const AnimationOverlay({super.key});

  @override
  State<AnimationOverlay> createState() => _AnimationOverlayState();
}

class _AnimationOverlayState extends State<AnimationOverlay> {
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
  final _allSolutionFoundController = BouncyContainerController(
      bounceCount: 5,
      easingInDuration: 300,
      bouncingDuration: 1000,
      easingOutDuration: 300,
      minScale: 0.8,
      bouncyScale: 1.2,
      maxScale: 1.3,
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

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onSolutionWasStolen.addListener(_showSolutionWasStolen);
    gm.onGoldenSolutionAppeared.addListener(_showNewGoldenSolutionAppeared);
    gm.onStealerPardoned.addListener(_showStealerWasPardoned);
    gm.onAllSolutionsFound.addListener(_showAllSolutionsFound);
    gm.onTrainGotBoosted.addListener(_showTrainGotBoosted);
  }

  @override
  void dispose() {
    _stolenController.dispose();
    _pardonedController.dispose();
    _newGoldenController.dispose();
    _allSolutionFoundController.dispose();
    _trainGotBoostedController.dispose();

    final gm = GameManager.instance;
    gm.onSolutionWasStolen.removeListener(_showSolutionWasStolen);
    gm.onGoldenSolutionAppeared.removeListener(_showNewGoldenSolutionAppeared);
    gm.onStealerPardoned.removeListener(_showStealerWasPardoned);
    gm.onAllSolutionsFound.removeListener(_showAllSolutionsFound);
    gm.onTrainGotBoosted.removeListener(_showTrainGotBoosted);

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

  void _showAllSolutionsFound() {
    _allSolutionFoundController.triggerAnimation(const _AllSolutionsFound());
  }

  void _showTrainGotBoosted(int boostRemaining) {
    _trainGotBoostedController
        .triggerAnimation(_TrainGotBoosted(boostRemaining: boostRemaining));
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
            child: BouncyContainer(controller: _allSolutionFoundController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.165,
            child: BouncyContainer(controller: _trainGotBoostedController),
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
            style: const TextStyle(
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
            style: TextStyle(
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
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: textColor, size: 32),
        ],
      ),
    );
  }
}

class _AllSolutionsFound extends StatelessWidget {
  const _AllSolutionsFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 32),
          SizedBox(width: 10),
          Text(
            'Toutes les solutions ont été trouvées!\n'
            'Un boost supplémentaire a été accordé!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 157, 243, 151)),
          ),
          SizedBox(width: 10),
          Icon(Icons.star, color: Colors.amber, size: 32),
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
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 157, 243, 151)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}
