import 'package:common/models/ebs_messages.dart';

abstract class InvalidMessageException implements Exception {
  @override
  String toString() => 'Invalid message';

  FromEbsMessages get message;
}

class NoBroadcasterIdException implements InvalidMessageException {
  @override
  String toString() => 'No broadcasterId found';

  @override
  FromEbsMessages get message => FromEbsMessages.noBroadcasterIdException;
}

class InvalidAlgorithmException implements InvalidMessageException {
  @override
  String toString() => 'Invalid algorithm';

  @override
  FromEbsMessages get message => FromEbsMessages.invalidAlgorithmException;
}

class InvalidTimeoutException implements InvalidMessageException {
  @override
  String toString() => 'Invalid timeout';

  @override
  FromEbsMessages get message => FromEbsMessages.invalidAlgorithmException;
}

class InvalidConfigurationException implements InvalidMessageException {
  @override
  String toString() => 'Invalid configuration';

  @override
  FromEbsMessages get message => FromEbsMessages.invalidAlgorithmException;
}
