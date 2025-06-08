import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class BluberryWarAnimatedTextOverlay extends StatefulWidget {
  const BluberryWarAnimatedTextOverlay({super.key});

  @override
  State<BluberryWarAnimatedTextOverlay> createState() =>
      _BluberryWarAnimatedTextOverlayState();
}

class _BluberryWarAnimatedTextOverlayState
    extends State<BluberryWarAnimatedTextOverlay> {
  final _blueberryWarWrongWordController = BouncyContainerController(
    bounceCount: 2,
    easingInDuration: 600,
    bouncingDuration: 1500,
    easingOutDuration: 300,
    minScale: 0.9,
    bouncyScale: 1.2,
    maxScale: 1.4,
    maxOpacity: 0.9,
  );
  final _blueberryWarFoundWordController = BouncyContainerController(
    bounceCount: 2,
    easingInDuration: 600,
    bouncingDuration: 1500,
    easingOutDuration: 300,
    minScale: 0.9,
    bouncyScale: 1.2,
    maxScale: 1.4,
    maxOpacity: 0.9,
  );
  final _blueberryWarFailedController = BouncyContainerController(
    bounceCount: 2,
    easingInDuration: 600,
    bouncingDuration: 1500,
    easingOutDuration: 300,
    minScale: 0.9,
    bouncyScale: 1.2,
    maxScale: 1.4,
    maxOpacity: 0.9,
  );

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onTrySolution.listen(_blueberryWarTrySolution);
    gm.onGameEnded.listen(_blueberryWarFailed);
  }

  @override
  void dispose() {
    final tgm = Managers.instance.miniGames.blueberryWar;
    tgm.onTrySolution.cancel(_blueberryWarTrySolution);
    tgm.onGameEnded.cancel(_blueberryWarFailed);

    super.dispose();
  }

  void _blueberryWarTrySolution(String sender, String word, bool isSuccess) {
    if (isSuccess) {
      _blueberryWarFoundWordController.triggerAnimation(
        _BlueberryWarFoundWord(sender, word),
      );
    } else {
      _blueberryWarWrongWordController.triggerAnimation(
        _BlueberryWarWrongWord(sender, word),
      );
    }
  }

  void _blueberryWarFailed(bool hasWin) {
    // Do not write anything if the game was won, as the try solution will
    if (hasWin) return;
    _blueberryWarFailedController.triggerAnimation(const _BlueberryWarFailed());
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
              controller: _blueberryWarWrongWordController,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(
              controller: _blueberryWarFoundWordController,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: BouncyContainer(controller: _blueberryWarFailedController),
          ),
        ],
      ),
    );
  }
}

class _BlueberryWarFoundWord extends StatelessWidget {
  const _BlueberryWarFoundWord(this.sender, this.word);

  final String sender;
  final String word;

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
            'Vous avez gagné!\n$sender a trouvé la solution!',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 157, 243, 151),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}

class _BlueberryWarWrongWord extends StatelessWidget {
  const _BlueberryWarWrongWord(this.sender, this.word);

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
            style: tm.clientMainTextStyle.copyWith(
              fontSize: 24,
              color: textColor,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _BlueberryWarFailed extends StatelessWidget {
  const _BlueberryWarFailed();

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
            'Vous n\'avez pas trouvé le mot à temps...\n'
            'On retourne immédiatement au train!',
            textAlign: TextAlign.center,
            style: tm.clientMainTextStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: textColor, size: 32),
        ],
      ),
    );
  }
}
