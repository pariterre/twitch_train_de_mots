import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class TreasureHuntAnimatedTextOverlay extends StatefulWidget {
  const TreasureHuntAnimatedTextOverlay({super.key});

  @override
  State<TreasureHuntAnimatedTextOverlay> createState() =>
      _TreasureHuntAnimatedTextOverlayState();
}

class _TreasureHuntAnimatedTextOverlayState
    extends State<TreasureHuntAnimatedTextOverlay> {
  final _treasureHuntWrongWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _treasureHuntFoundWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _treasureHuntFailedController = BouncyContainerController(
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

    final tgm = Managers.instance.miniGames.treasureHunt;
    tgm.onTrySolution.listen(_treasureHuntTrySolution);
    tgm.onGameEnded.listen(_treasureHuntFailed);
  }

  @override
  void dispose() {
    final tgm = Managers.instance.miniGames.treasureHunt;
    tgm.onTrySolution.cancel(_treasureHuntTrySolution);
    tgm.onGameEnded.cancel(_treasureHuntFailed);

    super.dispose();
  }

  void _treasureHuntTrySolution(
      String sender, String word, bool isSuccess, int wordValue) {
    if (isSuccess) {
      _treasureHuntFoundWordController
          .triggerAnimation(_TreasureHuntFoundWord(sender, word, wordValue));
    } else {
      _treasureHuntWrongWordController
          .triggerAnimation(_TreasureHuntWrongWord(sender, word));
    }
  }

  void _treasureHuntFailed({required bool hasWon}) {
    // Do not write anything if the game was won, as the try solution will
    if (hasWon) return;
    _treasureHuntFailedController.triggerAnimation(const _TreasureHuntFailed());
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
            child:
                BouncyContainer(controller: _treasureHuntWrongWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child:
                BouncyContainer(controller: _treasureHuntFoundWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _treasureHuntFailedController),
          ),
        ],
      ),
    );
  }
}

class _TreasureHuntFoundWord extends StatelessWidget {
  const _TreasureHuntFoundWord(this.sender, this.word, this.wordValue);

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

class _TreasureHuntWrongWord extends StatelessWidget {
  const _TreasureHuntWrongWord(this.sender, this.word);

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

class _TreasureHuntFailed extends StatelessWidget {
  const _TreasureHuntFailed();

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
            '${Managers.instance.miniGames.treasureHunt.timeRemaining.inSeconds <= 0 ? 'Vous n\'avez pas trouvé le mot à temps...\n' : 'Vous avez épuisez vos essais...\n'}'
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
