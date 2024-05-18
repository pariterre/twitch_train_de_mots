class Difficulty {
  final double thresholdFactorOneStar;
  final double thresholdFactorTwoStars;
  final double thresholdFactorThreeStars;

  final bool hasUselessLetter;
  final int revealUselessLetterAtTimeLeft;

  final bool hasHiddenLetter;
  final int revealHiddenLetterAtTimeLeft;

  final int nbLettersOfShortestWord;
  final int nbLettersMinToDraw;
  final int nbLettersMaxToDraw;

  final String? message;

  const Difficulty({
    required this.nbLettersOfShortestWord,
    required this.nbLettersMinToDraw,
    required this.nbLettersMaxToDraw,
    required this.thresholdFactorOneStar,
    required this.thresholdFactorTwoStars,
    required this.thresholdFactorThreeStars,
    this.message,
    required this.hasUselessLetter,
    this.revealUselessLetterAtTimeLeft = -1,
    required this.hasHiddenLetter,
    this.revealHiddenLetterAtTimeLeft = -1,
  });

  bool hasSameRulesForPickingLetters(covariant Difficulty other) {
    if (identical(this, other)) return true;

    return hasUselessLetter == other.hasUselessLetter &&
        nbLettersOfShortestWord == other.nbLettersOfShortestWord &&
        nbLettersMinToDraw == other.nbLettersMinToDraw &&
        nbLettersMaxToDraw == other.nbLettersMaxToDraw;
  }
}
