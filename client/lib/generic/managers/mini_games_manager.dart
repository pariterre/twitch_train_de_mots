import 'package:train_de_mots/generic/models/mini_games.dart';

abstract class MiniGameManager {
  int get timeRemaining;
}

class MiniGamesManager {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  static Future<MiniGamesManager> factory() async {
    final instance = MiniGamesManager._();
    instance._isInitialized = true;
    return instance;
  }

  MiniGamesManager._();

  final Map<MiniGames, MiniGameManager> _miniGames = {};

  ///
  /// Run a mini game, returns
  void run(MiniGames game) {
    if (_miniGames[game] == null) {
      throw Exception('Mini game $game is not implemented.');
    }
    _currentGame = game;
  }

  MiniGames? _currentGame;
  MiniGameManager? get current => _miniGames[_currentGame];
}
