enum ToEbsMessages {
  newLetterProblemRequest,
  disconnect;
}

enum FromEbsMessages {
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

  FromEbsMessages get message;
}

class NoBroadcasterIdException implements InvalidMessageException {
  @override
  String toString() => 'No broadcasterId found';

  @override
  FromEbsMessages get message => FromEbsMessages.NoBroadcasterIdException;
}

class InvalidAlgorithmException implements InvalidMessageException {
  @override
  String toString() => 'Invalid algorithm';

  @override
  FromEbsMessages get message => FromEbsMessages.InvalidAlgorithmException;
}

class InvalidTimeoutException implements InvalidMessageException {
  @override
  String toString() => 'Invalid timeout';

  @override
  FromEbsMessages get message => FromEbsMessages.InvalidAlgorithmException;
}

class InvalidConfigurationException implements InvalidMessageException {
  @override
  String toString() => 'Invalid configuration';

  @override
  FromEbsMessages get message => FromEbsMessages.InvalidAlgorithmException;
}
