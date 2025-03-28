import 'package:common/widgets/fireworks.dart';
import 'package:common/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/managers.dart';

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

    final gm = Managers.instance.train;
    gm.onScrablingLetters.addListener(_refresh);
    gm.onRevealUselessLetter.addListener(_onRevealUselessLetter);
    gm.onRevealHiddenLetter.addListener(_onRevealHiddenLetter);
    gm.onRoundStarted.addListener(_onRoundStarted);

    final tm = Managers.instance.theme;
    tm.onChanged.addListener(_refresh);

    _reinitializeFireworks();
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onScrablingLetters.removeListener(_refresh);
    gm.onRevealUselessLetter.removeListener(_onRevealUselessLetter);
    gm.onRevealHiddenLetter.removeListener(_onRevealHiddenLetter);
    gm.onRoundStarted.removeListener(_onRoundStarted);

    final tm = Managers.instance.theme;
    tm.onChanged.removeListener(_refresh);

    for (var e in _fireworksControllers) {
      e.dispose();
    }

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _onRoundStarted() {
    _reinitializeFireworks();
    setState(() {});
  }

  void _onRevealUselessLetter() {
    final gm = Managers.instance.train;
    final uselessIndex = gm.uselessLetterIndex;
    _fireworksControllers[uselessIndex].trigger();
    setState(() {});
  }

  void _onRevealHiddenLetter() {
    final gm = Managers.instance.train;
    final hiddenIndex = gm.hiddenLetterIndex;
    _fireworksControllers[hiddenIndex].trigger();
    setState(() {});
  }

  void _reinitializeFireworks() {
    final gm = Managers.instance.train;
    if (gm.problem == null) return;

    _fireworksControllers.clear();
    final letters = gm.problem!.letters;
    for (final _ in letters) {
      _fireworksControllers.add(FireworksController(
        minColor: const Color.fromARGB(184, 0, 100, 200),
        maxColor: const Color.fromARGB(184, 100, 120, 255),
      ));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;

    if (gm.problem == null) return Container();
    final problem = gm.simplifiedProblem!;

    return SizedBox(
      width: LetterDisplayerCommon.baseWidth(problem.letters.length),
      child: LetterDisplayerCommon(
        letterProblem: problem,
        letterBuilder: (index) =>
            Fireworks(controller: _fireworksControllers[index]),
      ),
    );
  }
}
