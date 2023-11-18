import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/french_words.dart';
import 'package:train_de_mots/models/misc.dart';

class WordProblem {
  String word;
  List<Solution> solutions;

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

    // Sort the subWords by length and alphabetically
    solutions.sort((a, b) {
      if (a.word.length == b.word.length) {
        return a.word.compareTo(b.word);
      }
      return a.word.length - b.word.length;
    });
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
      candidate = _randomLetters(
          minLetters: c.minimumWordLetter, maxLetters: c.maximumWordLetter);
      subWords = await _WordManipulation.instance._findsWords(
          from: candidate,
          nbLetters: c.nbLetterInSmallestWord,
          wordsCountLimit: c.maximumWordsNumber);
    } while (subWords.length < c.minimumWordsNumber ||
        subWords.length > c.maximumWordsNumber);

    return WordProblem._(
        word: candidate,
        solutions: subWords.map((e) => Solution(word: e)).toList());
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
      subWords = await _WordManipulation.wordsWithAtLeast(
          Configuration.instance.nbLetterInSmallestWord);

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
        subWords = (await _WordManipulation.instance._findsWords(
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
        solutions: subWords.map((e) => Solution(word: e)).toList());
  }
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
String _randomLetters({required int minLetters, required int maxLetters}) {
  if (minLetters <= 0 || maxLetters < minLetters) {
    throw ArgumentError(
        'Number of letters should be greater than zero and maxLetters should be higher than minLetters');
  }
  final nbLetters = minLetters == maxLetters
      ? minLetters
      : Random().nextInt(maxLetters - minLetters) + minLetters;

  String result = '';
  for (int i = 0; i < nbLetters; i++) {
    result += removeDiacritics(randomLetterFromFrequency.toUpperCase());
  }
  return result;
}

class _WordManipulation {
  final Map<int, Set<String>>
      words; // -1 is all, the other are subset of exactly n letters

  static final _WordManipulation _instance = _WordManipulation._internal();
  _WordManipulation._internal()
      : words = {
          -1: frenchWords
              .where((e) => !e.contains('-'))
              .map((e) => removeDiacritics(e.toUpperCase()))
              .toSet()
        };
  static _WordManipulation get instance => _instance;

  static Future<Set<String>> wordsWithAtLeast(int nbLetters) async {
    if (!_WordManipulation.instance.words.keys.contains(nbLetters)) {
      // Create the cache if it does not exist
      _WordManipulation.instance.words[nbLetters] = _WordManipulation
          .instance.words[-1]!
          .where((e) => e.length >= nbLetters)
          .toSet();
    }

    return _WordManipulation.instance.words[nbLetters]!;
  }

  ///
  /// Returns all valid words from the permutation of the letters of the word
  /// [from], with at least [nbLetters] and at most [from.length] letters.
  /// If [wordsCountLimit] is provided, the search terminate as soon as this
  /// limit is reached.
  Future<Set<String>> _findsWords({
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
}
