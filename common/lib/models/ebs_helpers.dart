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
}

enum ToFrontendMessages {
  gameState,
  pardonResponse,
  boostResponse,
}

enum Sku {
  celebrate,
  bigHeist;

  @override
  String toString() {
    switch (this) {
      case Sku.celebrate:
        return 'celebrate';
      case Sku.bigHeist:
        return 'big_heist';
    }
  }

  static fromString(String value) {
    switch (value) {
      case 'celebrate':
        return Sku.celebrate;
      case 'big_heist':
        return Sku.bigHeist;
    }
  }
}
