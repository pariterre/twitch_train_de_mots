import 'dart:async';
import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/generic/misc/misc.dart';
import 'package:common/generic/models/ebs_helpers.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';
import 'package:twitch_manager/twitch_ebs.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('GameManager');

///
/// This class syncs with the states of the game on the App side. It therefore
/// constantly waits for updates from the App, without proactively changing the
/// game state. In that sense, it provides a communication channel between the
/// App and the Frontends.
class EbsManager extends TwitchEbsManagerAbstract {
  ///
  /// Holds the current state of the game
  SerializableGameState _gameState = SerializableGameState.empty();
  Map<String, dynamic> _lastSentGameState = {};

  ///
  /// Create a new GameManager. This method automatically starts a keep alive
  /// mechanism to keep the connexion alive. If it fails, the game is ended.
  /// [broadcasterId] the id of the broadcaster.
  /// [ebsInfo] the configuration of the EBS.
  EbsManager.spawn({
    required String broadcasterId,
    required super.ebsInfo,
    required super.sendPort,
    required bool useMockedTwitchEbsApi,
    required List<String> acceptedExtensionVersions,
  }) : super(
            broadcasterId: broadcasterId,
            twitchEbsApiInitializer: useMockedTwitchEbsApi
                ? TwitchEbsApiMocked.initialize
                : TwitchEbsApi.initialize) {
    // Set up the logger
    Logger.root.onRecord.listen((record) => print(
        '${record.time} - BroadcasterId: $broadcasterId - ${record.message}'));

    _logger.info('Sending welcome message');
    TwitchEbsApi.instance.sendChatMessage('Bienvenue au Train de mots!');

    // Send if the extension is active to the frontend
    _sendExtensionActiveStatus(acceptedExtensionVersions);
  }

  Future<void> _sendExtensionActiveStatus(
      List<String> acceptedExtensionVersions) async {
    communicator.sendMessage(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.isExtensionActive.name,
          'active_version':
              await TwitchEbsApi.instance.activeExtensionVersion(),
          'accepted_versions': acceptedExtensionVersions,
        }));
  }

  Future<void> _handlePatchGameStateResponse(MessageProtocol message) async {
    _logger.info('Received patch game state response from app');

    final gameStatePatch = message.data?['game_state'] == null
        ? {}
        : Map<String, dynamic>.from(message.data!['game_state']);

    // Change player names to opaque ids in the patch if any.
    // TODO: Do the same for [playersWhoCanPardon], [boosters]
    if (gameStatePatch['players'] != null) {
      final players = gameStatePatch['players'] as Map<String, dynamic>;

      final playersToRemove = <String>[];
      for (var playerName in players.keys) {
        final player = players[playerName] as Map<String, dynamic>;
        player['name'] =
            registeredFrontendUsers.from(login: playerName)?.opaqueId;
        if (player['name'] == null) playersToRemove.add(playerName);
      }
      for (var player in playersToRemove) {
        players.remove(player);
      }
    }

    // Apply the patch to the current game state to get the new game state
    final newGameState = SerializableGameState.deserialize(
        applyPatch(_gameState.serialize(), gameStatePatch));

    if (newGameState.computeHash() != message.data?['game_state_hash']) {
      throw 'Game state hash does not match the expected hash';
    }

    _gameState = newGameState;
    await _sendGameStateToFrontend();
  }

  Future<void> _sendGameStateToFrontend() async {
    _logger.info('Sending game state to frontend');

    _lastSentGameState = deepDiffAsPatch(_lastSentGameState, _gameState);

    communicator.sendMessage(MessageProtocol(
        to: MessageTo.frontend,
        from: MessageFrom.ebs,
        type: MessageTypes.put,
        data: {
          'type': MessagesToFrontend.gameStateResponse.name,
          'game_state': _lastSentGameState
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
  /// Relay the try a word request from the frontend to the app
  /// [userId] the id of the user that is trying the word
  /// [word] the word that is being tried
  Future<bool> _frontendTryAWord(String userId, String word) async {
    _logger.info('Resquesting to try the word $word');
    final playerName = registeredFrontendUsers.from(userId: userId)?.login;
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.tryWord.name,
          'player_name': playerName,
          'word': word
        }));
    return response.isSuccess ?? false;
  }

  ///
  /// Handle a message from the frontend to pardon the last stealer
  /// [userId] the id of the user that wants to pardon
  Future<bool> _frontendRequestedToPardon(String userId) async {
    _logger.info('Resquesting to pardon last stealer');

    final playerName = registeredFrontendUsers.from(userId: userId)?.login;
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.pardonRequest.name,
          'player_name': playerName
        }));
    return response.isSuccess ?? false;
  }

  ///
  /// Handle a message from the frontend to boost the train
  /// [userId] the id of the user that wants to boost
  Future<bool> _frontendRequestedBoosted(String userId) async {
    _logger.info('Resquesting to boost the train');

    final playerName = registeredFrontendUsers.from(userId: userId)?.login;
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.boostRequest.name,
          'player_name': playerName
        }));
    return response.isSuccess ?? false;
  }

  Future<bool> _frontendRequestedRevealTileAt(String userId, int index) async {
    _logger.info('Resquesting to reveal tile at $index');

    final playerName = registeredFrontendUsers.from(userId: userId)?.login;
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.revealTileAt.name,
          'player_name': playerName,
          'index': index
        }));
    return response.isSuccess ?? false;
  }

  Future<bool> _frontendRequestedSlingShoot(String userId,
      {required int id, required Vector2 velocity}) async {
    _logger.info('Resquesting to slingshoot at $id');

    final playerName = registeredFrontendUsers.from(userId: userId)?.login;
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': MessagesToApp.slingShootBlueberry.name,
          'player_name': playerName,
          'id': id,
          'velocity': velocity.serialize()
        }));
    return response.isSuccess ?? false;
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
      case MessageFrom.ebs:
      case MessageFrom.generic:
        throw 'Request not supported';
    }
  }

  Future<void> _handleMessageFromApp(MessageProtocol message) async {
    try {
      switch (message.to) {
        case MessageTo.ebs:
          switch (MessagesToEbs.values.byName(message.data!['type'])) {
            case MessagesToEbs.newLetterProblemRequest:
              final letterProblem = await _appRequestedANewLetterProblem(
                  message.data!['configuration'] as Map<String, dynamic>);
              communicator.sendMessage(message.copyWith(
                  to: MessageTo.app,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: true,
                  data: {'letter_problem': letterProblem.serialize()}));
              break;
            case MessagesToEbs.patchGameStateResponse:
              // TODO Change this to a put request with response to confirm the client can ditch the "previous" game state
              await _handlePatchGameStateResponse(message);
              break;
            case MessagesToEbs.gameStateRequest:
              throw 'This request should not come from the app';
          }
          break;
        case MessageTo.frontend:
          switch (MessagesToFrontend.values.byName(message.data!['type'])) {
            case MessagesToFrontend.pardonResponse:
            case MessagesToFrontend.boostResponse:
              break;
            case MessagesToFrontend.gameStateResponse:
              throw 'This response should not come from the app';
          }
          break;
        case MessageTo.pubsub:
        case MessageTo.app:
        case MessageTo.generic:
        case MessageTo.ebsMain:
          throw 'Request not supported';
      }
    } catch (e) {
      communicator.sendErrorReponse(
          message.copyWith(
              to: MessageTo.app,
              from: MessageFrom.ebs,
              type: MessageTypes.response),
          e.toString());
    }
  }

  Future<void> _handleMessageFromFrontend(MessageProtocol message,
      ExtractedTransactionReceipt? transactionReceipt) async {
    // Helper function to send a response to the frontend
    late final String userId;
    try {
      userId = message.data!['user_id']!;
    } catch (e) {
      return communicator.sendErrorReponse(message, 'user_id not found');
    }

    try {
      switch (message.to) {
        case MessageTo.ebs:
          switch (MessagesToEbs.values.byName(message.data!['type'])) {
            case MessagesToEbs.gameStateRequest:
              _sendGameStateToFrontend();
              break;
            case MessagesToEbs.newLetterProblemRequest:
            case MessagesToEbs.patchGameStateResponse:
              throw 'This request should not come from the frontend';
          }

        case MessageTo.frontend:
        case MessageTo.app:
          switch (MessagesToApp.values.byName(message.data!['type'])) {
            case MessagesToApp.tryWord:
              communicator.sendResponse(message.copyWith(
                  from: MessageFrom.ebs,
                  to: MessageTo.frontend,
                  type: MessageTypes.response,
                  isSuccess: await _frontendTryAWord(
                      userId, message.data!['word'] as String)));
              break;

            case MessagesToApp.pardonRequest:
              communicator.sendResponse(message.copyWith(
                  from: MessageFrom.ebs,
                  to: MessageTo.frontend,
                  type: MessageTypes.response,
                  isSuccess: await _frontendRequestedToPardon(userId)));
              break;

            case MessagesToApp.boostRequest:
              final isSuccess = await _frontendRequestedBoosted(userId);
              communicator.sendResponse(message.copyWith(
                  to: MessageTo.frontend,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: isSuccess));
              break;

            case MessagesToApp.revealTileAt:
              final isSuccess = await _frontendRequestedRevealTileAt(
                  userId, message.data!['index'] as int);
              communicator.sendResponse(message.copyWith(
                  to: MessageTo.frontend,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: isSuccess));
              break;

            case MessagesToApp.slingShootBlueberry:
              final isSuccess = await _frontendRequestedSlingShoot(
                userId,
                id: message.data!['id'] as int,
                velocity:
                    Vector2Extension.deserialize(message.data!['velocity']),
              );
              communicator.sendResponse(message.copyWith(
                  to: MessageTo.frontend,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: isSuccess));
              break;

            case MessagesToApp.fireworksRequest:
            case MessagesToApp.attemptTheBigHeist:
            case MessagesToApp.changeLaneRequest:
            case MessagesToApp.fixTracksMiniGameRequest:
              final playerName =
                  registeredFrontendUsers.from(userId: userId)?.login;

              final response = await communicator.sendQuestion(MessageProtocol(
                  to: MessageTo.app,
                  from: MessageFrom.ebs,
                  type: MessageTypes.get,
                  data: {
                    'type': message.data!['type'],
                    'player_name': playerName,
                    'is_redeemed': false
                  }));

              communicator.sendResponse(message.copyWith(
                  to: MessageTo.frontend,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: response.isSuccess ?? false));
              break;

            case MessagesToApp.bitsRedeemed:
              // This is expected to be from bits transaction
              if (transactionReceipt == null) {
                throw 'Bits transaction not found';
              }

              // Get the sku of the product
              final playerName = message.transaction!.displayName;
              final sku = Sku.fromString(transactionReceipt.product.sku);

              MessagesToApp type = switch (sku) {
                Sku.celebrate => MessagesToApp.fireworksRequest,
                Sku.bigHeist => MessagesToApp.attemptTheBigHeist,
                Sku.changeLane => MessagesToApp.changeLaneRequest,
                Sku.fixTracks => MessagesToApp.fixTracksMiniGameRequest,
              };

              final response = await communicator.sendQuestion(MessageProtocol(
                  to: MessageTo.app,
                  from: MessageFrom.ebs,
                  type: MessageTypes.get,
                  data: {
                    'type': type.name,
                    'player_name': playerName,
                    'is_redeemed': true
                  }));

              communicator.sendResponse(message.copyWith(
                  to: MessageTo.frontend,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: response.isSuccess ?? false));
              break;

            case MessagesToApp.isExtensionActive:
              throw 'Request should not come from frontend';
          }

          break;
        case MessageTo.pubsub:
        case MessageTo.generic:
        case MessageTo.ebsMain:
          throw 'Request not supported';
      }
    } catch (e) {
      return communicator.sendErrorReponse(message, e.toString());
    }
  }
}

class TwitchEbsApiMocked extends TwitchEbsApiMockerTemplate {
  static Future<void> initialize({
    required String broadcasterId,
    required TwitchEbsInfo ebsInfo,
  }) async =>
      TwitchEbsApi.initializeMocker(
          broadcasterId: broadcasterId,
          ebsInfo: ebsInfo,
          twitchEbsApi: TwitchEbsApiMocked(
              broadcasterId: broadcasterId, ebsInfo: ebsInfo));

  TwitchEbsApiMocked({required super.broadcasterId, required super.ebsInfo});

  final _random = Random();
  final _users = <TwitchUser>[];

  @override
  Future<TwitchUser?> user({String? userId, String? login}) async {
    _logger.fine('Getting user for ${userId ?? login}');
    return _users.firstWhere(
        (player) =>
            (userId != null && player.userId == userId) ||
            (login != null && player.login == login),
        orElse: () => _addRandomUser(userId: userId, login: login));
  }

  TwitchUser _addRandomUser(
      {String? userId, String? login, String? displayName}) {
    userId ??= '${_random.nextInt(1000000) + 1000000}';
    login ??= 'user$userId';
    displayName ??= 'User $userId';

    final newUser =
        TwitchUser(userId: userId, login: login, displayName: displayName);
    _users.add(newUser);
    return newUser;
  }

  ///
  /// Fake a successful API request
  @override
  Future<http.Response> sendPubsubMessage(Map<String, dynamic> message) async =>
      http.Response(
          '{"success": true, "message": "Pubsub message sent successfully"}',
          204,
          headers: {'Content-Type': 'application/json'});
}
