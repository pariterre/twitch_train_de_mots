import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/french_words.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/solution.dart';

class WordProblem {
  String _word;
  String get word => _word;

  List<int> _scrambleIndices = [];
  List<int> get scrambleIndices => _scrambleIndices;
  int cooldownScrambleTimer = 0;

  Solutions _solutions;
  Solutions get solutions => _solutions;
  bool get isAllSolutionsFound => _solutions.every((e) => e.isFound);

  String? _extraUselessLetter;
  bool get hasUselessLetter => _extraUselessLetter != null;

  ///
  /// Returns the maximum score that can be obtained by finding all the words
  int get maximumScore => _solutions.fold(0, (prev, e) => prev + e.value);

  ///
  /// Returns the current score of all the founders
  int get currentScore => _solutions
      .where((e) => e.isFound)
      .map((e) => e.value)
      .fold(0, (prev, e) => prev + e);

  ///
  /// Returns the threshold score for one star
  int get thresholdScoreForOneStar => maximumScore ~/ 3;

  static initialize({required int nbLetterInSmallestWord}) async {
    await _WordGenerator.instance.wordsWithAtLeast(nbLetterInSmallestWord);
  }

  Set<Player> get finders => solutions
      .where((element) => element.isFound)
      .map((e) => e.foundBy)
      .toSet();

  int scoreOf(Player player) => solutions
      .where((element) => element.isFound && element.foundBy == player)
      .map((e) => e.value)
      .fold(0, (value, element) => value + element);

  WordProblem._(
      {required String word,
      required Solutions solutions,
      required String? uselessLetter})
      : _word = word,
        _solutions = solutions,
        _extraUselessLetter = uselessLetter {
    _initialize();
  }

  ///
  /// This method should be called whenever [_word] is changed
  void _initialize() {
    // Sort the letters of candidate into alphabetical order
    final wordSorted = word.split('')..sort();
    _word = wordSorted.join('');
    _scrambleIndices = List.generate(word.length, (index) => index);

    _solutions = _solutions.sort();

    // Give a good scramble to the letters
    for (int i = 0; i < _solutions.length; i++) {
      scrambleLetters();
    }
  }

  ///
  /// Returns the solution if the word is a solution, null otherwise
  Solution? trySolution(String word, {required int nbLetterInSmallestWord}) {
    // Do some rapid validation
    if (word.length < nbLetterInSmallestWord) {
      // If the word is shorted than the permitted shortest word, it is invalid
      return null;
    }
    // If the word contains any non letters, it is invalid
    word = removeDiacritics(word.toUpperCase());
    if (word.contains(RegExp(r'[^A-Z]'))) return null;

    return solutions.firstWhereOrNull((Solution e) => e.word == word);
  }

  ///
  /// Scamble the letters of the word by swapping two letters at random
  void scrambleLetters() {
    final random = Random();

    final index1 = random.nextInt(_scrambleIndices.length);
    int index2;
    do {
      index2 = random.nextInt(_scrambleIndices.length);
    } while (index1 == index2);

    final temp = _scrambleIndices[index1];
    _scrambleIndices[index1] = _scrambleIndices[index2];
    _scrambleIndices[index2] = temp;
  }

  /// This method returns a letter that do not change the numbers of solutions
  /// to the problem.
  /// If the method returns null, it means it is not possible to add a useless
  /// letter to the problem without changing the number of solutions.
  static Future<String?> _addUselessLetter(
      {required String word, required Solutions solutions}) async {
    // Create a list of all possible letters to add
    final possibleLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .split('')
        .where((letter) => !word.contains(letter))
        .toList();

    final random = Random();
    do {
      final newLetter =
          possibleLetters.removeAt(random.nextInt(possibleLetters.length));
      final newWord = word + newLetter;
      final newSolutions =
          await _WordGenerator.instance._findsWordsFromPermutations(
        from: newWord,
        nbLetters: solutions.nbLettersInSmallest,
        wordsCountLimit: solutions.length + 1,
      );

      if (newSolutions.length == solutions.length) {
        // The new letter is useless if the number of solutions did not increase
        return newLetter;
      }
    } while (possibleLetters.isNotEmpty);

    // If we get here, it means no useless letter could be added
    return null;
  }

  void tossUselessLetter() {
    if (!hasUselessLetter) return;

    final index = _word.split('').indexWhere((e) => e == _extraUselessLetter);
    if (index == -1) return; // This should never happen, but just in case

    _word = _word.substring(0, index) + _word.substring(index + 1);
    _extraUselessLetter = null;
    _initialize();
  }

  ///
  /// Generates a new word problem from a random string of letters.
  static Future<WordProblem> generateFromRandom({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) async {
    String candidate;
    Set<String> subWords;

    bool isAValidCandidate = false;
    // We have to deduce the number of letters to add to the candidate. It is
    // way too long otherwise
    if (addUselessLetter) maxLetters--;
    String? uselessLetter;

    if (maxLetters < minLetters) {
      throw ArgumentError(
          'The maximum number of letters should be greater than the minimum number of letters');
    }

    do {
      candidate = _WordGenerator.instance._randomStringOfLetters(
          minLetters: minLetters, maxLetters: maxLetters);
      subWords = await _WordGenerator.instance._findsWordsFromPermutations(
          from: candidate,
          nbLetters: nbLetterInSmallestWord,
          wordsCountLimit: maximumNbOfWords);

      isAValidCandidate = subWords.length >= minimumNbOfWords &&
          subWords.length <= maximumNbOfWords;

      if (isAValidCandidate && addUselessLetter) {
        // Add a useless letter to the problem
        uselessLetter = await WordProblem._addUselessLetter(
            word: candidate,
            solutions:
                Solutions(subWords.map((e) => Solution(word: e)).toList()));

        // If it is not possible to add a new letter, reject the word
        if (uselessLetter == null) isAValidCandidate = false;
      }
    } while (!isAValidCandidate);

    return WordProblem._(
        word: candidate + (uselessLetter ?? ''),
        solutions: Solutions(subWords.map((e) => Solution(word: e)).toList()),
        uselessLetter: uselessLetter);
  }

  ///
  /// Generates a new word problem from picking a letter, then subsetting the
  /// words and picking a new letter available in the remainning words.
  static Future<WordProblem> generateFromBuildingUp({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) async {
    final random = Random();
    String candidate;
    Set<String> subWords;

    bool isAValidCandidate = false;
    String? uselessLetter;
    do {
      candidate = '';
      subWords = await _WordGenerator.instance
          .wordsWithAtLeast(nbLetterInSmallestWord);

      String availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      do {
        // Find a letter which is available
        candidate += availableLetters[random.nextInt(availableLetters.length)];

        // Reduce the subWords to only those containing the letters in candidate
        List<String> mandatoryLetters = candidate.split('');
        subWords = subWords
            .where((word) =>
                mandatoryLetters.every((letter) => word.contains(letter)))
            .toSet();

        // Find all the different letters in the subWords
        final availableLettersInSubWords =
            subWords.join('').split('').toSet().join('');

        // Remove the letter from the available letters and intersect with the available letters in subWords
        availableLetters = availableLetters
            .replaceAll(candidate[candidate.length - 1], '')
            .split('')
            .where((letter) => availableLettersInSubWords.contains(letter))
            .join('');

        // Delay to avoid blocking the UI
        await Future.delayed(const Duration(milliseconds: 1));

        // Continue as long as there are letters to add
      } while (availableLetters.isNotEmpty && subWords.length > 1);

      // Take one of the remainning subWords and use it as the word
      candidate = subWords.elementAt(random.nextInt(subWords.length));

      // Put all the possible words from candidate in subWords
      subWords = {};
      if (candidate.length >= minLetters && candidate.length <= maxLetters) {
        // This takes time, only do it if the candidate is valid
        subWords = (await _WordGenerator.instance._findsWordsFromPermutations(
          from: candidate,
          nbLetters: nbLetterInSmallestWord,
          wordsCountLimit: maximumNbOfWords,
        ));
      }
      isAValidCandidate = subWords.length >= minimumNbOfWords &&
          subWords.length <= maximumNbOfWords;

      if (isAValidCandidate && addUselessLetter) {
        // Add a useless letter to the problem
        uselessLetter = await WordProblem._addUselessLetter(
            word: candidate,
            solutions:
                Solutions(subWords.map((e) => Solution(word: e)).toList()));

        // If it is not possible to add a new letter, reject the word
        if (uselessLetter == null) isAValidCandidate = false;
      }

      // Make sure the number of words as solution is valid
    } while (!isAValidCandidate);

    return WordProblem._(
        word: candidate + (uselessLetter ?? ''),
        solutions: Solutions(subWords.map((e) => Solution(word: e)).toList()),
        uselessLetter: uselessLetter);
  }
}

class _WordGenerator {
  final Map<int, Set<String>>
      wordsList; // -1 is all, the other are subset of exactly n letters

  static final _WordGenerator _instance = _WordGenerator._internal();
  _WordGenerator._internal()
      : wordsList = {
          -1: frenchWords
              .where((e) => !e.contains('-'))
              .map((e) => removeDiacritics(e.toUpperCase()))
              .toSet()
        };
  static _WordGenerator get instance => _instance;

  Future<Set<String>> wordsWithAtLeast(int nbLetters) async {
    if (!_WordGenerator.instance.wordsList.keys.contains(nbLetters)) {
      // Create the cache if it does not exist
      _WordGenerator.instance.wordsList[nbLetters] = _WordGenerator
          .instance.wordsList[-1]!
          .where((e) => e.length >= nbLetters)
          .toSet();
    }

    return _WordGenerator.instance.wordsList[nbLetters]!;
  }

  ///
  /// Returns all valid words from the permutation of the letters of the word
  /// [from], with at least [nbLetters] and at most [from.length] letters.
  /// If [wordsCountLimit] is provided, the search terminate as soon as this
  /// limit is reached.
  Future<Set<String>> _findsWordsFromPermutations({
    required String from,
    int? wordsCountLimit,
    int nbLetters = 0,
  }) async {
    final Set<String> permutations = {};

    for (int i = nbLetters; i <= from.length; i++) {
      permutations.addAll(await _generateValidPermutations(
          await wordsWithAtLeast(nbLetters),
          from,
          i,
          wordsCountLimit != null
              ? wordsCountLimit - permutations.length + 1
              : null));

      // Terminate prematurely if no words of length from.length are found
      if (permutations.isEmpty) break;

      // Terminate prematurely if too many words are found
      if (wordsCountLimit != null && permutations.length > wordsCountLimit) {
        break;
      }
    }

    return permutations.toSet();
  }

  Future<Set<String>> _generateValidPermutations(
      Set<String> words, String word, int length, int? maxNumberWords) async {
    List<String> permutations = [];

    int cmp = 0;

    Future<void> generate(String prefix, String remaining, int len) async {
      // Add a delay to avoid blocking the UI
      if (cmp % 100 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
      cmp++;

      // If the len is 0, it means a new word is ready to be compared to the database
      if (len == 0) {
        if (words.contains(prefix)) permutations.add(prefix);
        return;
      }

      for (int i = 0; i < remaining.length; i++) {
        // Terminate prematurely if too many words are found
        if (maxNumberWords != null && permutations.length > maxNumberWords) {
          return;
        }
        await generate(prefix + remaining[i],
            remaining.substring(0, i) + remaining.substring(i + 1), len - 1);
      }
    }

    await generate('', word, length);
    return permutations.toSet();
  }

  /// Generates a random sequence of letters with the specified number of letters
  String _randomStringOfLetters(
      {required int minLetters, required int maxLetters}) {
    if (minLetters <= 0 || maxLetters < minLetters) {
      throw ArgumentError(
          'Number of letters should be greater than zero and maxLetters should be higher than minLetters');
    }
    final nbLetters = minLetters == maxLetters
        ? minLetters
        : Random().nextInt(maxLetters - minLetters) + minLetters;

    String result = '';
    for (int i = 0; i < nbLetters; i++) {
      result += removeDiacritics(_randomLetterFromFrequency.toUpperCase());
    }
    return result;
  }
}

/// Pick a letter at random based on the frequency of letters in the French.
String get _randomLetterFromFrequency {
  while (true) {
    final val = Random().nextInt(1000);

    if (val < 121) {
      return 'E';
    } else if (val < 191) {
      return 'A';
    } else if (val < 257) {
      return 'I';
    } else if (val < 322) {
      return 'S';
    } else if (val < 386) {
      return 'N';
    } else if (val < 447) {
      return 'R';
    } else if (val < 506) {
      return 'T';
    } else if (val < 556) {
      return 'O';
    } else if (val < 606) {
      return 'L';
    } else if (val < 651) {
      return 'U';
    } else if (val < 687) {
      return 'D';
    } else if (val < 719) {
      return 'C';
    } else if (val < 745) {
      return 'M';
    } else if (val < 770) {
      return 'P';
    } else if (val < 790) {
      return 'É';
    } else if (val < 802) {
      return 'G';
    } else if (val < 813) {
      return 'B';
    } else if (val < 824) {
      return 'V';
    } else if (val < 836) {
      return 'H';
    } else if (val < 847) {
      return 'F';
    } else if (val < 853) {
      return 'Q';
    } else if (val < 857) {
      return 'Y';
    } else if (val < 865) {
      return 'X';
    } else if (val < 868) {
      return 'J';
    } else if (val < 872) {
      return 'È';
    } else if (val < 875) {
      return 'À';
    } else if (val < 878) {
      return 'K';
    } else if (val < 892) {
      return 'W';
    } else if (val < 905) {
      return 'Z';
    } else if (val < 912) {
      return 'Ê';
    } else if (val < 919) {
      return 'Ç';
    } else if (val < 923) {
      return 'Ô';
    } else if (val < 926) {
      return 'Â';
    } else if (val < 930) {
      return 'Î';
    } else if (val < 932) {
      return 'Û';
    } else if (val < 933) {
      return 'Ù';
    } else if (val < 935) {
      return 'Ï';
    } else {
      // If we get here, we fell in the 6% of something else in french. Just
      // pick a random letter
    }
  }
}

class WordProblemMock extends WordProblem {
  WordProblemMock()
      : super._(
          word: 'BJOONUR',
          solutions: Solutions([
            Solution(word: 'BONJOUR'),
            Solution(word: 'JOUR'),
          ]),
          uselessLetter: null,
        );
}
