import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
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
    ref
        .read(gameManagerProvider)
        .onScrablingLetters
        .addListener(_onScrablingLetters);
  }

  @override
  void dispose() {
    ref
        .read(gameManagerProvider)
        .onScrablingLetters
        .removeListener(_onScrablingLetters);
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

class _Letter extends ConsumerWidget {
  const _Letter({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(schemeProvider);
    final letterWidget = Letter(letter);

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
              scheme.letterColorLight,
              scheme.letterColorDark,
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
                  color: scheme.textColor,
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
                  style: TextStyle(color: scheme.textColor, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
