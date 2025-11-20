import 'dart:math';

import 'package:common/generic/models/random_extension.dart';

final _random = Random();

enum DistributionType {
  uniform,
  skewedTowardsLessValuables,
  skewedTowardsMoreValuables,
}

class ValuableLetter {
  final String data;
  final int value;

  ValuableLetter(this.data) : value = getValueOfLetter(data);

  ///
  /// Returns a random uppercase letter from A to Z
  static String getRandom({
    DistributionType distribution = DistributionType.uniform,
    int maxValue = 10,
  }) {
    while (true) {
      final letter = String.fromCharCode(65 +
          switch (distribution) {
            DistributionType.uniform => _random.nextInt(26),
            DistributionType.skewedTowardsLessValuables =>
              _random.nextSkewedInt(max: 26, skewTowards: 4),
            DistributionType.skewedTowardsMoreValuables =>
              _random.nextSkewedInt(max: 26, skewTowards: 20),
          });
      if (getValueOfLetter(letter) <= maxValue) {
        return letter;
      }
    }
  }

  ///
  /// The value of the letter is the same as the number of points it gives in Scrabble (French)
  static int getValueOfLetter(String letter) {
    switch (letter) {
      case 'A':
      case 'E':
      case 'I':
      case 'L':
      case 'N':
      case 'O':
      case 'R':
      case 'S':
      case 'T':
      case 'U':
        return 1;
      case 'D':
      case 'G':
      case 'M':
        return 2;
      case 'B':
      case 'C':
      case 'P':
        return 3;
      case 'F':
      case 'H':
      case 'V':
        return 4;
      case 'J':
      case 'Q':
        return 8;
      case 'K':
      case 'W':
      case 'X':
      case 'Y':
      case 'Z':
        return 10;
      default:
        throw 'Invalid letter $letter';
    }
  }
}
