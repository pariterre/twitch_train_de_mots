class Difficulty {
  final double thresholdFactorOneStar;
  final double thresholdFactorTwoStars;
  final double thresholdFactorThreeStars;

  final bool hasUselessLetter;
  final int revealUselessLetterAtTimeLeft;

  final bool hasHiddenLetter;
  final int revealHiddenLetterAtTimeLeft;

  final String? message;

  const Difficulty({
    required this.thresholdFactorOneStar,
    required this.thresholdFactorTwoStars,
    required this.thresholdFactorThreeStars,
    this.message,
    required this.hasUselessLetter,
    this.revealUselessLetterAtTimeLeft = -1,
    required this.hasHiddenLetter,
    this.revealHiddenLetterAtTimeLeft = -1,
  });
}
