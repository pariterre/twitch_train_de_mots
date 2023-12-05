import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/letter.dart';
import 'package:train_de_mots/models/word_problem.dart';

double _letterWidth = 60;
double _letterHeight = 70;
double _letterPadding = 4;

class WordDisplayer extends ConsumerStatefulWidget {
  const WordDisplayer({super.key, required this.problem});

  final WordProblem problem;

  @override
  ConsumerState<WordDisplayer> createState() => _WordDisplayerState();
}

class _WordDisplayerState extends ConsumerState<WordDisplayer> {
  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
    gm.onScrablingLetters.addListener(_onScrablingLetters);
  }

  @override
  void dispose() {
    final gm = ref.read(gameManagerProvider);
    gm.onScrablingLetters.removeListener(_onScrablingLetters);

    super.dispose();
  }

  void _onScrablingLetters() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final word = widget.problem.word;
    final scrambleIndices = widget.problem.scrambleIndices;

    final displayerWidth =
        _letterWidth * word.length + 2 * _letterPadding * (word.length);

    return SizedBox(
      width: displayerWidth,
      height: _letterHeight * 1.2,
      child: Stack(alignment: Alignment.center, children: [
        for (var index in word.split('').asMap().keys)
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left:
                  (_letterWidth + 2 * _letterPadding) * scrambleIndices[index],
              child: _Letter(letter: word[index])),
      ]),
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({required this.letter});

  final String letter;

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
    final letterWidget = Letter(widget.letter);

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
            colors: [
              tm.letterColorLight,
              tm.letterColorDark,
            ],
            stops: const [0, 0.4],
          ),
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                letterWidget.data,
                style: TextStyle(
                  color: tm.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0, right: 4.0),
                child: Text(
                  letterWidget.value.toString(),
                  style: TextStyle(color: tm.textColor, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
