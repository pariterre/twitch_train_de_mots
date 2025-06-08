import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class BlueberryWarLetterDisplayer extends StatefulWidget {
  const BlueberryWarLetterDisplayer({super.key});

  @override
  State<BlueberryWarLetterDisplayer> createState() =>
      _BlueberryWarLetterDisplayerState();
}

class _BlueberryWarLetterDisplayerState
    extends State<BlueberryWarLetterDisplayer> {
  final List<FireworksController> _fireworksControllers = [];

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onGameIsReady.listen(refresh);
    refresh();
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onGameIsReady.cancel(refresh);

    for (var e in _fireworksControllers) {
      e.dispose();
    }

    super.dispose();
  }

  void refresh() {
    _reinitializeFireworks();
    setState(() {});
  }

  void _reinitializeFireworks() {
    final gm = Managers.instance.miniGames.blueberryWar;
    if (gm.letters.isEmpty) return;

    _fireworksControllers.clear();
    for (final _ in gm.letters) {
      _fireworksControllers.add(FireworksController(
        minColor: const Color.fromARGB(184, 0, 100, 200),
        maxColor: const Color.fromARGB(184, 100, 120, 255),
      ));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.blueberryWar;

    if (gm.letters.isEmpty) return Container();

    return SizedBox(
      width: LetterDisplayerCommon.baseWidth(gm.letters.length),
      child: LetterDisplayerCommon(
        letterProblem: gm.problem,
        letterBuilder: (index) =>
            Fireworks(controller: _fireworksControllers[index]),
      ),
    );
  }
}
