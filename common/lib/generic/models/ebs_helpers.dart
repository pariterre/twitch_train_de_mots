///
/// This is a mocker for the shared secret used in the Twitch EBS. This is intended
/// to be used while debugging in local. It should not be used in production.
const mockedSharedSecret = 'qwertyuiopasdfghjklzxcvbnm1234567890';

enum MessagesToFrontend {
  gameStateResponse,
  pardonResponse,
  boostResponse,
}

enum MessagesToApp {
  fullGameStateRequest,
  isExtensionActive,
  tryWord,
  pardonRequest,
  boostRequest,
  bitsRedeemed,
  fireworksRequest,
  attemptTheBigHeist,
  changeLaneRequest,
  fixTracksMiniGameRequest,
  revealTileAt,
  slingShotBlueberryWar,
  slingShotAvatarWareHouse,
}

enum MessagesToEbs {
  opaqueToDisplayName,
  gameStateRequest,
  patchGameState,
  newLetterProblemRequest,
}

enum Sku {
  celebrate,
  bigHeist,
  changeLane,
  fixTracks;

  @override
  String toString() {
    switch (this) {
      case Sku.celebrate:
        return 'celebrate';
      case Sku.bigHeist:
        return 'big_heist';
      case Sku.changeLane:
        return 'change_lane';
      case Sku.fixTracks:
        return 'fix_tracks';
    }
  }

  static Sku fromString(String value) {
    switch (value) {
      case 'celebrate':
        return Sku.celebrate;
      case 'big_heist':
        return Sku.bigHeist;
      case 'change_lane':
        return Sku.changeLane;
      case 'fix_tracks':
        return Sku.fixTracks;
      case _:
        throw Exception('Unknown Sku value: $value');
    }
  }
}
