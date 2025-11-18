import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class TrackFixAnimatedTextOverlay extends StatefulWidget {
  const TrackFixAnimatedTextOverlay({super.key});

  @override
  State<TrackFixAnimatedTextOverlay> createState() =>
      _TrackFixAnimatedTextOverlayState();
}

class _TrackFixAnimatedTextOverlayState
    extends State<TrackFixAnimatedTextOverlay> {
  final _trackFixWrongWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _trackFixFoundWordController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _trackFixFailedController = BouncyContainerController(
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

    final fgm = Managers.instance.miniGames.trackFix;
    fgm.onTrySolution.listen(_trackFixTrySolution);
    fgm.onGameEnded.listen(_trackFixFailed);
  }

  @override
  void dispose() {
    final fgm = Managers.instance.miniGames.trackFix;
    fgm.onTrySolution.cancel(_trackFixTrySolution);
    fgm.onGameEnded.cancel(_trackFixFailed);

    super.dispose();
  }

  void _trackFixTrySolution(
      String sender, String word, bool isSuccess, int wordValue) {
    if (isSuccess) {
      _trackFixFoundWordController
          .triggerAnimation(_TrackFixFoundWord(sender, word, wordValue));
    } else {
      _trackFixWrongWordController
          .triggerAnimation(_TrackFixWrongWord(sender, word));
    }
  }

  void _trackFixFailed(bool hasWin) {
    // Do not write anything if the game was won, as the try solution will
    if (hasWin) return;
    _trackFixFailedController.triggerAnimation(const _TrackFixFailed());
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
            child: BouncyContainer(controller: _trackFixWrongWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _trackFixFoundWordController),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _trackFixFailedController),
          ),
        ],
      ),
    );
  }
}

class _TrackFixFoundWord extends StatelessWidget {
  const _TrackFixFoundWord(this.sender, this.word, this.wordValue);

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

class _TrackFixWrongWord extends StatelessWidget {
  const _TrackFixWrongWord(this.sender, this.word);

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

class _TrackFixFailed extends StatelessWidget {
  const _TrackFixFailed();

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
            '${Managers.instance.miniGames.trackFix.timeRemaining.inSeconds <= 0 ? 'Vous n\'avez pas trouvé le mot à temps...\n' : 'Vous avez épuisez vos essais...\n'}'
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
