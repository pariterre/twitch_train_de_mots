// TimeoutException

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
