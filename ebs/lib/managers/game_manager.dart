import 'dart:isolate';

import 'package:logging/logging.dart';

final _logger = Logger('GameManager');

class GameManager {
  final int broadcasterId;
  final SendPort sendPort;

  bool _isRunning = true;

  GameManager({required this.broadcasterId, required this.sendPort}) {
    _logger.info(
        'GameManager created for client: $broadcasterId, starting game loop');
    _gameLoop();
  }

  void requestEndOfGame() {
    _isRunning = false;
  }

  Future<void> _gameLoop() async {
    _logger.info('Game loop started for client: $broadcasterId');

    while (_isRunning) {
      // Perform game logic
      _logger.info('Game loop tick for client: $broadcasterId');
      await Future.delayed(Duration(seconds: 1));
    }

    _logger.info('Game loop ended for client: $broadcasterId');
  }
}
