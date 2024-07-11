import 'package:diacritic/diacritic.dart';

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
}
