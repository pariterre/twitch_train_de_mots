import 'package:train_de_mots/managers/configuration_manager.dart';

enum SuccessLevel {
  failed,
  oneStar,
  twoStars,
  threeStars;

  int toInt() {
    final cm = ConfigurationManager.instance;

    switch (this) {
      case SuccessLevel.failed:
        return 0;
      case SuccessLevel.oneStar:
        return 1;
      case SuccessLevel.twoStars:
        return cm.oneStationMaxPerRound ? 1 : 2;
      case SuccessLevel.threeStars:
        return cm.oneStationMaxPerRound ? 1 : 3;
    }
  }
}
