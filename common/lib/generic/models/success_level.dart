enum SuccessLevel {
  failed,
  oneStar,
  twoStars,
  threeStars,
  bigHeist,
  ;

  int toInt({required bool oneStationMaxPerRound}) {
    switch (this) {
      case SuccessLevel.failed:
        return 0;
      case SuccessLevel.oneStar:
        return 1;
      case SuccessLevel.twoStars:
        return oneStationMaxPerRound ? 1 : 2;
      case SuccessLevel.threeStars:
        return oneStationMaxPerRound ? 1 : 3;
      case SuccessLevel.bigHeist:
        return oneStationMaxPerRound ? 1 : 6;
    }
  }
}
