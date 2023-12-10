class ManagerNotInitializedException implements Exception {
  final String message;

  ManagerNotInitializedException(this.message);

  @override
  String toString() => message;
}
