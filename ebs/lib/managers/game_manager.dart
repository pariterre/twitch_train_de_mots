import 'dart:async';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/game_status.dart';
import 'package:logging/logging.dart';

import 'package:train_de_mots_ebs/models/completers.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the App side. It therefore
/// constantly waits for updates from the App, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// App and the Frontends.
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
  /// Holds the current state of the game
  SimplifiedGameState _gameState = SimplifiedGameState(
    status: GameStatus.initializing,
    round: 0,
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
  );
  SimplifiedGameState get gameState => _gameState;

  ///
  /// Create a new GameManager. This method automatically starts a keep alive
  /// mechanism to keep the connexion alive. If it fails, the game is ended.
  /// [broadcasterId] the id of the broadcaster
  /// [sendPort] the port to communicate with the main manager
  GameManager.appStartedTheGame(
      {required this.broadcasterId, required SendPort sendPort})
      : communications = GameManagerCommunication(sendPort: sendPort) {
    // Set up the logger
    Logger.root.onRecord.listen((record) => print(
        '${record.time} - BroadcasterId: $broadcasterId - ${record.message}'));

    _logger.info(
        'GameManager created for streamer: $broadcasterId, starting game loop');
    communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.frontend,
        fromTo: FromEbsToFrontendMessages.streamHasConnected));

    // Keep the connexion alive
    _keepAlive(null);
    Timer.periodic(Duration(minutes: 1), _keepAlive);
  }

  Future<void> appUpdatedGameState(SimplifiedGameState gameState) async {
    _logger.info('Updating game state to $gameState');
    _gameState = gameState;
    await sendGameStateToFrontend();
  }

  Future<void> sendGameStateToFrontend() async {
    _logger.info('Sending game state to frontend');

    communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.frontend,
        fromTo: FromEbsToFrontendMessages.gameStateUpdate,
        data: {'game_state': _gameState.serialize()}));
  }

  ///
  /// Handle a message from the App to end the game
  Future<void> appEndedTheGame() async {
    _logger.info('Game ended for streamer: $broadcasterId');
    communications.sendMessageViaMain(MessageProtocol(
      target: MessageTargets.frontend,
      fromTo: FromEbsToFrontendMessages.streamerHasDisconnected,
    ));
    communications.sendMessageViaMain(MessageProtocol(
      target: MessageTargets.app,
      fromTo: FromEbsToAppMessages.disconnect,
    ));
    communications.sendMessageViaMain(MessageProtocol(
      target: MessageTargets.main,
      fromTo: FromEbsToMainMessages.canDestroyIsolated,
    ));
  }

  ///
  /// Handle a message from the App to generate a new letter problem
  /// [request] the configuration for the new problem
  Future<LetterProblem> appRequestedANewLetterProblem(
      Map<String, dynamic> request) async {
    _logger.info('Generating a new letter problem');
    return LetterProblem.generateProblemFromRequest(request);
  }

  ///
  /// Handle a message from the frontend to pardon the last stealer
  /// [userId] the id of the user that wants to pardon
  Future<bool> frontendRequestedToPardon(int userId) async {
    _logger.info('Resquesting to pardon last stealer');

    final playerName = _userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    return await communications.sendQuestionToMain(MessageProtocol(
        target: MessageTargets.app,
        fromTo: FromEbsToAppMessages.pardonRequest,
        data: {'player_name': playerName}));
  }

  ///
  /// Handle a message from the frontend to boost the train
  /// [userId] the id of the user that wants to pardon
  Future<bool> frontendRequestedToBoost(int userId) async {
    _logger.info('Resquesting to boost the train');

    final playerName = _userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    return await communications.sendQuestionToMain(MessageProtocol(
        target: MessageTargets.app,
        fromTo: FromEbsToAppMessages.boostRequest,
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
  /// Keep the connexion alive. If it fails, the game is ended.
  Future<void> _keepAlive(Timer? keepGameManagerAlive) async {
    try {
      _logger.info('PING');
      final response = await communications
          .sendQuestionToMain(MessageProtocol(
              target: MessageTargets.app, fromTo: FromEbsToAppMessages.ping))
          .timeout(Duration(seconds: 30),
              onTimeout: () => {'response': 'NOT PONG'});
      if (response?['response'] != 'PONG') {
        throw Exception('No pong');
      }
      _logger.info('PONG');
    } catch (e) {
      _logger.severe('App missed the ping, closing connexion');
      keepGameManagerAlive?.cancel();
      appEndedTheGame();
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
  void sendMessageViaMain(MessageProtocol message) => sendPort.send(message);

  ///
  /// Send a message to main while expecting an actual response. This is
  /// useful we needs to wait for a response from the main.
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
