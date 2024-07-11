import 'package:train_de_mots_server/range.dart';

///
/// Placeholder for the definition of a Problem
class Problem {
  ///
  /// The number of letters in the shortest solutions
  final Range lengthShortestSolution;

  ///
  /// The number of letters in the longest solutions
  final Range lengthLongestSolution;

  ///
  /// The number of solutions the problem must have
  final Range nbSolutions;

  ///
  /// The number of useless letters that must be added to the list of letters
  final int nbUselessLetters;

  Problem({
    required this.lengthShortestSolution,
    required this.lengthLongestSolution,
    required this.nbSolutions,
    required this.nbUselessLetters,
  }) {
    if (nbUselessLetters < 0) {
      throw ArgumentError('The number of useless letters should be positive');
    } else if (nbUselessLetters > 1) {
      throw ArgumentError('Only one useless letter is implemented for now');
    }
  }

  ///
  /// The maximum number of true letters in the longest solutions (i.e. without the useless letters)
  int get nbMaxTrueLetters => lengthShortestSolution.max - nbUselessLetters;
}
