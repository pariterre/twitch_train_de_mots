import 'dart:math';

import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots_server/french_words.dart';
import 'package:train_de_mots_server/letter_problem.dart';
import 'package:train_de_mots_server/problem.dart';

final _random = Random();

class ProblemGenerator {
  ///
  /// Generates a new word problem from a random string of letters.
  static Future<LetterProblem?> generateFromRandom(Problem pb) async {
    LetterProblem? finalProblem;

    do {
      // Generate a first candidate set of letters
      List<String> candidateLetters = _WordGenerator.instance
          ._generateRandomLetters(
              nbLetters: pb.lengthLongestSolution.max, useFrequency: false);
      Set<String> solutions;
      String? uselessLetter;

      do {
        // Find all the words that can be made from the candidate letters
        solutions = await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: pb.lengthShortestSolution.max);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (solutions.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (solutions.length < pb.nbSolutions.min ||
            candidateLetters.length < pb.lengthLongestSolution.min) break;

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
      if (!pb.nbSolutions.contains(solutions.length) ||
          candidateLetters.length < pb.lengthLongestSolution.min) {
        continue;
      }

      if (pb.nbUselessLetters > 0) {
        // Add a useless letter to the problem if required
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: pb.lengthShortestSolution.max,
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
    return finalProblem;
  }

  ///
  /// Generates a new word problem from picking a letter, then subsetting the
  /// words and picking a new letter available in the remainning words.
  static Future<LetterProblem?> generateFromBuildingUp(Problem pb) async {
    final random = Random();

    LetterProblem? finalProblem;

    do {
      List<String> candidateLetters = [];

      Set<String> solutions = await _WordGenerator.instance
          .wordsWithAtLeast(pb.lengthShortestSolution.max);
      String? uselessLetter;

      String availableLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      do {
        // From the list of all the remaining letters in the alphabet, pick a random one
        candidateLetters
            .add(availableLetters[random.nextInt(availableLetters.length)]);

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
          solutions.elementAt(random.nextInt(solutions.length)).split('');

      // Get all the possible words from candidate in solutions
      solutions = {};
      if (pb.lengthLongestSolution.contains(candidateLetters.length)) {
        // This takes time, only do it if the candidate is valid
        solutions = (await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: pb.lengthShortestSolution.max));
      }

      // Make sure the number of words as solution is valid
      if (!pb.nbSolutions.contains(solutions.length)) {
        continue;
      }

      if (pb.nbUselessLetters > 0) {
        // Add a useless letter to the problem
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: pb.lengthShortestSolution.max,
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

    return finalProblem;
  }

  ///
  /// Generates a new word problem from a random longest word. Apart from the
  /// randomization of the candidate letters, the algorithm is the same as the
  /// [generateFromRandom] method.
  static Future<LetterProblem?> generateFromRandomWord(Problem pb) async {
    final random = Random();
    final wordsToPickFrom = (await _WordGenerator.instance
            .wordsWithAtLeast(pb.lengthLongestSolution.min))
        .where((e) => e.length <= pb.lengthLongestSolution.max);

    LetterProblem? finalProblem;

    do {
      // Generate a first candidate set of letters
      List<String> candidateLetters = wordsToPickFrom
          .elementAt(random.nextInt(wordsToPickFrom.length))
          .split('');
      Set<String> solutions;
      String? uselessLetter;

      do {
        // Find all the words that can be made from the candidate letters
        solutions = await _WordGenerator.instance._findsWordsFromPermutations(
            from: candidateLetters,
            nbLettersOfSmallestWords: pb.lengthShortestSolution.max);

        // If the longest words is as long as the candidate, we have found
        // a potentially valid candidate set of letters
        if (solutions.fold<int>(
                0, (prev, element) => max(prev, element.length)) ==
            candidateLetters.length) {
          break;
        }

        // If we cut too much, we have to start over
        if (solutions.length < pb.nbSolutions.min ||
            candidateLetters.length < pb.lengthLongestSolution.min) break;

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
      if (!pb.nbSolutions.contains(solutions.length) ||
          candidateLetters.length < pb.lengthLongestSolution.min) {
        continue;
      }

      if (pb.nbUselessLetters > 0) {
        // Add a useless letter to the problem if required
        uselessLetter = await _findUselessLetter(
            letters: candidateLetters,
            nbLettersInSmallestWord: pb.lengthShortestSolution.max,
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
    return finalProblem;
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
  static Future<String?> _findUselessLetter(
      {required List<String> letters,
      required int nbLettersInSmallestWord,
      required int nbSolutions}) async {
    // Create a list of all possible letters to add
    final possibleLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .split('')
        .where((letter) => !letters.contains(letter))
        .toList();

    do {
      final newLetter =
          possibleLetters.removeAt(_random.nextInt(possibleLetters.length));
      final newLetters = [...letters, newLetter];
      final newSolutions = await _WordGenerator.instance
          ._findsWordsFromPermutations(
              from: newLetters,
              nbLettersOfSmallestWords: nbLettersInSmallestWord);

      if (newSolutions.length == nbSolutions) {
        // The new letter is useless if the number of solutions did not change
        return newLetter;
      }
    } while (possibleLetters.isNotEmpty);

    // If we get here, it means no useless letter could be found
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
  /// [from], with at least [nbLettersOfSmallestWords] and at most [from.length] letters.
  Future<Set<String>> _findsWordsFromPermutations({
    required List<String> from,
    int nbLettersOfSmallestWords = 0,
  }) async {
    // First, we remove all the words from the database that contains any letter
    // which is not in the letters set as the words
    final Set<String> words = {};
    for (final word in await wordsWithAtLeast(nbLettersOfSmallestWords)) {
      if (word.split('').every((letter) => from.contains(letter))) {
        words.add(word);
      }
    }

    // Then, count each duplicate letters in each word to make sure at least the
    // same amount of duplicate exists in the letters set
    return words.where((word) {
      final wordAsList = word.split('');
      return wordAsList.every((letter) {
        final countInWord =
            wordAsList.fold<int>(0, (prev, e) => prev + (e == letter ? 1 : 0));
        final countInLetters =
            from.fold<int>(0, (prev, e) => prev + (e == letter ? 1 : 0));
        return countInWord <= countInLetters;
      });
    }).toSet();
  }

  /// Generates a random sequence of letters with the specified number of letters
  List<String> _generateRandomLetters(
      {required int nbLetters, bool useFrequency = true}) {
    if (nbLetters <= 0) {
      throw ArgumentError(
          'Number of letters should be greater than zero and maxLetters should be higher than minLetters');
    }
    List<String> result = [];
    for (int i = 0; i < nbLetters; i++) {
      final letter = useFrequency
          ? _randomLetterFromFrequency
          : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[_random.nextInt(26)];
      result.add(removeDiacritics(letter));
    }
    return result;
  }
}

/// Pick a letter at random based on the frequency of letters in the French.
String get _randomLetterFromFrequency {
  while (true) {
    final val = _random.nextInt(1000);

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
