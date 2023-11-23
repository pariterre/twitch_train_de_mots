import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';
import 'package:train_de_mots/models/letter.dart';

class WordDisplayer extends StatefulWidget {
  const WordDisplayer({super.key, required this.word});

  final String word;

  @override
  State<WordDisplayer> createState() => _WordDisplayerState();
}

class _WordDisplayerState extends State<WordDisplayer> {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var letter in widget.word.split('').map<Letter>((e) => Letter(e)))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _Letter(letter: letter),
        ),
    ]);
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter});

  final Letter letter;

  @override
  Widget build(BuildContext context) {
    // Create a letter that ressemble those on a Scrabble board
    return Card(
      elevation: 5,
      child: Container(
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CustomColorScheme.instance.letterColorLight,
              CustomColorScheme.instance.letterColorDark,
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
                letter.data,
                style: TextStyle(
                  color: CustomColorScheme.instance.textColor,
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
                  letter.value.toString(),
                  style: TextStyle(
                      color: CustomColorScheme.instance.textColor,
                      fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
