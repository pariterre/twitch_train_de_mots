import 'dart:async';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/isolated_games_manager.dart';
import 'package:train_de_mots_ebs/models/completers.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the client side. It therefore
/// constantly waits for updates from the client, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// client and the frontends.
class GameManager {
  ///
  /// Ids that interact with the game
  final int broadcasterId;
  final Map<int, String> _userIdToOpaqueId = {};
  final Map<int, String> _userIdToLogin = {};
  final Map<String, int> _opaqueIdToUserId = {};
  final Map<String, int> _loginToUserId = {};

  ///
  /// Communication protocol with main manager
  final GameManagerCommunication communications;

  ///
  /// Game state variables
  bool _isRunning = true;
  Future<void> requestEndOfGame() async => _isRunning = false;

  GameManager({required this.broadcasterId, required SendPort sendPort})
      : communications = GameManagerCommunication(sendPort: sendPort) {
    _logger.info(
        'GameManager created for client: $broadcasterId, starting game loop');
    _gameLoop();
  }

  Future<void> requestPardonStealer(String playerName) async {
    _logger.info('Resquesting to pardon last stealer');

    communications.sendMessageToClient(
        type: FromEbsToClientMessages.pardonRequest,
        data: {'player_name': playerName});
  }

  Future<bool> registerToGame(
      {required int userId, required String opaqueId}) async {
    _logger.info('Registering to game');

    // Do not lose time if the user is already registered
    if (_userIdToOpaqueId.containsKey(userId)) return true;

    // Get the login of the user
    final login = await communications.sendQuestionToManager(
        type: FromEbsToManagerMessages.getLogin, data: {'user_id': userId});
    if (login == null) {
      _logger.severe('Could not get login for user $userId');
      return false;
    }

    // Register the user
    _userIdToOpaqueId[userId] = opaqueId;
    _opaqueIdToUserId[opaqueId] = userId;
    _userIdToLogin[userId] = login;
    _loginToUserId[login] = userId;
    return true;
  }

  Future<void> pardonStatusUpdate(String pardonnerUserId) async {
    _logger.info('Last stealer is pardoned');

    if (pardonnerUserId.isEmpty) {
      communications.sendMessageToFrontend(
          type: FromEbsToFrontendMessages.pardonStatusUpdate,
          data: {
            'pardonner_user_id': ['']
          });
    }

    if (!_loginToUserId.containsKey(pardonnerUserId)) {
      _logger.severe('User $pardonnerUserId is not registered');
      return;
    }

    // Get the opaque id
    final userId = _loginToUserId[pardonnerUserId]!;
    final opaqueId = _userIdToOpaqueId[userId]!;

    communications.sendMessageToFrontend(
        type: FromEbsToFrontendMessages.pardonStatusUpdate,
        data: {
          'pardonner_user_id': [opaqueId]
        });
  }

  Future<LetterProblem> generateProblem(Map<String, dynamic> request) async {
    return LetterProblem.generateProblemFromRequest(request);
  }

  Future<void> _gameLoop() async {
    _logger.info('Game loop started for client: $broadcasterId');

    // Inform the frontend that the game has started and they are required to register
    communications.sendMessageToFrontend(
        type: FromEbsToFrontendMessages.gameStarted);

    while (_isRunning) {
      // Perform game logic
      _logger.info('Game loop tick for client: $broadcasterId');
      await Future.delayed(Duration(seconds: 5));

      // _gameManagerCommunication.sendMessageToClient(type: FromEbsToClientMessages.ping);
      // _gameManagerCommunication.sendMessageToFrontend(type: FromEbsToFrontendMessages.ping);
    }

    _logger.info('Game loop ended for client: $broadcasterId');
  }
}

class GameManagerCommunication {
  final SendPort sendPort;

  GameManagerCommunication({required this.sendPort});

  void sendMessageToClient(
      {required FromEbsToClientMessages type, Map<String, dynamic>? data}) {
    final message = {
      'target': MessageTarget.client.index,
      'message': {'type': type.index, 'data': data}
    };
    sendPort.send(message);
  }

  void sendMessageToFrontend({
    required FromEbsToFrontendMessages type,
    Map<String, dynamic>? data,
  }) {
    final message = {
      'target': MessageTarget.frontend.index,
      'message': {'type': type.index, 'data': data ?? ''},
    };
    sendPort.send(message);
  }

  void sendMessageToManager(
      {required FromEbsToManagerMessages type,
      Map<String, dynamic>? data,
      Map<String, dynamic>? internalMain}) {
    final message = {
      'target': MessageTarget.manager.index,
      'message': {'type': type.index, 'data': data},
      'internal_main': internalMain,
    };
    sendPort.send(message);
  }

  final _completers = Completers();
  Future<dynamic> sendQuestionToManager(
      {required FromEbsToManagerMessages type,
      Map<String, dynamic>? data,
      Map<String, dynamic>? internalMain}) {
    final completerId = _completers.spawn();
    final completer = _completers.get(completerId)!;

    final message = {
      'target': MessageTarget.manager.index,
      'message': {'type': type.index, 'data': data},
      'internal_isolate': {'completer_id': completerId},
      'internal_main': internalMain,
    };
    sendPort.send(message);

    return completer.future;
  }

  Future<void> complete(
      {required int? completerId, required dynamic data}) async {
    if (completerId == null) return;
    _completers.get(completerId)?.complete(data);
  }
}
