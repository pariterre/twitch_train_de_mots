import 'package:common/models/ebs_helpers.dart';

abstract class InvalidMessageException implements Exception {
  @override
  String toString() => 'Invalid message';

  FromEbsToAppMessages get message;
}

class NoBroadcasterIdException implements InvalidMessageException {
  @override
  String toString() => 'No broadcasterId found';

  @override
  FromEbsToAppMessages get message =>
      FromEbsToAppMessages.noBroadcasterIdException;
}

class InvalidAlgorithmException implements InvalidMessageException {
  @override
  String toString() => 'Invalid algorithm';

  @override
  FromEbsToAppMessages get message =>
      FromEbsToAppMessages.invalidAlgorithmException;
}

class InvalidTimeoutException implements InvalidMessageException {
  @override
  String toString() => 'Invalid timeout';

  @override
  FromEbsToAppMessages get message =>
      FromEbsToAppMessages.invalidAlgorithmException;
}

class InvalidConfigurationException implements InvalidMessageException {
  @override
  String toString() => 'Invalid configuration';

  @override
  FromEbsToAppMessages get message =>
      FromEbsToAppMessages.invalidAlgorithmException;
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

class ManagerNotInitializedException implements Exception {
  final String message;

  ManagerNotInitializedException(this.message);

  @override
  String toString() => message;
}

class ManagerAlreadyInitializedException implements Exception {
  final String message;

  ManagerAlreadyInitializedException(this.message);

  @override
  String toString() => message;
}
