import 'dart:async';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/isolated_games_manager.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the client side. It therefore
/// constantly waits for updates from the client, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// client and the frontends.
class GameManager {
  final int broadcasterId;
  final SendPort _sendPort;
  final Map<int, Completer> _completers = {};
  int addCompleter() {
    final completer = Completer();
    final id = _completers.hashCode;
    _completers[id] = completer;
    return id;
  }

  final Map<String, int> loginToId = {};

  void completeCompleter(int id, dynamic value) {
    final completer = _completers[id]!;
    completer.complete(value);
  }

  Completer popCompleter(int id) {
    final completer = _completers.remove(id);
    if (completer == null) {
      throw Exception('Completer not found');
    }
    return completer;
  }

  bool _isRunning = true;

  GameManager({required this.broadcasterId, required SendPort sendPort})
      : _sendPort = sendPort {
    _logger.info(
        'GameManager created for client: $broadcasterId, starting game loop');
    _gameLoop();
  }

  Future<void> requestEndOfGame() async {
    _isRunning = false;
  }

  Future<void> requestPardonStealer(String playerName) async {
    _logger.info('Resquesting to pardon last stealer');

    sendMessageToClient(
        type: FromEbsToClientMessages.pardonRequest,
        data: {'player_name': playerName});
  }

  Future<void> pardonStatusUpdate(String loginWhoCanPardon) async {
    _logger.info('Last stealer is pardoned');

    int userId = -1;
    if (loginWhoCanPardon.isNotEmpty) {
      userId = loginToId[loginWhoCanPardon] ?? -1;
      if (userId < 0) {
        userId = await sendQuestionToManager(
                type: FromEbsToManagerMessages.getUserId,
                data: {'login': loginWhoCanPardon}) ??
            -1;
        if (userId >= 0) loginToId[loginWhoCanPardon] = userId;
      }
    }
    sendMessageToFrontend(
        type: FromEbsToFrontendMessages.pardonStatusUpdate,
        data: {
          'users_who_can_pardon': [userId]
        });
  }

  Future<LetterProblem> generateProblem(Map<String, dynamic> request) async {
    return LetterProblem.generateProblemFromRequest(request);
  }

  Future<void> _gameLoop() async {
    _logger.info('Game loop started for client: $broadcasterId');

    while (_isRunning) {
      // Perform game logic
      _logger.info('Game loop tick for client: $broadcasterId');
      await Future.delayed(Duration(seconds: 5));

      // sendMessageToClient(type: FromEbsToClientMessages.ping);
      // sendMessageToFrontend(type: FromEbsToFrontendMessages.ping);
    }

    _logger.info('Game loop ended for client: $broadcasterId');
  }

  void sendMessageToClient(
      {required FromEbsToClientMessages type, Map<String, dynamic>? data}) {
    final message = {
      'target': MessageTarget.client.index,
      'message': {'type': type.index, 'data': data}
    };
    _sendPort.send(message);
  }

  void sendMessageToFrontend(
      {required FromEbsToFrontendMessages type, Map<String, dynamic>? data}) {
    final message = {
      'target': MessageTarget.frontend.index,
      'message': {'type': type.index, 'data': data ?? ''}
    };
    _sendPort.send(message);
  }

  void sendMessageToManager(
      {required FromEbsToManagerMessages type, Map<String, dynamic>? data}) {
    final message = {
      'target': MessageTarget.manager.index,
      'message': {'type': type.index, 'data': data}
    };
    _sendPort.send(message);
  }

  Future<dynamic> sendQuestionToManager(
      {required FromEbsToManagerMessages type, Map<String, dynamic>? data}) {
    final completerId = addCompleter();
    final completer = _completers[completerId]!;

    final message = {
      'target': MessageTarget.manager.index,
      'message': {'type': type.index, 'data': data, 'completer_id': completerId}
    };
    _sendPort.send(message);

    completer.future.then((value) {
      _completers.remove(completerId);
    });
    return completer.future;
  }
}
