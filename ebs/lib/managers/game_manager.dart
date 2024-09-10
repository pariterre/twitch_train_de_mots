import 'dart:async';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
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
  /// Create a new GameManager. This method automatically starts a keep alive
  /// mechanism to keep the connexion alive. If it fails, the game is ended.
  /// [broadcasterId] the id of the broadcaster
  /// [sendPort] the port to communicate with the main manager
  GameManager.clientStartedTheGame(
      {required this.broadcasterId, required SendPort sendPort})
      : communications = GameManagerCommunication(sendPort: sendPort) {
    _logger.info(
        'GameManager created for client: $broadcasterId, starting game loop');
    communications.sendMessageToMain(MessageProtocol(
        target: MessageTargets.frontend,
        fromTo: FromEbsToFrontendMessages.gameStarted));

    // Keep the connexion alive
    _keepAlive();
    Timer.periodic(Duration(minutes: 1), (_) => _keepAlive());
  }

  ///
  /// Handle a message from the frontend to pardon the last stealer
  /// [playerName] the name of the player to pardon
  Future<bool> frontendRequestedToPardon(String playerName) async {
    _logger.info('Resquesting to pardon last stealer');

    return await communications.sendQuestionToMain(MessageProtocol(
        target: MessageTargets.client,
        fromTo: FromEbsToClientMessages.pardonRequest,
        data: {'player_name': playerName}));
  }

  ///
  /// Handle a message from the frontend to register to the game
  /// [userId] the twitch id of the user
  /// [opaqueId] the opaque id of the user (provided by the frontend)
  Future<bool> frontendRegisteredToTheGame(
      {required int userId, required String opaqueId}) async {
    _logger.info('Registering to game');

    // Do not lose time if the user is already registered
    if (_userIdToOpaqueId.containsKey(userId)) return true;

    // Get the login of the user
    final login = await communications.sendQuestionToMain(MessageProtocol(
        target: MessageTargets.main,
        fromTo: FromEbsToMainMessages.getLogin,
        data: {'user_id': userId}));

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

  ///
  /// Handle a message from the client to update the pardonners status.
  /// [pardonnerUserId] the twitch id of the user that can pardon
  Future<void> clientUpdatedPardonnersStatus(String pardonnerUserId) async {
    _logger.info('Last stealer is pardoned');

    if (pardonnerUserId.isEmpty) {
      communications.sendMessageToMain(MessageProtocol(
          target: MessageTargets.frontend,
          fromTo: FromEbsToFrontendMessages.pardonStatusUpdate,
          data: {
            'pardonner_user_id': ['']
          }));
    }

    if (!_loginToUserId.containsKey(pardonnerUserId)) {
      _logger.severe('User $pardonnerUserId is not registered');
      return;
    }

    // Get the opaque id
    final userId = _loginToUserId[pardonnerUserId]!;
    final opaqueId = _userIdToOpaqueId[userId]!;

    communications.sendMessageToMain(MessageProtocol(
        target: MessageTargets.frontend,
        fromTo: FromEbsToFrontendMessages.pardonStatusUpdate,
        data: {
          'pardonner_user_id': [opaqueId]
        }));
  }

  ///
  /// Handle a message from the client to end the game
  Future<void> clientEndedTheGame() async {
    _logger.info('Game ended for client: $broadcasterId');
    communications.sendMessageToMain(MessageProtocol(
      target: MessageTargets.frontend,
      fromTo: FromEbsToFrontendMessages.gameEnded,
    ));
    communications.sendMessageToMain(MessageProtocol(
      target: MessageTargets.client,
      fromTo: FromEbsToClientMessages.disconnect,
    ));
    communications.sendMessageToMain(MessageProtocol(
      target: MessageTargets.main,
      fromTo: FromEbsToMainMessages.canDestroyIsolated,
    ));
  }

  ///
  /// Handle a message from the client to generate a new letter problem
  /// [request] the configuration for the new problem
  Future<LetterProblem> clientRequestedANewLetterProblem(
      Map<String, dynamic> request) async {
    return LetterProblem.generateProblemFromRequest(request);
  }

  ///
  /// Keep the connexion alive. If it fails, the game is ended.
  Future<void> _keepAlive() async {
    _logger.info('Sending keep alive message');
    try {
      final response = await communications
          .sendQuestionToMain(MessageProtocol(
              target: MessageTargets.client,
              fromTo: FromEbsToClientMessages.ping))
          .timeout(Duration(seconds: 30),
              onTimeout: () => {'response': 'NOT PONG'});
      if (response?['response'] != 'PONG') {
        throw Exception('Client is not alive');
      }
    } catch (e) {
      _logger.severe('Client is not alive, ending game');
      clientEndedTheGame();
    }
  }
}

class GameManagerCommunication {
  final SendPort sendPort;
  final completers = Completers();
  Future<void> complete(
      {required int? completerId, required dynamic data}) async {
    if (completerId == null) return;
    completers.get(completerId)?.complete(data);
  }

  GameManagerCommunication({required this.sendPort});

  ///
  /// Send a message to main. The message will be redirected based on the
  /// target field of the message.
  /// [message] the message to send
  void sendMessageToMain(MessageProtocol message) => sendPort.send(message);

  ///
  /// Send a message to main while expecting an actual response. This is
  /// useful when the client needs to wait for a response from the main
  /// [message] the message to send
  /// returns a future that will be completed when the main responds
  Future<dynamic> sendQuestionToMain(MessageProtocol message) {
    final completerId = completers.spawn();
    final completer = completers.get(completerId)!;

    sendPort
        .send(message.copyWith(internalIsolate: {'completer_id': completerId}));

    return completer.future.timeout(Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout'));
  }
}
