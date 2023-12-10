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

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({required this.message});

  @override
  String toString() => message;
}
