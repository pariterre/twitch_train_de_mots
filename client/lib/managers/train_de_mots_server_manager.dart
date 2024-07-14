class TrainDeMotsServerManager {
  // Singleton
  static TrainDeMotsServerManager get instance {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _instance!;
  }

  static TrainDeMotsServerManager? _instance;
  TrainDeMotsServerManager._internal({required Uri uri}) : _uri = uri;

  // Attributes
  final Uri _uri;
  Uri get uri {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _uri;
  }

  // Methods
  static Future<void> initialize({required Uri uri}) async {
    if (_instance != null) return;

    _instance = TrainDeMotsServerManager._internal(uri: uri);
  }
}
