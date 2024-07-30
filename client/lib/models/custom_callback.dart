class CustomCallback<T extends Function> {
  final List<T> _listeners = [];

  void addListener(T callback) => _listeners.add(callback);

  void removeListener(T callback) =>
      _listeners.removeWhere((e) => e == callback);

  Future<void> notifyListeners() async {
    for (final callback in _listeners) {
      callback();
    }
  }

  Future<void> notifyListenersWithParameter(parameter) async {
    for (final callback in _listeners) {
      callback(parameter);
    }
  }
}
