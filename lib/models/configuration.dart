class Configuration {
  final int minimumWordsNumber = 8;
  final int maximumWordsNumber = 15;

  static final Configuration _instance = Configuration._internal();
  Configuration._internal();
  static Configuration get instance => _instance;

  Future<void> initialize() async {}
}
