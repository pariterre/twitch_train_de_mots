import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/widgets/bouncy_container.dart';

class AnimationOverlay extends ConsumerStatefulWidget {
  const AnimationOverlay({super.key});

  @override
  ConsumerState<AnimationOverlay> createState() => _AnimationOverlayState();
}

class _AnimationOverlayState extends ConsumerState<AnimationOverlay> {
  final _solutionStolenController = BouncyContainerController(
    minScale: 0.5,
    bouncyScale: 1.4,
    maxScale: 1.5,
    maxOpacity: 0.9,
  );

  @override
  void initState() {
    super.initState();
    ref
        .read(gameManagerProvider)
        .onSolutionWasStolen
        .addListener(_showSolutionWasStolen);
  }

  @override
  void dispose() {
    _solutionStolenController.dispose();
    ref
        .read(gameManagerProvider)
        .onSolutionWasStolen
        .removeListener(_showSolutionWasStolen);
    super.dispose();
  }

  void _showSolutionWasStolen(Solution solution) {
    _solutionStolenController
        .triggerAnimation(_ASolutionWasStolen(solution: solution));
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

  final Solution solution;

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
