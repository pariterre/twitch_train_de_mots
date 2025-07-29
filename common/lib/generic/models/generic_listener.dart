///
/// To specify a specific type of listener, you can instantiate this class
/// as such:
class GenericListener<T extends Function> {
  // Define a mutex to prevent adding/removing listeners while notifying
  bool _isNotifying = false;

  Future<void> _waitForNotifying() async {
    while (_isNotifying) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  ///
  /// Start listening.
  Future<void> listen(T callback) async {
    await _waitForNotifying();
    _listeners.add(callback);
  }

  ///
  /// Stop listening.
  Future<void> cancel(T callback) async {
    await _waitForNotifying();
    _listeners.remove(callback);
  }

  ///
  /// Stop all listeners.
  Future<void> cancelAll() async {
    await _waitForNotifying();
    _listeners.clear();
  }

  ///
  /// Notify all listeners.
  Future<void> notifyListeners(void Function(T) callback) async {
    await _waitForNotifying();
    _isNotifying = true;
    _listeners.forEach(callback);
    _isNotifying = false;
  }

  int get length => _listeners.length;

  ///
  /// List of active listeners to notify.
  final List<T> _listeners = [];

  ///
  /// Copy the listeners from another GenericListener.
  void copyListenersFrom(GenericListener<T> other) {
    _listeners.clear();
    _listeners.addAll(other._listeners);
  }
}
