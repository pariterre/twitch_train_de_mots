import 'package:common/widgets/fireworks.dart';
import 'package:common/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/treasure_hunt/managers/treasure_hunt_game_manager.dart';
import 'package:train_de_mots/treasure_hunt/models/tile.dart';

class LetterDisplayer extends StatefulWidget {
  const LetterDisplayer({super.key});

  @override
  State<LetterDisplayer> createState() => _LetterDisplayerState();
}

class _LetterDisplayerState extends State<LetterDisplayer> {
  final List<FireworksController> _fireworksControllers = [];

  @override
  void initState() {
    super.initState();

    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.listen(refresh);
    gm.onRewardFound.listen(_onRevealHiddenLetter);
    refresh();
  }

  @override
  void dispose() {
    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.cancel(refresh);
    gm.onRewardFound.cancel(_onRevealHiddenLetter);

    for (var e in _fireworksControllers) {
      e.dispose();
    }

    super.dispose();
  }

  void refresh() {
    _reinitializeFireworks();
    setState(() {});
  }

  void _onRevealHiddenLetter(Tile tile) {
    if (!tile.hasLetter) return;

    final gm = TreasureHuntGameManager.instance;
    final index = gm.getLetterIndex(tile.index);
    _fireworksControllers[index].trigger();
    setState(() {});
  }

  void _reinitializeFireworks() {
    final gm = TreasureHuntGameManager.instance;
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
    final gm = TreasureHuntGameManager.instance;

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
