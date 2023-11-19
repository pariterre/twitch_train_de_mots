import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/french_words.dart';
import 'package:train_de_mots/models/solution.dart';

class WordProblem {
  String word;
  Solutions solutions;

  static initialize() async {
    await _WordGenerator.instance
        .wordsWithAtLeast(Configuration.instance.nbLetterInSmallestWord);
  }

  Set<String> get founders => solutions
      .where((element) => element.isFound)
      .map((e) => e.founder!)
      .toSet();

  int score(String founder) => solutions
      .where((element) => element.isFound && element.founder == founder)
      .map((e) => e.value)
      .reduce((value, element) => value + element);

  WordProblem._({required this.word, required this.solutions}) {
    // Sort the letters of candidate into alphabetical order
    final wordSorted = word.split('').toList()
      ..sort()
      ..join('');
    word = wordSorted.join('');

    solutions = solutions.sort();
  }

  bool trySolution(String founder, String word) {
    // Do some rapid validation
    if (word.length < Configuration.instance.nbLetterInSmallestWord) {
      return false;
    }
    if (word.contains(' ')) return false;

    final solution = Solution(word: word);
    final found =
        solutions.firstWhereOrNull((Solution e) => e.word == solution.word);
    if (found != null) {
      found.founder = founder;
      return true;
    }
    return false;
  }

  ///
  /// Generates a new word problem from a random string of letters.
  static Future<WordProblem> generateFromRandom() async {
    String candidate;
    Set<String> subWords;
    final c = Configuration.instance;

    do {
      candidate = _WordGenerator.instance._randomStringOfLetters(
          minLetters: c.minimumWordLetter, maxLetters: c.maximumWordLetter);
      subWords = await _WordGenerator.instance._findsWordsFromPermutations(
          from: candidate,
          nbLetters: c.nbLetterInSmallestWord,
          wordsCountLimit: c.maximumWordsNumber);
    } while (subWords.length < c.minimumWordsNumber ||
        subWords.length > c.maximumWordsNumber);

    return WordProblem._(
        word: candidate,
        solutions: Solutions(subWords.map((e) => Solution(word: e)).toList()));
  }

  ///
  /// Generates a new word problem from picking a letter, then subsetting the
  /// words and picking a new letter available in the remainning words.
  static Future<WordProblem> generateFromBuildingUp() async {
    final random = Random();
    String candidate;
    Set<String> subWords;

    do {
      candidate = '';
      subWords = await _WordGenerator.instance
          .wordsWithAtLeast(Configuration.instance.nbLetterInSmallestWord);

      String availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      // String availableLetters = 'AELMSWX'; // Force a rapid solution for debug
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
      if (candidate.length >= Configuration.instance.minimumWordLetter &&
          candidate.length <= Configuration.instance.maximumWordLetter) {
        // This takes time, only do it if the candidate is valid
        subWords = (await _WordGenerator.instance._findsWordsFromPermutations(
          from: candidate,
          nbLetters: Configuration.instance.nbLetterInSmallestWord,
          wordsCountLimit: Configuration.instance.maximumWordsNumber,
        ));
      }
      // Make sure the number of words as solution is valid
    } while (subWords.length < Configuration.instance.minimumWordsNumber ||
        subWords.length > Configuration.instance.maximumWordsNumber);

    return WordProblem._(
        word: candidate,
        solutions: Solutions(subWords.map((e) => Solution(word: e)).toList()));
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

    for (int i = from.length; i >= nbLetters; i--) {
      permutations.addAll(await _generateValidPermutations(
          await wordsWithAtLeast(nbLetters), from, i, wordsCountLimit));

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
      if (cmp % 1000 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
      cmp++;

      // If the len is 0, it means a new word was found
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
