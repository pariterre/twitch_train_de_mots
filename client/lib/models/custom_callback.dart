class CustomCallback<T extends Function> {
  final List<T> _listeners = [];

  void addListener(T callback) => _listeners.add(callback);

  void removeListener(T callback) =>
      _listeners.removeWhere((e) => e == callback);

  void notifyListeners() {
    for (final callback in _listeners) {
      callback();
    }
  }

  void notifyListenersWithParameter(parameter) {
    for (final callback in _listeners) {
      callback(parameter);
    }
  }
}
