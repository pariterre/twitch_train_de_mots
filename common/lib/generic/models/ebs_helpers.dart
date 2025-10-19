///
/// This is a mocker for the shared secret used in the Twitch EBS. This is intended
/// to be used while debugging in local. It should not be used in production.
const mockedSharedSecret = 'qwertyuiopasdfghjklzxcvbnm1234567890';

enum ToBackendMessages {
  newLetterProblemRequest,
}

enum ToAppMessages {
  isExtensionActive,
  gameStateRequest,
  tryWord,
  pardonRequest,
  boostRequest,
  bitsRedeemed,
  fireworksRequest,
  attemptTheBigHeist,
  changeLaneRequest,
  revealTileAt,
  slingShootBlueberry,
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
