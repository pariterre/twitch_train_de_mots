enum SuccessLevel {
  failed,
  oneStar,
  twoStars,
  threeStars;

  int toInt() {
    switch (this) {
      case SuccessLevel.failed:
        return 0;
      case SuccessLevel.oneStar:
        return 1;
      case SuccessLevel.twoStars:
        return 2;
      case SuccessLevel.threeStars:
        return 3;
    }
  }
}
