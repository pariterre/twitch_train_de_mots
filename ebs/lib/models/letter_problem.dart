import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/models/problem_configuration.dart';
import 'package:train_de_mots_ebs/models/range.dart';

final _random = Random();
final _logger = Logger('LetterProblem');

class LetterProblem {
  final List<String> letters;

  final String? uselessLetter;
  bool get hasUselessLetter => uselessLetter != null;

  final Set<String> solutions;

  ///
  /// This method constructs a [LetterProblem] from a list of [letters] and a set
  /// of words that can be made from these letters ([solutions]).
  /// The [uselessLetter] is a letter that can be added to the list of letters
  LetterProblem({
    required List<String> letters,
    required Set<String> solutions,
    required this.uselessLetter,
  })  : letters = letters.map((e) => e.toUpperCase()).toList()..sort(),
        solutions =
            solutions.map((e) => removeDiacritics(e).toUpperCase()).toSet();

  @override
  String toString() {
    return 'Problem:\n'
        '\tLetters: $letters (${letters.length})\n'
        '\tuselessLetter: $uselessLetter\n'
        '\tsolutions: ${solutions.length}';
  }

  ///
  /// Returns a serialized version of the LetterProblem
  Map<String, dynamic> serialize() {
    return {
      'letters': letters.join(),
      'uselessLetter': uselessLetter,
      'solutions': solutions.toList(),
    };
  }

  ///
  /// Generates a new word problem from a random string of letters.
  /// The [config] is the configuration of the problem to generate.
  /// The [timeout] is the maximum time to generate the problem.
  factory LetterProblem.generateFromRandom(ProblemConfiguration config) {
    _logger.info('Generating problem from random letters...');

    LetterProblem? finalProblem;
    do {
      // Generate a first candidate set of letters
      List<String> candidateLetters = DictionaryManager.generateRandomLetters(
          nbLetters: config.lengthLongestSolution.max, useFrequency: false);
      Set<String> solutions;
      String? uselessLetter;

      do {
        // Find all the words that can be made from the candidate letters
        solutions = DictionaryManager.findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: config.lengthShortestSolution.max);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (solutions.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (solutions.length < config.nbSolutions.min ||
            candidateLetters.length < config.lengthLongestSolution.min) {
          break;
        }

        // Otherwise, drop one of the letters that is not in any of the longest
        // words
        final nbLettersInLongest = solutions.fold<int>(
            0, (prev, element) => max(prev, element.length));
        final longestSubWords = solutions
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
      if (!config.nbSolutions.contains(solutions.length) ||
          candidateLetters.length < config.lengthLongestSolution.min) {
        continue;
      }

      if (config.nbUselessLetters > 0) {
        // Add a useless letter to the problem if required
        uselessLetter = _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: config.lengthShortestSolution.max,
            nbSolutions: solutions.length);

        // If it is not possible to add a new letter, reject the letters candidate
        if (uselessLetter == null) {
          continue;
        }
      }

      // If we get here, it means the candidate is valid
      finalProblem = LetterProblem(
          letters: candidateLetters,
          solutions: solutions,
          uselessLetter: uselessLetter);
    } while (finalProblem == null);

    // The candidate is valid, return the problem
    _logger.info('Problem generated');
    return finalProblem;
  }

  ///
  /// Generates a new word problem from picking a letter, then subsetting the
  /// words and picking a new letter available in the remainning words.
  /// The [config] is the configuration of the problem to generate.
  /// The [timeout] is the maximum time to generate the problem.
  factory LetterProblem.generateFromBuildingUp(ProblemConfiguration config) {
    _logger.info('Generating problem from building up...');

    LetterProblem? finalProblem;
    do {
      List<String> candidateLetters = [];
      Set<String> solutions =
          DictionaryManager.wordsWithAtLeast(config.lengthShortestSolution.max);
      String? uselessLetter;

      String availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      do {
        // From the list of all the remaining letters in the alphabet, pick a random one
        candidateLetters
            .add(availableLetters[_random.nextInt(availableLetters.length)]);

        // Reduce the solutions to only those containing the letters in candidate
        solutions = solutions
            .where((word) =>
                candidateLetters.every((letter) => word.contains(letter)))
            .toSet();

        // Find all the different letters in the solutions
        final availableLettersInSubWords =
            solutions.join('').split('').toSet().join('');

        // Remove the letters, from the available letters, that don't intersect
        // with the letters in the solutions. That prevents us from picking a
        // letter that is not in the solutions (droping the number of solutions
        // to zero)
        availableLetters = availableLetters
            .replaceAll(candidateLetters[candidateLetters.length - 1], '')
            .split('')
            .where((letter) => availableLettersInSubWords.contains(letter))
            .join('');

        // Continue as long as there are letters to add
      } while (availableLetters.isNotEmpty && solutions.length > 1);

      // Take one of the remainning solutions and use it as the word
      candidateLetters =
          solutions.elementAt(_random.nextInt(solutions.length)).split('');

      // Get all the possible words from candidate in solutions
      solutions = {};
      if (config.lengthLongestSolution.contains(candidateLetters.length)) {
        // This takes time, only do it if the candidate is valid
        solutions = DictionaryManager.findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: config.lengthShortestSolution.max);
      }

      // Make sure the number of words as solution is valid
      if (!config.nbSolutions.contains(solutions.length)) {
        continue;
      }

      if (config.nbUselessLetters > 0) {
        // Add a useless letter to the problem
        uselessLetter = _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: config.lengthShortestSolution.max,
            nbSolutions: solutions.length);

        // If it is not possible to add a new letter, reject the word
        if (uselessLetter == null) {
          continue;
        }
      }

      // If we get here, it means the candidate is valid
      finalProblem = LetterProblem(
        letters: candidateLetters,
        solutions: solutions,
        uselessLetter: uselessLetter,
      );
    } while (finalProblem == null);

    // The candidate is valid, return the problem
    _logger.info('Problem generated');
    return finalProblem;
  }

  ///
  /// Generates a new word problem from a random longest word. Apart from the
  /// randomization of the candidate letters, the algorithm is the same as the
  /// [LetterProblem.generateFromRandom] method.
  /// The [config] is the configuration of the problem to generate.
  /// The [timeout] is the maximum time to generate the problem.
  factory LetterProblem.generateFromRandomWord(ProblemConfiguration config) {
    _logger.info('Generating problem from random word...');

    final wordsToPickFrom =
        DictionaryManager.wordsWithAtLeast(config.lengthLongestSolution.min)
            .where((e) => e.length <= config.lengthLongestSolution.max);

    LetterProblem? finalProblem;
    do {
      // Generate a first candidate set of letters
      List<String> candidateLetters = wordsToPickFrom
          .elementAt(_random.nextInt(wordsToPickFrom.length))
          .split('');
      Set<String> solutions;
      String? uselessLetter;

      do {
        // Find all the words that can be made from the candidate letters
        solutions = DictionaryManager.findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: config.lengthShortestSolution.max);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (solutions.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (solutions.length < config.nbSolutions.min ||
            candidateLetters.length < config.lengthLongestSolution.min) {
          break;
        }

        // Otherwise, drop one of the letters that is not in any of the longest
        // words
        final nbLettersInLongest = solutions.fold<int>(
            0, (prev, element) => max(prev, element.length));
        final longestSubWords = solutions
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
      if (!config.nbSolutions.contains(solutions.length) ||
          candidateLetters.length < config.lengthLongestSolution.min) {
        continue;
      }

      if (config.nbUselessLetters > 0) {
        // Add a useless letter to the problem if required
        uselessLetter = _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: config.lengthShortestSolution.max,
            nbSolutions: solutions.length);

        // If it is not possible to add a new letter, reject the letters candidate
        if (uselessLetter == null) {
          continue;
        }
      }

      // This can return null if the problem was already played
      finalProblem = LetterProblem(
        letters: candidateLetters,
        solutions: solutions,
        uselessLetter: uselessLetter,
      );
    } while (finalProblem == null);

    // The candidate is valid, return the problem
    _logger.info('Problem generated');
    return finalProblem;
  }

  factory LetterProblem.generateProblemFromRequest(request) {
    int forceIntParse(value) => value is int ? value : int.parse(value);
    Range forceRangeParse(valueMin, valueMax) =>
        Range(forceIntParse(valueMin), forceIntParse(valueMax));

    LetterProblem Function(ProblemConfiguration) parseAlgorithm(algorithm) {
      switch (algorithm) {
        case 'fromRandom':
          return LetterProblem.generateFromRandom;
        case 'fromBuildingUp':
          return LetterProblem.generateFromBuildingUp;
        case 'fromRandomWord':
          return LetterProblem.generateFromRandomWord;
        default:
          throw InvalidAlgorithmException();
      }
    }

    ProblemConfiguration parseProblemConfiguration({
      lengthShortestSolutionMin,
      lengthShortestSolutionMax,
      lengthLongestSolutionMin,
      lengthLongestSolutionMax,
      nbSolutionsMin,
      nbSolutionsMax,
      nbUselessLetters,
    }) {
      try {
        return ProblemConfiguration(
          lengthShortestSolution: forceRangeParse(
              lengthShortestSolutionMin, lengthShortestSolutionMax),
          lengthLongestSolution: forceRangeParse(
              lengthLongestSolutionMin, lengthLongestSolutionMax),
          nbSolutions: forceRangeParse(nbSolutionsMin, nbSolutionsMax),
          nbUselessLetters: forceIntParse(nbUselessLetters),
        );
      } catch (e) {
        throw InvalidConfigurationException();
      }
    }

    final algorithm = parseAlgorithm(request['algorithm']!);
    final config = parseProblemConfiguration(
      lengthShortestSolutionMin: request['lengthShortestSolutionMin'],
      lengthShortestSolutionMax: request['lengthShortestSolutionMax'],
      lengthLongestSolutionMin: request['lengthLongestSolutionMin'],
      lengthLongestSolutionMax: request['lengthLongestSolutionMax'],
      nbSolutionsMin: request['nbSolutionsMin'],
      nbSolutionsMax: request['nbSolutionsMax'],
      nbUselessLetters: request['nbUselessLetters'],
    );

    _logger.info('Generating new word\n'
        'Configuration:\n'
        '\talgorithm: ${request['algorithm']}\n'
        '\tlengthShortestSolution: ${config.lengthShortestSolution.min} - ${config.lengthShortestSolution.max}\n'
        '\tlengthLongestSolution: ${config.lengthLongestSolution.min} - ${config.lengthLongestSolution.max}\n'
        '\tnbSolutions: ${config.nbSolutions.min} - ${config.nbSolutions.max}\n'
        '\tnbUselessLetters: ${config.nbUselessLetters}\n');

    final problem = algorithm(config);
    _logger.info('Problem generated (${problem.letters.join()})');
    return problem;
  }
}

///
/// This method returns a letter that do not change the numbers of solutions
/// to the problem.
/// If the method returns null, it means it is not possible to add a useless
/// letter to the problem without changing the number of solutions.
///
/// [letters] is the list of letters to which we want to add a letter
/// [nbLettersInSmallestWord] is the number of letters in the smallest word
/// [nbSolutions] is the number of solutions to the problem before adding the
/// letter (this number is expected to remain after adding the useless letter)
String? _findUselessLetter(
    {required List<String> letters,
    required int nbLettersInSmallestWord,
    required int nbSolutions}) {
  // Create a list of all possible letters to add
  final possibleLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      .split('')
      .where((letter) => !letters.contains(letter))
      .toList();

  do {
    final newLetter =
        possibleLetters.removeAt(_random.nextInt(possibleLetters.length));
    final newLetters = [...letters, newLetter];
    final newSolutions = DictionaryManager.findsWordsFromPermutations(
        from: newLetters, nbLettersOfSmallestWords: nbLettersInSmallestWord);

    if (newSolutions.length == nbSolutions) {
      // The new letter is useless if the number of solutions did not change
      return newLetter;
    }
  } while (possibleLetters.isNotEmpty);

  // If we get here, it means no useless letter could be found
  return null;
}
