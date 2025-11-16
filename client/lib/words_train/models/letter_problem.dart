import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/player.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

final _logger = Logger('LetterProblem');

class LetterProblem {
  final List<String> _letters;
  List<String> get letters {
    final out = [..._letters];
    if (_extraUselessLetter != null) out.add(_extraUselessLetter!);

    return out;
  }

  List<int> _scrambleIndices = [];
  List<int> get scrambleIndices => _scrambleIndices;

  WordSolutions _solutions;
  WordSolutions get solutions => _solutions;
  bool get areAllSolutionsFound => _solutions.every((e) => e.isFound);

  final String? _extraUselessLetter;
  bool get hasUselessLetter => _extraUselessLetter != null;
  int get uselessLetterIndex => _letters.length;

  int _hiddenLetterIndex = -1;
  int get hiddenLettersIndex => _hiddenLetterIndex;

  ///
  /// Returns the current score of all the found solutions
  int get teamScore => _solutions
      .where((e) => e.isFound)
      .map((e) => e.isStolen ? e.value ~/ 3 : e.value)
      .fold(0, (prev, e) => prev + e);

  ///
  /// Returns if at least one solution was stolen
  bool get noSolutionWasStolenOrPardoned =>
      !_solutions.any((e) => e.isStolen || e.isPardoned);

  Set<Player> get finders => solutions
      .where((element) => element.isFound)
      .map((e) => e.foundBy)
      .toSet();

  int scoreOf(Player player) => solutions
      .where((element) => element.isFound && element.foundBy == player)
      .map((e) => e.value)
      .fold(0, (value, e) => value + e);

  LetterProblem._(
      {required List<String> letters,
      required WordSolutions solutions,
      required String? uselessLetter})
      : _letters = letters,
        _solutions = solutions,
        _extraUselessLetter = uselessLetter {
    _initialize();
  }

  ///
  /// This method should be called whenever [_letters] is changed
  void _initialize() {
    _logger.config('Initializing the letter problem...');

    // Sort the solutions in alphabetical order
    _solutions = _solutions.sort();

    // Sort the letters of candidate into alphabetical order
    _letters.sort();

    // Give a good scramble to the letters
    _scrambleIndices = List.generate(
        _letters.length + (hasUselessLetter ? 1 : 0), (index) => index);
    for (int i = 0; i < _solutions.length; i++) {
      scrambleLetters();
    }

    // Set the hidden letter index (even if not required). We use [_letters]
    // instead of [letters] because we do not want to hide the useless letter
    // if it exists
    _hiddenLetterIndex = Random().nextInt(_letters.length);

    _logger.config('Letter problem initialized');
  }

  ///
  /// Returns the solution if the word is a solution, null otherwise
  WordSolution? trySolution(String word,
      {required int nbLetterInSmallestWord}) {
    _logger.fine('Trying solution: $word...');

    // Do some rapid validation
    if (word.length < nbLetterInSmallestWord) {
      // If the word is shorted than the permitted shortest word, it is invalid
      _logger.warning('Word is too short');
      return null;
    }
    // If the word contains any non letters, it is invalid
    word = removeDiacritics(word.toUpperCase());
    if (word.contains(RegExp(r'[^A-Z]'))) {
      _logger.warning('Word contains non letters');
      return null;
    }

    final out = solutions.firstWhereOrNull((WordSolution e) => e.word == word);

    _logger.fine('Solution found: ${out != null}');
    return out;
  }

  ///
  /// Scamble the letters of the word by swapping two letters at random
  void scrambleLetters() {
    _logger.fine('Scrambling letters...');

    final random = Random();

    final index1 = random.nextInt(_scrambleIndices.length);
    int index2;
    do {
      index2 = random.nextInt(_scrambleIndices.length);
    } while (index1 == index2);

    final temp = _scrambleIndices[index1];
    _scrambleIndices[index1] = _scrambleIndices[index2];
    _scrambleIndices[index2] = temp;

    _logger.fine('Letters scrambled');
  }

  @override
  operator ==(Object other) =>
      other is LetterProblem &&
      const ListEquality().equals(_letters, other._letters);

  @override
  int get hashCode => Object.hash(_letters, _solutions, _extraUselessLetter);

  ///
  /// Calls the WordsTrain EBS server using the generateFromRandomWord method.
  static Future<LetterProblem> fetchFromEbs({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) async {
    _logger.info('Generating problem from EBS...');

    // Make sure the EBS is connected
    while (!Managers.instance.allManagersInitialized ||
        !Managers.instance.ebs.isConnectedToEbs) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    // We have to deduce the number of letters to add to the candidate. It is
    // way too long otherwise
    if (addUselessLetter) maxLetters--;

    if (maxLetters < minLetters) {
      throw ArgumentError(
          'The maximum number of letters should be greater than the minimum number of letters');
    }

    Map<String, dynamic> data =
        await Managers.instance.ebs.generateLetterProblem(
      nbLetterInSmallestWord: nbLetterInSmallestWord,
      minLetters: minLetters,
      maxLetters: maxLetters,
      minimumNbOfWords: minimumNbOfWords,
      maximumNbOfWords: maximumNbOfWords,
      addUselessLetter: addUselessLetter,
    );

    _logger.info('Problem generated');
    return LetterProblem._(
        letters: (data['letters'] as String).split(''),
        solutions: WordSolutions(
            ((data['solutions'] as List).cast<String>().toSet())
                .map((e) => WordSolution(word: e))
                .toList()),
        uselessLetter: data['uselessLetter']);
  }
}

class LetterProblemMock extends LetterProblem {
  LetterProblemMock({
    required String letters,
    required super.solutions,
    String super.uselessLetter = 'X',
  }) : super._(letters: letters.split(''));
}
