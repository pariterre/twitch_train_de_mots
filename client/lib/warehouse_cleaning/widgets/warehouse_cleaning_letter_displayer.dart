import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class WarehouseCleaningLetterDisplayer extends StatefulWidget {
  const WarehouseCleaningLetterDisplayer({super.key});

  @override
  State<WarehouseCleaningLetterDisplayer> createState() =>
      _WarehouseCleaningLetterDisplayerState();
}

class _WarehouseCleaningLetterDisplayerState
    extends State<WarehouseCleaningLetterDisplayer> {
  final List<FireworksController> _fireworksControllers = [];

  @override
  void initState() {
    super.initState();

    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onGameStarted.listen(refresh);
    whgm.onLetterFound.listen(_onRevealLetter);
    refresh();
  }

  @override
  void dispose() {
    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onGameStarted.cancel(refresh);
    whgm.onLetterFound.cancel(_onRevealLetter);

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
    final whgm = Managers.instance.miniGames.warehouseCleaning;
    if (whgm.letters.isEmpty) return;

    _fireworksControllers.clear();
    for (final _ in whgm.letters) {
      _fireworksControllers.add(FireworksController(
        minColor: const Color.fromARGB(184, 0, 100, 200),
        maxColor: const Color.fromARGB(184, 100, 120, 255),
      ));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final whgm = Managers.instance.miniGames.warehouseCleaning;

    if (whgm.letters.isEmpty) return Container();

    return SizedBox(
      width: LetterDisplayerCommon.baseWidth(whgm.letters.length),
      child: LetterDisplayerCommon(
        letterProblem: whgm.problem,
        letterBuilder: (index) =>
            Fireworks(controller: _fireworksControllers[index]),
      ),
    );
  }
}
