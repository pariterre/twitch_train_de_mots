import 'package:common/models/ebs_helpers.dart';

abstract class InvalidMessageException implements Exception {
  @override
  String toString() => 'Invalid message';

  FromEbsToClientMessages get message;
}

class NoBroadcasterIdException implements InvalidMessageException {
  @override
  String toString() => 'No broadcasterId found';

  @override
  FromEbsToClientMessages get message =>
      FromEbsToClientMessages.noBroadcasterIdException;
}

class InvalidAlgorithmException implements InvalidMessageException {
  @override
  String toString() => 'Invalid algorithm';

  @override
  FromEbsToClientMessages get message =>
      FromEbsToClientMessages.invalidAlgorithmException;
}

class InvalidTimeoutException implements InvalidMessageException {
  @override
  String toString() => 'Invalid timeout';

  @override
  FromEbsToClientMessages get message =>
      FromEbsToClientMessages.invalidAlgorithmException;
}

class InvalidConfigurationException implements InvalidMessageException {
  @override
  String toString() => 'Invalid configuration';

  @override
  FromEbsToClientMessages get message =>
      FromEbsToClientMessages.invalidAlgorithmException;
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() {
    return 'TimeoutException: $message';
  }
}

class UnauthorizedException implements Exception {
  UnauthorizedException();

  @override
  String toString() {
    return 'Token verification failed';
  }
}

class InvalidEndpointException implements Exception {
  InvalidEndpointException();

  @override
  String toString() {
    return 'Invalid endpoint';
  }
}

class ConnexionToWebSocketdRefusedException implements Exception {
  ConnexionToWebSocketdRefusedException();

  @override
  String toString() {
    return 'Connexion to WebSocketd refused';
  }
}
