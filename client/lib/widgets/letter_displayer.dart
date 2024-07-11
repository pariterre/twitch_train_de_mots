import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/valuable_letter.dart';
import 'package:train_de_mots/widgets/fireworks.dart';

double _letterWidth = 80;
double _letterHeight = 90;
double _letterPadding = 4;

double _letterSize = 46;
double _numberSize = 26;

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

    final gm = GameManager.instance;
    gm.onScrablingLetters.addListener(_refresh);
    gm.onRevealUselessLetter.addListener(_onRevealUselessLetter);
    gm.onRevealHiddenLetter.addListener(_onRevealHiddenLetter);
    gm.onRoundStarted.addListener(_onRoundStarted);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);

    _reinitializeFireworks();
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onScrablingLetters.removeListener(_refresh);
    gm.onRevealUselessLetter.removeListener(_onRevealUselessLetter);
    gm.onRevealHiddenLetter.removeListener(_onRevealHiddenLetter);
    gm.onRoundStarted.removeListener(_onRoundStarted);

    final tm = ThemeManager.instance;
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
    final gm = GameManager.instance;
    final uselessIndex = gm.uselessLetterIndex;
    _fireworksControllers[uselessIndex].trigger();
    setState(() {});
  }

  void _onRevealHiddenLetter() {
    final gm = GameManager.instance;
    final hiddenIndex = gm.hiddenLetterIndex;
    _fireworksControllers[hiddenIndex].trigger();
    setState(() {});
  }

  void _reinitializeFireworks() {
    final gm = GameManager.instance;
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
    final gm = GameManager.instance;

    if (gm.problem == null) return Container();

    final letters = gm.problem!.letters;
    final scrambleIndices = gm.problem!.scrambleIndices;

    final displayerWidth =
        _letterWidth * letters.length + 2 * _letterPadding * (letters.length);

    final revealedUselessIndex =
        gm.isUselessLetterRevealed ? gm.uselessLetterIndex : -1;
    final hiddenIndex = gm.hasHiddenLetter ? gm.hiddenLetterIndex : -1;

    return SizedBox(
      width: displayerWidth,
      height: _letterHeight * 1.2,
      child: Stack(alignment: Alignment.center, children: [
        for (var index in letters.asMap().keys)
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left:
                  (_letterWidth + 2 * _letterPadding) * scrambleIndices[index],
              child: _Letter(
                letter: letters[index],
                uselessIsRevealed: index == revealedUselessIndex,
                isHidden: index == hiddenIndex,
              )),
        for (var index in letters.asMap().keys)
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left:
                  (_letterWidth + 2 * _letterPadding) * scrambleIndices[index],
              child: SizedBox(
                width: _letterWidth,
                height: _letterHeight,
                child: Fireworks(controller: _fireworksControllers[index]),
              )),
      ]),
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({
    required this.letter,
    required this.uselessIsRevealed,
    required this.isHidden,
  });

  final String letter;
  final bool uselessIsRevealed;
  final bool isHidden;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final valuableLetter = ValuableLetter(widget.letter);

    // Create a letter that ressemble those on a Scrabble board
    return Card(
      elevation: 5,
      child: Container(
        width: _letterWidth,
        height: _letterHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.uselessIsRevealed
                ? [tm.uselessLetterColorLight, tm.uselessLetterColorDark]
                : widget.isHidden
                    ? [tm.hiddenLetterColorLight, tm.hiddenLetterColorDark]
                    : [tm.letterColorLight, tm.letterColorDark],
            stops: const [0, 0.4],
          ),
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: widget.isHidden
            ? null
            : Stack(
                children: [
                  Center(
                    child: Text(
                      valuableLetter.data,
                      style: TextStyle(
                        color: tm.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: _letterSize,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0, right: 4.0),
                      child: Text(
                        valuableLetter.value.toString(),
                        style: TextStyle(
                            color: tm.textColor, fontSize: _numberSize),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
