import 'package:diacritic/diacritic.dart';
import 'package:train_de_mots/models/french_words.dart';

class Solution {
  final String word;
  String? founder;

  int get value =>
      word.split('').map((e) => letterValue(e)).reduce((a, b) => a + b);
  bool get isFound => founder != null;

  Solution({required String word, this.founder})
      : word = removeDiacritics(word.toUpperCase());
}

class Letter {
  final String data;
  final int value;

  Letter(this.data) : value = letterValue(data);
}
