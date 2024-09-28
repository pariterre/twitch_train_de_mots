class CustomCallback<T extends Function> {
  final List<T> _listeners = [];

  // Define a mutex to prevent removing listeners while notifying them
  bool _isNotifying = false;

  void addListener(T callback) async {
    while (_isNotifying) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    _listeners.add(callback);
  }

  void removeListener(T callback) async {
    while (_isNotifying) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    _listeners.removeWhere((e) => e == callback);
  }

  Future<void> notifyListeners() async {
    if (_isNotifying) return;
    _isNotifying = true;
    if (_listeners.isNotEmpty) {
      for (final callback in _listeners) {
        callback();
      }
    }
    _isNotifying = false;
  }

  Future<void> notifyListenersWithParameter(parameter) async {
    if (_listeners.isEmpty) return;
    _isNotifying = true;
    for (final callback in _listeners) {
      callback(parameter);
    }
    _isNotifying = false;
  }
}
