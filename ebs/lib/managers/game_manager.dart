import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/game_status.dart';
import 'package:logging/logging.dart';

import 'package:train_de_mots_ebs/models/letter_problem.dart';
import 'package:twitch_manager/twitch_ebs.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the App side. It therefore
/// constantly waits for updates from the App, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// App and the Frontends.
class GameManager extends TwitchEbsManagerAbstract {
  ///
  /// Holds the current state of the game
  SimplifiedGameState _gameState = SimplifiedGameState(
    status: GameStatus.initializing,
    round: 0,
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
    boosters: [],
    canAttemptTheBigHeist: false,
    isAttemptingTheBigHeist: false,
  );
  SimplifiedGameState get gameState => _gameState;
  set gameState(SimplifiedGameState value) {
    _gameState = value;

    // Convert the pardonners from login to opaque id
    for (int i = 0; i < _gameState.pardonners.length; i++) {
      final pardonnerId = loginToUserId[_gameState.pardonners[i]] ?? -1;
      _gameState.pardonners[i] = userIdToOpaqueId[pardonnerId] ?? '';
    }

    // Convert the boosters from login to opaque id
    for (int i = 0; i < _gameState.boosters.length; i++) {
      final boosterId = loginToUserId[_gameState.boosters[i]] ?? -1;
      _gameState.boosters[i] = userIdToOpaqueId[boosterId] ?? '';
    }
  }

  ///
  /// Create a new GameManager. This method automatically starts a keep alive
  /// mechanism to keep the connexion alive. If it fails, the game is ended.
  /// [broadcasterId] the id of the broadcaster.
  /// [ebsInfo] the configuration of the EBS.
  GameManager.spawn({
    required int broadcasterId,
    required super.ebsInfo,
    required super.sendPort,
  }) : super(broadcasterId: broadcasterId) {
    // Set up the logger
    Logger.root.onRecord.listen((record) => print(
        '${record.time} - BroadcasterId: $broadcasterId - ${record.message}'));

    _logger.info('Sending welcome message');
    TwitchApi.instance.sendChatMessage('Bienvenue au Train de mots!');
  }

  Future<void> _sendGameStateToFrontend() async {
    _logger.info('Sending game state to frontend');

    communicator.sendMessage(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.frontend,
        type: MessageTypes.put,
        data: {
          'type': ToFrontendMessages.gameState.name,
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
  Future<bool> _frontendRequestedToPardon(int userId) async {
    _logger.info('Resquesting to pardon last stealer');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.app,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.pardonRequest.name,
          'player_name': playerName
        }));
    if (response.isSuccess ?? false) {
      _gameState.pardonRemaining--;
      _gameState.pardonners.remove(userIdToOpaqueId[userId]);
    }
    return response.isSuccess ?? false;
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

    final response = await communicator.sendQuestion(MessageProtocol(
        from: MessageFrom.ebsIsolated,
        to: MessageTo.app,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.boostRequest.name,
          'player_name': playerName
        }));
    final isSuccess = response.isSuccess ?? false;
    if (isSuccess) {
      _gameState.boostStillNeeded--;
      _gameState.boosters.add(userIdToOpaqueId[userId] ?? '');
    }

    return isSuccess;
  }

  @override
  Future<void> handlePutRequest(MessageProtocol message) async =>
      await _handleRequest(message);

  @override
  Future<void> handleGetRequest(MessageProtocol message) async =>
      await _handleRequest(message);

  @override
  Future<void> handleBitsTransaction(MessageProtocol message,
      ExtractedTransactionReceipt transactionReceipt) async {
    await _handleRequest(message, transactionReceipt);
  }

  Future<void> _handleRequest(MessageProtocol message,
      [ExtractedTransactionReceipt? transactionReceipt]) async {
    switch (message.from) {
      case MessageFrom.app:
        await _handleMessageFromApp(message);
        break;
      case MessageFrom.frontend:
        await _handleMessageFromFrontend(message, transactionReceipt);
        break;
      case MessageFrom.ebsMain:
      case MessageFrom.ebsIsolated:
      case MessageFrom.generic:
        throw 'Request not supported';
    }
  }

  Future<void> _handleMessageFromApp(MessageProtocol message) async {
    try {
      switch (message.to) {
        case MessageTo.ebsIsolated:
          switch (ToBackendMessages.values.byName(message.data!['type'])) {
            case ToBackendMessages.newLetterProblemRequest:
              final letterProblem = await _appRequestedANewLetterProblem(
                  message.data!['configuration'] as Map<String, dynamic>);
              communicator.sendMessage(message.copyWith(
                  from: MessageFrom.ebsIsolated,
                  to: MessageTo.app,
                  type: MessageTypes.response,
                  isSuccess: true,
                  data: {'letter_problem': letterProblem.serialize()}));
              break;
          }
          break;
        case MessageTo.frontend:
          switch (ToFrontendMessages.values.byName(message.data!['type'])) {
            case ToFrontendMessages.gameState:
              gameState = SimplifiedGameState.deserialize(
                  message.data!['game_state'] as Map<String, dynamic>);
              _sendGameStateToFrontend();
              break;
            case ToFrontendMessages.pardonResponse:
              break;
            case ToFrontendMessages.boostResponse:
              break;
          }
          break;
        case MessageTo.app:
        case MessageTo.generic:
        case MessageTo.ebsMain:
          throw 'Request not supported';
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

  Future<void> _handleMessageFromFrontend(MessageProtocol message,
      ExtractedTransactionReceipt? transactionReceipt) async {
    // Helper function to send a response to the frontend
    late final int userId;
    try {
      userId = message.data!['user_id']!;
    } catch (e) {
      return communicator.sendErrorReponse(message, 'user_id not found');
    }

    try {
      if (message.to != MessageTo.app) {
        throw 'Request not supported';
      }

      switch (ToAppMessages.values.byName(message.data!['type'])) {
        case ToAppMessages.gameStateRequest:
          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: true,
              data: {'game_state': gameState.serialize()}));
          break;

        case ToAppMessages.pardonRequest:
          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: await _frontendRequestedToPardon(userId)));
          break;

        case ToAppMessages.boostRequest:
          final isSuccess = await _frontendRequestedBoosted(userId);
          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: isSuccess));
          break;

        case ToAppMessages.fireworksRequest:
        case ToAppMessages.attemptTheBigHeist:
          throw 'Request is supposed to come from bit transaction';

        case ToAppMessages.bitsRedeemed:
          // This is expected to be from bits transaction
          if (transactionReceipt == null) throw 'Bits transaction not found';

          // Get the sku of the product
          final playerName = message.transaction!.displayName;
          final sku = Sku.fromString(transactionReceipt.product.sku);

          late ToAppMessages type;
          switch (sku) {
            case Sku.celebrate:
              type = ToAppMessages.fireworksRequest;
              break;

            case Sku.bigHeist:
              type = ToAppMessages.attemptTheBigHeist;
              break;
          }

          final response = await communicator.sendQuestion(MessageProtocol(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.app,
              type: MessageTypes.get,
              data: {'type': type.name, 'player_name': playerName}));

          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebsIsolated,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: response.isSuccess ?? false));
      }
    } catch (e) {
      return communicator.sendErrorReponse(message, e.toString());
    }
  }
}
