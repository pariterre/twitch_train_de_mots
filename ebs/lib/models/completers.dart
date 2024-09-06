import 'dart:async';

class Completers {
  final Map<int, Completer> _completers = {};

  int spawn() {
    final completer = Completer();
    final id = _completers.hashCode;
    _completers[id] = completer;

    completer.future.then((_) => _completers.remove(id));
    return id;
  }

  Completer? get(int id) => _completers[id];

  Completer? pop(int id) => _completers.remove(id);

  void complete(int id, dynamic value) {
    final completer = _completers[id]!;
    completer.complete(value);
  }
}
