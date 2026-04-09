import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class WarehouseCleaningAnimatedTextOverlay extends StatefulWidget {
  const WarehouseCleaningAnimatedTextOverlay({super.key});

  @override
  State<WarehouseCleaningAnimatedTextOverlay> createState() =>
      _WarehouseCleaningAnimatedTextOverlayState();
}

class _WarehouseCleaningAnimatedTextOverlayState
    extends State<WarehouseCleaningAnimatedTextOverlay> {
  final _warehouseCleaningWrongWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _warehouseCleaningFoundWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _warehouseCleaningFailedController = BouncyContainerController(
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

    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onTrySolution.listen(_warehouseCleaningTrySolution);
    whgm.onGameEnded.listen(_warehouseCleaningFailed);
  }

  @override
  void dispose() {
    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onTrySolution.cancel(_warehouseCleaningTrySolution);
    whgm.onGameEnded.cancel(_warehouseCleaningFailed);

    super.dispose();
  }

  void _warehouseCleaningTrySolution(
      {required String playerName,
      required String word,
      required bool isSolutionRight,
      required int pointsAwarded}) {
    if (isSolutionRight) {
      _warehouseCleaningFoundWordController.triggerAnimation(
          _WarehouseCleaningFoundWord(playerName, word, pointsAwarded));
    } else {
      _warehouseCleaningWrongWordController
          .triggerAnimation(_WarehouseCleaningWrongWord(playerName, word));
    }
  }

  void _warehouseCleaningFailed({required bool hasWon}) {
    // Do not write anything if the game was won, as the try solution will
    if (hasWon) return;
    _warehouseCleaningFailedController
        .triggerAnimation(const _WarehouseCleaningFailed());
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
            child: BouncyContainer(
                controller: _warehouseCleaningWrongWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(
                controller: _warehouseCleaningFoundWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child:
                BouncyContainer(controller: _warehouseCleaningFailedController),
          ),
        ],
      ),
    );
  }
}

class _WarehouseCleaningFoundWord extends StatelessWidget {
  const _WarehouseCleaningFoundWord(this.sender, this.word, this.wordValue);

  final String sender;
  final String word;
  final int wordValue;

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
            'Vous avez gagné!\n'
            '$sender a trouvé la solution, et\n'
            'remporte $wordValue points!',
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

class _WarehouseCleaningWrongWord extends StatelessWidget {
  const _WarehouseCleaningWrongWord(this.sender, this.word);

  final String sender;
  final String word;

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
            '$sender a proposé $word\nMais ce n\'est pas la solution',
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

class _WarehouseCleaningFailed extends StatelessWidget {
  const _WarehouseCleaningFailed();

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
            '${Managers.instance.miniGames.warehouseCleaning.timeRemaining.inSeconds <= 0 ? 'Vous n\'avez pas trouvé le mot à temps...\n' : 'Vous avez épuisez vos essais...\n'}'
            'On retourne immédiatement au train!',
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
