class TrainDeMotsServerManager {
  // Singleton
  static final TrainDeMotsServerManager instance =
      TrainDeMotsServerManager._internal();
  factory TrainDeMotsServerManager() => instance;
  TrainDeMotsServerManager._internal();

  // Attributes
  bool _initialized = false;
  late final Uri _uri;
  Uri get uri {
    if (!_initialized) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _uri;
  }

  // Methods
  Future<void> initialize({required Uri uri}) async {
    if (_initialized) {
      return;
    }

    _uri = uri;

    _initialized = true;
  }
}
