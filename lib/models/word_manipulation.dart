import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/french_words.dart';
import 'package:train_de_mots/models/misc.dart';

class WordProblem {
  String word;
  List<Solution> solutions;

  WordProblem._({required this.word, required this.solutions});

  bool trySolution(String founder, String word) {
    // Do some rapid validation
    if (word.length < Configuration.instance.smallestWord) return false;
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
  /// Generates a new word problem from a random word.
  /// This is the main constructor
  static Future<WordProblem> generate() async {
    String candidate;
    Set<String> subWords;
    final c = Configuration.instance;

    do {
      candidate = randomLetters(
          minLetters: c.minimumWordLetter, maxLetters: c.maximumWordLetter);
      subWords = await _WordManipulation.instance.findsWords(
          from: candidate,
          nbLetters: c.smallestWord,
          wordsCountLimit: c.maximumWordsNumber);
    } while (subWords.length < c.minimumWordsNumber ||
        subWords.length > c.maximumWordsNumber);

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
    if (cmp % 5000 == 0) {
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
String randomLetters({required int minLetters, required int maxLetters}) {
  if (minLetters <= 0 || maxLetters < minLetters) {
    throw ArgumentError(
        'Number of letters should be greater than zero and maxLetters should be higher than minLetters');
  }
  final nbLetters = minLetters == maxLetters
      ? minLetters
      : Random().nextInt(maxLetters - minLetters) + minLetters;

  Random random = Random();
  String result = '';

  for (int i = 0; i < nbLetters; i++) {
    int randomNumber =
        random.nextInt(26); // Generates a random number between 0 and 25
    String capitalLetter = String.fromCharCode(
        randomNumber + 65); // ASCII code for capital letters starts from 65 (A)
    result += capitalLetter;
  }

  return result;
}

class _WordManipulation {
  final Set<String> words;

  static final _WordManipulation _instance = _WordManipulation._internal();
  _WordManipulation._internal()
      : words = {...frenchWords.map((e) => removeDiacritics(e.toUpperCase()))};
  static _WordManipulation get instance => _instance;

  Future<void> initialize() async {}

  ///
  /// Pick a random word with at least [nbLetters]
  Future<String> pickRandom({int nbLetters = 0}) async {
    final reducedList = await wordsWithAtLeast(nbLetters: nbLetters);

    return reducedList.elementAt(Random().nextInt(reducedList.length));
  }

  ///
  /// Returns all words with exactly [nbLetters] in the list
  Future<Set<String>> wordsWithExactly({required int nbLetters}) async =>
      words.where((e) => e.length == nbLetters).toSet();

  ///
  /// Returns all words with at least [nbLetters] in the list
  Future<Set<String>> wordsWithAtLeast({required int nbLetters}) async =>
      nbLetters == 0
          ? words
          : words.where((e) => e.length >= nbLetters).toSet();

  ///
  /// Returns all valid words from the permutation of the letters of the word
  /// [from], with at least [nbLetters] and at most [from.length] letters.
  /// If [wordsCountLimit] is provided, the search terminate as soon as this
  /// limit is reached.
  Future<Set<String>> findsWords({
    required String from,
    int? wordsCountLimit,
    int nbLetters = 0,
  }) async {
    final Set<String> permutations = {};

    for (int i = nbLetters; i < from.length; i++) {
      permutations.addAll(await _generateValidPermutations(
          await wordsWithExactly(nbLetters: i), from, i, wordsCountLimit));

      // Terminate prematurely if too many words are found
      if (wordsCountLimit != null && permutations.length > wordsCountLimit) {
        break;
      }
    }

    return permutations.toSet();
  }
}
