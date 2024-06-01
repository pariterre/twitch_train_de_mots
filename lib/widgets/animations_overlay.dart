import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:train_de_mots/widgets/bouncy_container.dart';

class AnimationOverlay extends StatefulWidget {
  const AnimationOverlay({super.key});

  @override
  State<AnimationOverlay> createState() => _AnimationOverlayState();
}

class _AnimationOverlayState extends State<AnimationOverlay> {
  final _solutionStolenController = BouncyContainerController(
    minScale: 0.5,
    bouncyScale: 1.4,
    maxScale: 1.5,
    maxOpacity: 0.9,
  );

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onSolutionWasStolen.addListener(_showSolutionWasStolen);
    gm.onStealerPardonned.addListener(_showStealerWasPardonned);
  }

  @override
  void dispose() {
    _solutionStolenController.dispose();

    final gm = GameManager.instance;
    gm.onSolutionWasStolen.removeListener(_showSolutionWasStolen);
    gm.onStealerPardonned.removeListener(_showStealerWasPardonned);

    super.dispose();
  }

  void _showSolutionWasStolen(WordSolution solution) {
    _solutionStolenController
        .triggerAnimation(_ASolutionWasStolen(solution: solution));
  }

  void _showStealerWasPardonned(WordSolution solution) {
    _solutionStolenController
        .triggerAnimation(_AStealerWasPardonned(solution: solution));
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
            top: MediaQuery.of(context).size.height * 0.19,
            child: BouncyContainer(controller: _solutionStolenController),
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

class _AStealerWasPardonned extends StatelessWidget {
  const _AStealerWasPardonned({required this.solution});

  final WordSolution solution;

  @override
  Widget build(BuildContext context) {
    const textColor = Color.fromARGB(255, 157, 243, 151);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: textColor, size: 32),
          const SizedBox(width: 10),
          Text(
            'Le joueur ${solution.foundBy.name} a été pardonné de son vol!',
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
