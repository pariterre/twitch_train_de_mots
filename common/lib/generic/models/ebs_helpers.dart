enum ToBackendMessages {
  newLetterProblemRequest,
}

enum ToAppMessages {
  gameStateRequest,
  pardonRequest,
  boostRequest,
  bitsRedeemed,
  fireworksRequest,
  attemptTheBigHeist,
  changeLaneRequest,
  revealTileAt,
}

enum ToFrontendMessages {
  gameState,
  pardonResponse,
  boostResponse,
}

enum Sku {
  celebrate,
  bigHeist,
  changeLane;

  @override
  String toString() {
    switch (this) {
      case Sku.celebrate:
        return 'celebrate';
      case Sku.bigHeist:
        return 'big_heist';
      case Sku.changeLane:
        return 'change_lane';
    }
  }

  static fromString(String value) {
    switch (value) {
      case 'celebrate':
        return Sku.celebrate;
      case 'big_heist':
        return Sku.bigHeist;
      case 'change_lane':
        return Sku.changeLane;
    }
  }
}
