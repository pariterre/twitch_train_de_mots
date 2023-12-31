import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/valuable_letter.dart';

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
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onScrablingLetters.addListener(_refresh);
    gm.onRoundStarted.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onScrablingLetters.removeListener(_refresh);
    gm.onRoundStarted.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    if (gm.problem == null) {
      return Center(child: CircularProgressIndicator(color: tm.mainColor));
    }

    final letters = gm.problem!.letters;
    final scrambleIndices = gm.problem!.scrambleIndices;

    final displayerWidth =
        _letterWidth * letters.length + 2 * _letterPadding * (letters.length);

    final hiddenIndex = gm.hiddenLetterIndex;

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
                  letter: letters[index], isHidden: index == hiddenIndex)),
      ]),
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({required this.letter, required this.isHidden});

  final String letter;
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
            colors: widget.isHidden
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
