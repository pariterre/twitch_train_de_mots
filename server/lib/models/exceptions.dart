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
