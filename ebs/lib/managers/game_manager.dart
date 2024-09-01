import 'dart:isolate';

import 'package:common/models/ebs_messages.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/isolated_games_manager.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the client side. It therefore
/// constantly waits for updates from the client, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// client and the frontends.
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
      await Future.delayed(Duration(seconds: 5));
      sendPort.send({
        'target': MessageTarget.client.index,
        'message': {
          'type': FromEbsMessages.genericMessage.index,
          'data': 'Message to clients'
        }
      });
      sendPort.send({
        'target': MessageTarget.frontend.index,
        'message': {
          'type': FromEbsMessages.genericMessage.index,
          'data': 'Message to frontends'
        }
      });
    }

    _logger.info('Game loop ended for client: $broadcasterId');
  }
}
