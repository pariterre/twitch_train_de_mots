enum GameClientToServerMessages {
  newLetterProblemRequest,
  disconnect;
}

enum GameServerToClientMessages {
  isConnected,
  newLetterProblemGenerated,
  NoBroadcasterIdException,
  InvalidAlgorithmException,
  InvalidTimeoutException,
  InvalidConfigurationException,
  UnkownMessageException;
}

abstract class InvalidMessageException implements Exception {
  @override
  String toString() => 'Invalid message';

  GameServerToClientMessages get message;
}

class NoBroadcasterIdException implements InvalidMessageException {
  @override
  String toString() => 'No broadcasterId found';

  @override
  GameServerToClientMessages get message =>
      GameServerToClientMessages.NoBroadcasterIdException;
}

class InvalidAlgorithmException implements InvalidMessageException {
  @override
  String toString() => 'Invalid algorithm';

  @override
  GameServerToClientMessages get message =>
      GameServerToClientMessages.InvalidAlgorithmException;
}

class InvalidTimeoutException implements InvalidMessageException {
  @override
  String toString() => 'Invalid timeout';

  @override
  GameServerToClientMessages get message =>
      GameServerToClientMessages.InvalidAlgorithmException;
}

class InvalidConfigurationException implements InvalidMessageException {
  @override
  String toString() => 'Invalid configuration';

  @override
  GameServerToClientMessages get message =>
      GameServerToClientMessages.InvalidAlgorithmException;
}
