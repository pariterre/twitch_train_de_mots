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
  pardonRequest;
}

enum FromEbsToManagerMessages {
  initialize,
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
  pardonStatusUpdate;
}

enum FrontendHttpGetEndpoints {
  initialize;

  factory FrontendHttpGetEndpoints.fromString(String name) {
    try {
      return FrontendHttpGetEndpoints.values
          .firstWhere((e) => name.contains(e.toString()));
    } catch (e) {
      throw InvalidEndpointException();
    }
  }

  @override
  String toString() => '/$name';
}

enum FrontendHttpPostEndpoints {
  pardon,
  dummyRequest;

  factory FrontendHttpPostEndpoints.fromString(String name) {
    try {
      return FrontendHttpPostEndpoints.values
          .firstWhere((e) => name.contains(e.toString()));
    } catch (e) {
      throw InvalidEndpointException();
    }
  }

  @override
  String toString() => '/$name';
}
