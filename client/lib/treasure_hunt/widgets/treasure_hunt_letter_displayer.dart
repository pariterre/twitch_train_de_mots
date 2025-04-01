import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:common/treasure_hunt/treasure_hunt_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class TreasureHuntLetterDisplayer extends StatefulWidget {
  const TreasureHuntLetterDisplayer({super.key});

  @override
  State<TreasureHuntLetterDisplayer> createState() =>
      _TreasureHuntLetterDisplayerState();
}

class _TreasureHuntLetterDisplayerState
    extends State<TreasureHuntLetterDisplayer> {
  final List<FireworksController> _fireworksControllers = [];

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onGameStarted.listen(refresh);
    gm.onRewardFound.listen(_onRevealLetter);
    refresh();
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onGameStarted.cancel(refresh);
    gm.onRewardFound.cancel(_onRevealLetter);

    for (var e in _fireworksControllers) {
      e.dispose();
    }

    super.dispose();
  }

  void refresh() {
    _reinitializeFireworks();
    setState(() {});
  }

  void _onRevealLetter(Tile tile) {
    if (!tile.isLetter) return;

    _fireworksControllers[tile.letterIndex!].trigger();
    setState(() {});
  }

  void _reinitializeFireworks() {
    final gm = Managers.instance.miniGames.treasureHunt;
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
    final gm = Managers.instance.miniGames.treasureHunt;

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
