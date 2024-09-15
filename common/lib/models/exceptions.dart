abstract class TrainDeMotsException implements Exception {}

class NoBroadcasterIdException implements TrainDeMotsException {
  @override
  String toString() => 'No broadcasterId found';
}

class InvalidAlgorithmException implements TrainDeMotsException {
  @override
  String toString() => 'Invalid algorithm';
}

class InvalidConfigurationException implements TrainDeMotsException {
  @override
  String toString() => 'Invalid configuration';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() {
    return 'TimeoutException: $message';
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
