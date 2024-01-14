class Difficulty {
  final double thresholdFactorOneStar;
  final double thresholdFactorTwoStars;
  final double thresholdFactorThreeStars;

  final bool hasUselessLetter;

  final bool hasHiddenLetter;
  final int revealHiddenLetterAtTimeLeft;

  const Difficulty({
    required this.thresholdFactorOneStar,
    required this.thresholdFactorTwoStars,
    required this.thresholdFactorThreeStars,
    required this.hasUselessLetter,
    required this.hasHiddenLetter,
    this.revealHiddenLetterAtTimeLeft = -1,
  });
}
