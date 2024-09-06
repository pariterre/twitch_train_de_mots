import 'package:common/models/exceptions.dart';

enum FromManagerToEbsMessages {
  getUserId,
  getDisplayName,
  getLogin;
}

enum FromClientToEbsMessages {
  newLetterProblemRequest,
  pardonStatusUpdate,
  disconnect;
}

enum FromFrontendToEbsMessages {
  registerToGame,
  pardonRequest;

  factory FromFrontendToEbsMessages.fromString(String name) {
    try {
      return FromFrontendToEbsMessages.values
          .firstWhere((e) => name.contains(e.name));
    } catch (e) {
      throw InvalidEndpointException();
    }
  }

  String asEndpoint() => '/$name';
}

enum FromEbsToManagerMessages {
  initialize,
  responseInternal,
  getUserId,
  getDisplayName,
  getLogin;
}

enum FromEbsToClientMessages {
  isConnected,
  ping,
  newLetterProblemGenerated,
  pardonRequest,
  noBroadcasterIdException,
  invalidAlgorithmException,
  invalidTimeoutException,
  invalidConfigurationException,
  unkownMessageException;
}

enum FromEbsToFrontendMessages {
  ping,
  gameStarted,
  pardonStatusUpdate;
}
