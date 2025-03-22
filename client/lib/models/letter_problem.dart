import 'dart:math';

import 'package:collection/collection.dart';
import 'package:common/models/french_words.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/ebs_server_manager.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/word_solution.dart';

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
  /// Returns the maximum score that can be obtained by finding all the solutions
  int get maximumPossibleScore => _solutions.maximumPossibleScore;

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
    _logger.info('Trying solution: $word...');

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

    _logger.info('Solution found: ${out != null}');
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
}

class ProblemGenerator {
  static Future<String?> _fetchProblemFromDatabase({
    required bool withUselessLetter,
    required int minNbLetters,
    required int maxNbLetters,
  }) async {
    _logger.info('Fetching problem from database...');
    final out = await DatabaseManager.instance.fetchLetterProblem(
        withUselessLetter: withUselessLetter,
        minNbLetters: minNbLetters,
        maxNbLetters: maxNbLetters);

    _logger.info('Problem fetched: ${out != null}');
    return out;
  }

  static DateTime _lastScreenUpdate = DateTime.now();
  static Future<void> _updateScreenIfNeeded({double dt = 1 / 60}) async {
    if (DateTime.now().difference(_lastScreenUpdate).inMilliseconds >
        dt * 1000) {
      _lastScreenUpdate = DateTime.now();

      _logger.info('Updating screen...');
      await Future.delayed(Duration.zero);
    }
  }

  ///
  /// Generates a new word problem from a random string of letters.
  static Future<LetterProblem> generateFromRandom({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) async {
    _logger.info('Generating problem from random letters...');

    LetterProblem? finalProblem;
    // We have to deduce the number of letters to add to the candidate. It is
    // way too long otherwise
    if (addUselessLetter) maxLetters--;

    if (maxLetters < minLetters) {
      throw ArgumentError(
          'The maximum number of letters should be greater than the minimum number of letters');
    }

    final maxSearchingTimeThreshold = DateTime.now().add(maxSearchingTime);
    do {
      await _updateScreenIfNeeded();

      // Generate a first candidate set of letters
      List<String> candidateLetters = _WordGenerator.instance
          ._generateRandomLetters(nbLetters: maxLetters, useFrequency: false);
      Set<String> subWords;
      String? uselessLetter;

      if (DateTime.now().isAfter(maxSearchingTimeThreshold)) {
        // If the time is up, try fetching from the database. If it fails, we
        // continue with the random letters algorithm
        final candidateLettersTp = await _fetchProblemFromDatabase(
            withUselessLetter: addUselessLetter,
            minNbLetters: minLetters,
            maxNbLetters: maxLetters);
        if (candidateLettersTp != null) {
          candidateLetters = candidateLettersTp.split('');
        }
      }

      do {
        await _updateScreenIfNeeded();

        // Find all the words that can be made from the candidate letters
        subWords = await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters, nbLetters: nbLetterInSmallestWord);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (subWords.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (subWords.length < minimumNbOfWords ||
            candidateLetters.length < minLetters) {
          break;
        }

        // Otherwise, drop one of the letters that is not in any of the longest
        // words
        final nbLettersInLongest =
            subWords.fold<int>(0, (prev, element) => max(prev, element.length));
        final longestSubWords = subWords
            .where((word) => word.length == nbLettersInLongest)
            .toList();
        final lettersToRemove = candidateLetters
            .where((letter) =>
                !longestSubWords.any((word) => word.contains(letter)))
            .toList();
        if (lettersToRemove.isEmpty) {
          // If the combination of letters of the longest words contains all the
          // letters pick a random letter to remove
          lettersToRemove.add(candidateLetters[
              Random().nextInt(candidateLetters.length - 1) + 1]);
        }
        for (final letter in lettersToRemove) {
          candidateLetters.remove(letter);
        }
      } while (true);

      // Make sure the number of words as solution is valid
      bool isAValidCandidate = subWords.length >= minimumNbOfWords &&
          subWords.length <= maximumNbOfWords &&
          candidateLetters.length >= minLetters;

      if (isAValidCandidate && addUselessLetter) {
        // Add a useless letter to the problem if required
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            solutions: WordSolutions(
                subWords.map((e) => WordSolution(word: e)).toList()));

        // If it is not possible to add a new letter, reject the letters candidate
        isAValidCandidate = uselessLetter != null;
      }

      if (isAValidCandidate) {
        // This can return null if the problem was already played
        finalProblem = _letterProblemFromListLetters(
            candidateLetters: candidateLetters,
            subWords: subWords,
            uselessLetter: uselessLetter);
      }
    } while (finalProblem == null);

    // The candidate is valid, return the problem
    _logger.info('Problem generated');
    return finalProblem;
  }

  ///
  /// Generates a new word problem from picking a letter, then subsetting the
  /// words and picking a new letter available in the remainning words.
  static Future<LetterProblem> generateFromBuildingUp({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) async {
    _logger.info('Generating problem from building up...');

    final random = Random();

    LetterProblem? finalProblem;
    final maxSearchingTimeThreshold = DateTime.now().add(maxSearchingTime);

    do {
      await _updateScreenIfNeeded();
      List<String> candidateLetters = [];

      Set<String> subWords = await _WordGenerator.instance
          .wordsWithAtLeast(nbLetterInSmallestWord);
      String? uselessLetter;

      String availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      do {
        await _updateScreenIfNeeded();

        // From the list of all the remaining letters in the alphabet, pick a random one
        candidateLetters
            .add(availableLetters[random.nextInt(availableLetters.length)]);

        if (DateTime.now().isAfter(maxSearchingTimeThreshold)) {
          // If the time is up, try fetching from the database. If it fails, we
          // continue with the random letters algorithm
          final candidateLettersTp = await _fetchProblemFromDatabase(
            withUselessLetter: addUselessLetter,
            minNbLetters: minLetters,
            maxNbLetters: maxLetters,
          );
          if (candidateLettersTp != null) {
            candidateLetters = candidateLettersTp.split('');
            availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            subWords = await _WordGenerator.instance
                .wordsWithAtLeast(nbLetterInSmallestWord);
          }
        }

        // Reduce the subWords to only those containing the letters in candidate
        subWords = subWords
            .where((word) =>
                candidateLetters.every((letter) => word.contains(letter)))
            .toSet();

        // Find all the different letters in the subWords
        final availableLettersInSubWords =
            subWords.join('').split('').toSet().join('');

        // Remove the letters, from the available letters, that don't intersect
        // with the letters in the subWords. That prevents us from picking a
        // letter that is not in the subWords (droping the number of solutions
        // to zero)
        availableLetters = availableLetters
            .replaceAll(candidateLetters[candidateLetters.length - 1], '')
            .split('')
            .where((letter) => availableLettersInSubWords.contains(letter))
            .join('');

        // Continue as long as there are letters to add
      } while (availableLetters.isNotEmpty && subWords.length > 1);

      // Take one of the remainning subWords and use it as the word
      candidateLetters =
          subWords.elementAt(random.nextInt(subWords.length)).split('');

      // Get all the possible words from candidate in subWords
      subWords = {};
      if (candidateLetters.length >= minLetters &&
          candidateLetters.length <= maxLetters) {
        // This takes time, only do it if the candidate is valid
        subWords = (await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters, nbLetters: nbLetterInSmallestWord));
      }
      bool isAValidCandidate = subWords.length >= minimumNbOfWords &&
          subWords.length <= maximumNbOfWords;

      if (isAValidCandidate && addUselessLetter) {
        // Add a useless letter to the problem
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            solutions: WordSolutions(
                subWords.map((e) => WordSolution(word: e)).toList()));

        // If it is not possible to add a new letter, reject the word
        isAValidCandidate = uselessLetter != null;
      }

      if (isAValidCandidate) {
        // This can return null if the problem was already played
        finalProblem = _letterProblemFromListLetters(
            candidateLetters: candidateLetters,
            subWords: subWords,
            uselessLetter: uselessLetter);
      }
    } while (finalProblem == null);

    _logger.info('Problem generated');
    return finalProblem;
  }

  ///
  /// Generates a new word problem from a random longest word. Apart from the
  /// randomization of the candidate letters, the algorithm is the same as the
  /// [generateFromRandom] method.
  static Future<LetterProblem> generateFromRandomWord(
      {required int nbLetterInSmallestWord,
      required int minLetters,
      required int maxLetters,
      required int minimumNbOfWords,
      required int maximumNbOfWords,
      required bool addUselessLetter,
      required Duration maxSearchingTime}) async {
    _logger.info('Generating problem from random word...');

    // We have to deduce the number of letters to add to the candidate. It is
    // way too long otherwise
    if (addUselessLetter) maxLetters--;

    if (maxLetters < minLetters) {
      throw ArgumentError(
          'The maximum number of letters should be greater than the minimum number of letters');
    }

    final random = Random();
    final wordsToPickFrom =
        (await _WordGenerator.instance.wordsWithAtLeast(minLetters))
            .where((e) => e.length <= maxLetters);

    LetterProblem? finalProblem;
    final maxSearchingTimeThreshold = DateTime.now().add(maxSearchingTime);

    do {
      await _updateScreenIfNeeded();

      // Generate a first candidate set of letters
      List<String> candidateLetters = wordsToPickFrom
          .elementAt(random.nextInt(wordsToPickFrom.length))
          .split('');
      Set<String> subWords;
      String? uselessLetter;

      if (DateTime.now().isAfter(maxSearchingTimeThreshold)) {
        // If the time is up, try fetching from the database. If it fails, we
        // continue with the random letters algorithm
        final candidateLettersTp = await _fetchProblemFromDatabase(
            withUselessLetter: addUselessLetter,
            minNbLetters: minLetters,
            maxNbLetters: maxLetters);
        if (candidateLettersTp != null) {
          candidateLetters = candidateLettersTp.split('');
        }
      }

      do {
        await _updateScreenIfNeeded();

        // Find all the words that can be made from the candidate letters
        subWords = await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters, nbLetters: nbLetterInSmallestWord);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (subWords.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (subWords.length < minimumNbOfWords ||
            candidateLetters.length < minLetters) {
          break;
        }

        // Otherwise, drop one of the letters that is not in any of the longest
        // words
        final nbLettersInLongest =
            subWords.fold<int>(0, (prev, element) => max(prev, element.length));
        final longestSubWords = subWords
            .where((word) => word.length == nbLettersInLongest)
            .toList();
        final lettersToRemove = candidateLetters
            .where((letter) =>
                !longestSubWords.any((word) => word.contains(letter)))
            .toList();
        if (lettersToRemove.isEmpty) {
          // If the combination of letters of the longest words contains all the
          // letters pick a random letter to remove
          lettersToRemove.add(candidateLetters[
              Random().nextInt(candidateLetters.length - 1) + 1]);
        }
        for (final letter in lettersToRemove) {
          candidateLetters.remove(letter);
        }
      } while (true);

      // Make sure the number of words as solution is valid
      bool isAValidCandidate = subWords.length >= minimumNbOfWords &&
          subWords.length <= maximumNbOfWords &&
          candidateLetters.length >= minLetters;

      if (isAValidCandidate && addUselessLetter) {
        // Add a useless letter to the problem if required
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            solutions: WordSolutions(
                subWords.map((e) => WordSolution(word: e)).toList()));

        // If it is not possible to add a new letter, reject the letters candidate
        isAValidCandidate = uselessLetter != null;
      }

      if (isAValidCandidate) {
        // This can return null if the problem was already played
        finalProblem = _letterProblemFromListLetters(
            candidateLetters: candidateLetters,
            subWords: subWords,
            uselessLetter: uselessLetter);
      }
    } while (finalProblem == null);

    // The candidate is valid, return the problem
    _logger.info('Problem generated');
    return finalProblem;
  }

  ///
  /// Calls the Train de mots EBS server using the generateFromRandomWord method.
  static Future<LetterProblem> generateFromEbs({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) async {
    _logger.info('Generating problem from EBS...');

    // We have to deduce the number of letters to add to the candidate. It is
    // way too long otherwise
    if (addUselessLetter) maxLetters--;

    if (maxLetters < minLetters) {
      throw ArgumentError(
          'The maximum number of letters should be greater than the minimum number of letters');
    }

    try {
      if (!EbsServerManager.instance.isConnectedToEbs) {
        throw Exception('Not connected to EBS server');
      }

      Map<String, dynamic> data =
          await EbsServerManager.instance.generateLetterProblem(
        nbLetterInSmallestWord: nbLetterInSmallestWord,
        minLetters: minLetters,
        maxLetters: maxLetters,
        minimumNbOfWords: minimumNbOfWords,
        maximumNbOfWords: maximumNbOfWords,
        addUselessLetter: addUselessLetter,
        maxSearchingTime: maxSearchingTime,
      );

      final finalProblem = _letterProblemFromListLetters(
          candidateLetters: data['letters'].split(''),
          subWords: data['solutions'].cast<String>().toSet(),
          uselessLetter: data['uselessLetter']);
      if (finalProblem == null) {
        throw Exception('Failed to get problem from EBS server');
      }

      _logger.info('Problem generated');
      return finalProblem;
    } catch (e) {
      _logger.warning(
          'Failed to get problem from EBS server, falling back to local algorithm');
      // If anything goes wrong with the EBS, fallback to the local
      // algorithm
      return await generateFromRandomWord(
          nbLetterInSmallestWord: nbLetterInSmallestWord,
          minLetters: minLetters,
          maxLetters: maxLetters,
          minimumNbOfWords: minimumNbOfWords,
          maximumNbOfWords: maximumNbOfWords,
          addUselessLetter: addUselessLetter,
          maxSearchingTime: maxSearchingTime);
    }
  }

  ///
  ///
  static LetterProblem? _letterProblemFromListLetters(
      {required List<String> candidateLetters,
      required Set<String> subWords,
      required String? uselessLetter}) {
    _logger.info('Creating problem from list of letters...');

    final problem = LetterProblem._(
        letters: candidateLetters,
        solutions:
            WordSolutions(subWords.map((e) => WordSolution(word: e)).toList()),
        uselessLetter: uselessLetter);

    _logger.info('Problem created');
    return problem;
  }

  ///
  /// This method returns a letter that do not change the numbers of solutions
  /// to the problem.
  /// If the method returns null, it means it is not possible to add a useless
  /// letter to the problem without changing the number of solutions.
  static Future<String?> _findUselessLetter(
      {required List<String> letters, required WordSolutions solutions}) async {
    _logger.info('Finding a useless letter...');

    // Create a list of all possible letters to add
    final possibleLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .split('')
        .where((letter) => !letters.contains(letter))
        .toList();

    final random = Random();

    do {
      await _updateScreenIfNeeded();

      final newLetter =
          possibleLetters.removeAt(random.nextInt(possibleLetters.length));
      final newLetters = [...letters, newLetter];
      final newSolutions = await _WordGenerator.instance
          ._findsWordsFromPermutations(
              from: newLetters, nbLetters: solutions.nbLettersInSmallest);

      if (newSolutions.length == solutions.length) {
        // The new letter is useless if the number of solutions did not change
        _logger.info('Useless letter found');
        return newLetter;
      }
    } while (possibleLetters.isNotEmpty);

    // If we get here, it means no useless letter could be found
    _logger.warning('No useless letter found');
    return null;
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
    _logger.info('Getting words with at least $nbLetters letters...');

    if (!_WordGenerator.instance.wordsList.keys.contains(nbLetters)) {
      _logger.info('Words dictionary not found, creating it...');

      // Create the cache if it does not exist
      _WordGenerator.instance.wordsList[nbLetters] = _WordGenerator
          .instance.wordsList[-1]!
          .where((e) => e.length >= nbLetters)
          .toSet();

      _logger.info('Words dictionary updated');
    }

    _logger.info('Words ready');
    return _WordGenerator.instance.wordsList[nbLetters]!;
  }

  ///
  /// Returns all valid words from the permutation of the letters of the word
  /// [from], with at least [nbLetters] and at most [from.length] letters.
  Future<Set<String>> _findsWordsFromPermutations({
    required List<String> from,
    int nbLetters = 0,
  }) async {
    _logger.info('Finding words from permutations...');

    // First, we remove all the words from the database that contains any letter
    // which is not in the letters set as the words
    final Set<String> words = {};
    for (final word in await wordsWithAtLeast(nbLetters)) {
      // We should update the screen every now and then here, but doing so makes
      // the algorithm way too slow. We will update the screen after the loop.
      // This creates a lag of about 1 to 2 seconds, but it is acceptable (the other
      // solution is to update every 1/60 seconds, which is takes about 1 minute)
      if (word.split('').every((letter) => from.contains(letter))) {
        words.add(word);
      }
    }
    // Update the screen here
    await ProblemGenerator._updateScreenIfNeeded();

    // Then, count each duplicate letters in each word to make sure at least the
    // same amount of duplicate exists in the letters set
    _logger.info('Permutations found, managing duplicates...');
    final out = words.where((word) {
      final wordAsList = word.split('');
      return wordAsList.every((letter) {
        final countInWord =
            wordAsList.fold<int>(0, (prev, e) => prev + (e == letter ? 1 : 0));
        final countInLetters =
            from.fold<int>(0, (prev, e) => prev + (e == letter ? 1 : 0));
        return countInWord <= countInLetters;
      });
    }).toSet();

    _logger.info('Duplicates managed, all permutations found');
    return out;
  }

  /// Generates a random sequence of letters with the specified number of letters
  List<String> _generateRandomLetters(
      {required int nbLetters, bool useFrequency = true}) {
    _logger.info('Generating random letters...');

    if (nbLetters <= 0) {
      throw ArgumentError(
          'Number of letters should be greater than zero and maxLetters should be higher than minLetters');
    }
    List<String> result = [];
    for (int i = 0; i < nbLetters; i++) {
      final letter = useFrequency
          ? _randomLetterFromFrequency
          : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Random().nextInt(26)];
      result.add(removeDiacritics(letter));
    }

    _logger.info('Random letters generated');
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

class LetterProblemMock extends LetterProblem {
  LetterProblemMock({
    required String letters,
    required super.solutions,
    String super.uselessLetter = 'X',
  }) : super._(letters: letters.split(''));
}
