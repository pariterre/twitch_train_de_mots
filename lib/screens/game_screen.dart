import 'package:flutter/material.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/models/word_manipulation.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
import 'package:train_de_mots/widgets/word_displayer.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _hasWord = false;

  Future<Solution> _pickANewWord() async {
    _hasWord = false;
    String candidate;
    Set<String> subWords;
    debugPrint('Starting to find a new word');
    do {
      candidate = randomLetters(minLetters: 9, maxLetters: 9);
      subWords = await WordManipulation.instance.findsWords(
          from: candidate,
          nbLetters: 4,
          wordsCountLimit: Configuration.instance.maximumWordsNumber);
    } while (subWords.length < Configuration.instance.minimumWordsNumber ||
        subWords.length > Configuration.instance.maximumWordsNumber);

    debugPrint('Found a new word: $candidate');
    _hasWord = true;
    return Solution(word: candidate, solutions: subWords.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<Solution>(
                future: _pickANewWord(),
                builder: (context, snapshot) {
                  if (!_hasWord) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WordDisplayer(word: snapshot.data!.word),
                      const SizedBox(height: 20),
                      SolutionsDisplayer(solutions: snapshot.data!.solutions),
                    ],
                  );
                }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('New word'),
          )
        ],
      ),
    );
  }
}
