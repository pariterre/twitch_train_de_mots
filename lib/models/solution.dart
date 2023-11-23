import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/letter.dart';
import 'package:train_de_mots/models/player.dart';

class Solution {
  final String word;

  bool wasStolen = false;
  Player? foundBy;

  int get value =>
      word
          .split('')
          .map((e) => Letter.getValueOfLetter(e))
          .reduce((a, b) => a + b) ~/
      (wasStolen ? 2 : 1);
  bool get isFound => foundBy != null;

  Solution({required String word, this.foundBy})
      : word = removeDiacritics(word.toUpperCase());
}

///
/// Solutions is a collection of solutions
class Solutions extends DelegatingList<Solution> {
  final List<Solution> _solutions;

  ///
  /// Create the delegate (that is _solutions and super._innerList are the same)
  Solutions(List<Solution>? solutions) : this._(solutions ?? []);
  Solutions._(List<Solution> solutions)
      : _solutions = solutions,
        super(solutions);

  ///
  /// Sort the subWords by length and alphabetically (default)
  @override
  Solutions sort([int Function(Solution, Solution)? compare]) {
    return Solutions._(
      [..._solutions]..sort(compare ??
          (a, b) {
            if (a.word.length == b.word.length) {
              return a.word.compareTo(b.word);
            }
            return a.word.length - b.word.length;
          }),
    );
  }

  ///
  /// Return a new Solutions with only the solutions of the given length
  Solutions solutionsOfLength(int length) => Solutions(
      _solutions.where((element) => element.word.length == length).toList());

  ///
  /// Get the number of letters in the smallest word
  int get nbLettersInSmallest => _solutions.fold<int>(
      100,
      (previousValue, element) => previousValue < element.word.length
          ? previousValue
          : element.word.length);

  ///
  /// Get the number of letters in the longest word
  int get nbLettersInLongest => _solutions.fold<int>(
      0,
      (previousValue, element) => previousValue > element.word.length
          ? previousValue
          : element.word.length);

  ///
  /// Get the maximum possible score for this solution
  int get maximumPossibleScore => _solutions.fold<int>(
      0, (previousValue, element) => previousValue + element.value);
}
