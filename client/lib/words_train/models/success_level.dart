import 'package:train_de_mots/generic/managers/managers.dart';

enum SuccessLevel {
  failed,
  oneStar,
  twoStars,
  threeStars,
  bigHeist,
  ;

  int toInt() {
    final cm = Managers.instance.configuration;

    switch (this) {
      case SuccessLevel.failed:
        return 0;
      case SuccessLevel.oneStar:
        return 1;
      case SuccessLevel.twoStars:
        return cm.oneStationMaxPerRound ? 1 : 2;
      case SuccessLevel.threeStars:
        return cm.oneStationMaxPerRound ? 1 : 3;
      case SuccessLevel.bigHeist:
        return cm.oneStationMaxPerRound ? 1 : 6;
    }
  }
}
