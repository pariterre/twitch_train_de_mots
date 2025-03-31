import 'dart:math';

import 'package:common/generic/models/french_words.dart';
import 'package:diacritic/diacritic.dart';

final _random = Random();

class DictionaryManager {
  ///
  /// Returns all the words with at least [nbLetters] letters.
  static Set<String> wordsWithAtLeast(int nbLetters) =>
      DictionaryManager._instance._wordsWithAtLeast(nbLetters);

  ///
  /// Returns all valid words from the permutation of the letters of the word
  /// [from], with at least [nbLettersOfSmallestWords] and at most [from.length] letters.
  static Set<String> findsWordsFromPermutations({
    required List<String> from,
    int nbLettersOfSmallestWords = 0,
  }) {
    // First, we remove all the words from the database that contains any letter
    // which is not in the letters set as the words
    final Set<String> words = {};
    for (final word in DictionaryManager._instance
        ._wordsWithAtLeast(nbLettersOfSmallestWords)) {
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
  static List<String> generateRandomLetters(
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

  // Requesting the "-1" is all the words, any positive number returns a subset
  // of exactly that amount of letters
  final Map<int, Set<String>> _words;

  static final DictionaryManager _instance = DictionaryManager._();
  DictionaryManager._()
      : _words = {
          -1: frenchWords
              .where((e) => !e.contains('-'))
              .map((e) => removeDiacritics(e.toUpperCase()))
              .toSet()
        };

  ///
  /// Returns all the words with at least [nbLetters] letters. This is cached
  /// for performance reasons.
  Set<String> _wordsWithAtLeast(int nbLetters) {
    if (!DictionaryManager._instance._words.keys.contains(nbLetters)) {
      // Create the cache if it does not exist
      DictionaryManager._instance._words[nbLetters] = DictionaryManager
          ._instance._words[-1]!
          .where((e) => e.length >= nbLetters)
          .toSet();
    }

    return DictionaryManager._instance._words[nbLetters]!;
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
