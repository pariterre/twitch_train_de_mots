import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/game_status.dart';
import 'package:logging/logging.dart';

import 'package:train_de_mots_ebs/models/letter_problem.dart';
import 'package:twitch_manager/models/ebs/ebs_exceptions.dart';
import 'package:twitch_manager/twitch_manager.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the App side. It therefore
/// constantly waits for updates from the App, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// App and the Frontends.
class GameManager extends IsolatedInstanceManagerAbstract {
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
  GameManager({required super.broadcasterId, required super.ebsInfo})
      : super() {
    // Set up the logger
    Logger.root.onRecord.listen((record) => print(
        '${record.time} - BroadcasterId: $broadcasterId - ${record.message}'));

    communicator.sendMessageViaMain(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.frontend,
        type: MessageTypes.put,
        data: {'type': ToFrontendMessages.streamerHasConnected}));
  }

  Future<void> _sendGameStateToFrontend() async {
    _logger.info('Sending game state to frontend');

    communicator.sendMessageViaMain(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.frontend,
        type: MessageTypes.put,
        data: {
          'type': ToFrontendMessages.gameState,
          'game_state': _gameState.serialize()
        }));
  }

  ///
  /// Handle a message from the App to generate a new letter problem
  /// [request] the configuration for the new problem
  Future<LetterProblem> _appRequestedANewLetterProblem(
      Map<String, dynamic> request) async {
    _logger.info('Generating a new letter problem');
    return LetterProblem.generateProblemFromRequest(request);
  }

  ///
  /// Handle a message from the frontend to pardon the last stealer
  /// [userId] the id of the user that wants to pardon
  Future<bool> _frontendRequestedPardonned(int userId) async {
    _logger.info('Resquesting to pardon last stealer');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    return await communicator.sendQuestionViaMain(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.ebsMain,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.pardonRequest,
          'player_name': playerName
        }));
  }

  ///
  /// Handle a message from the frontend to boost the train
  /// [userId] the id of the user that wants to pardon
  Future<bool> _frontendRequestedBoosted(int userId) async {
    _logger.info('Resquesting to boost the train');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    return await communicator.sendQuestionViaMain(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.app,
        type: MessageTypes.get,
        data: {'type': ToAppMessages.boostRequest, 'player_name': playerName}));
  }

  @override
  Future<void> handlePutRequest(MessageProtocol message) async =>
      await _handleRequest(message);

  @override
  Future<void> handleGetRequest(MessageProtocol message) async =>
      await _handleRequest(message);

  Future<void> _handleRequest(MessageProtocol message) async {
    final from = message.from;

    switch (from) {
      case MessageFrom.app:
        await _handleMessageFromApp(message);
        break;
      case MessageFrom.frontend:
        await _handleMessageFromFrontend(message);
        break;
      case MessageFrom.ebsMain:
      case MessageFrom.ebsIsolated:
      case MessageFrom.generic:
        throw InvalidEndpointException();
    }
  }

  Future<void> _handleMessageFromApp(MessageProtocol message) async {
    try {
      switch (message.data!['type'] as ToBackendMessages) {
        case ToBackendMessages.newLetterProblemRequest:
          final letterProblem = await _appRequestedANewLetterProblem(
              message.data!['request'] as Map<String, dynamic>);
          communicator.sendMessageViaMain(message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.app,
              type: MessageTypes.response,
              isSuccess: true,
              data: {'letter_problem': letterProblem.serialize()}));
          break;
      }
    } catch (e) {
      communicator.sendErrorReponse(
          message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.app,
              type: MessageTypes.response),
          e.toString());
    }
  }

  Future<void> _handleMessageFromFrontend(MessageProtocol message) async {
    // Helper function to send a response to the frontend

    late final int userId;
    try {
      userId = message.data!['user_id']!;
    } catch (e) {
      return communicator.sendErrorReponse(message, 'user_id not found');
    }

    try {
      if (message.to == MessageTo.ebsIsolated) {
        switch (message.data!['type'] as ToBackendMessages) {
          case ToBackendMessages.newLetterProblemRequest:
            communicator.sendErrorReponse(
                message, 'Wrong message from frontend');
            break;
        }
      } else if (message.to == MessageTo.app) {
        switch (message.data!['type'] as ToAppMessages) {
          case ToAppMessages.gameStateRequest:
            communicator.sendReponse(message.copyWith(
                from: MessageFrom.ebsIsolated,
                to: MessageTo.frontend,
                type: MessageTypes.response,
                isSuccess: true,
                data: {'game_state': gameState.serialize()}));
          case ToAppMessages.pardonRequest:
            communicator.sendReponse(message.copyWith(
                from: MessageFrom.ebsIsolated,
                to: MessageTo.frontend,
                type: MessageTypes.response,
                isSuccess: await _frontendRequestedPardonned(userId)));
          case ToAppMessages.boostRequest:
            communicator.sendReponse(message.copyWith(
                from: MessageFrom.ebsIsolated,
                to: MessageTo.frontend,
                type: MessageTypes.response,
                isSuccess: await _frontendRequestedBoosted(userId)));
        }
      } else {
        throw InvalidTargetException();
      }
    } catch (e) {
      return communicator.sendErrorReponse(message, e.toString());
    }
  }
}
