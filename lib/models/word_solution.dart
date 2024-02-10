import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/valuable_letter.dart';

class WordSolution {
  final String word;

  bool get isFound => _foundBy != null;
  Player? _foundBy;
  Player get foundBy => _foundBy!;
  set foundBy(Player player) {
    // If the word was already found, it is now stolen
    if (_foundBy != null) _stolenFrom = _foundBy!;
    _foundBy = player;
    _foundAt = DateTime.now();
  }

  DateTime? _foundAt;
  DateTime get foundAt => _foundAt!;

  bool get wasStolen => _stolenFrom != null;
  Player? _stolenFrom;
  Player get stolenFrom => _stolenFrom!;

  int get value => word
      .split('')
      .map((e) => ValuableLetter.getValueOfLetter(e))
      .reduce((a, b) => a + b);

  WordSolution({required String word})
      : word = removeDiacritics(word.toUpperCase());
}

///
/// Solutions is a collection of solutions
class WordSolutions extends DelegatingList<WordSolution> {
  final List<WordSolution> _solutions;

  ///
  /// Create the delegate (that is _solutions and super._innerList are the same)
  WordSolutions(List<WordSolution>? solutions) : this._(solutions ?? []);
  WordSolutions._(super.solutions) : _solutions = solutions;

  ///
  /// Sort the subWords by length and alphabetically (default)
  @override
  WordSolutions sort([int Function(WordSolution, WordSolution)? compare]) {
    return WordSolutions._(
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
  WordSolutions solutionsOfLength(int length) => WordSolutions(
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
  int get maximumPossibleScore =>
      _solutions.fold(0, (prev, e) => prev + e.value);
}
