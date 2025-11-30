import 'dart:async';
import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/generic/models/ebs_helpers.dart';
import 'package:common/generic/models/game_status.dart';
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
  SerializableGameState _gameState = SerializableGameState(
    status: WordsTrainGameStatus.initializing,
    round: 0,
    isRoundSuccess: false,
    timeRemaining: Duration.zero,
    newCooldowns: {},
    letterProblem: null,
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
    boosters: [],
    canAttemptTheBigHeist: false,
    isAttemptingTheBigHeist: false,
    canAttemptEndOfRailwayMiniGame: false,
    isAttemptingEndOfRailwayMiniGame: false,
    configuration: SerializableConfiguration(showExtension: true),
    miniGameState: null,
  );
  SerializableGameState get gameState => _gameState;
  set gameState(SerializableGameState value) {
    _gameState = value;

    // Convert the cooldowns from login to opaque id
    for (final key in _gameState.newCooldowns.keys.toList()) {
      final userId = loginToUserId[key] ?? -1;
      _gameState.newCooldowns[userIdToOpaqueId[userId] ?? ''] =
          _gameState.newCooldowns[key]!;
      _gameState.newCooldowns.remove(key);
    }

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
  EbsManager.spawn({
    required String broadcasterId,
    required super.ebsInfo,
    required super.sendPort,
    required bool useMockedTwitchApi,
    required List<String> acceptedExtensionVersions,
  }) : super(
            broadcasterId: broadcasterId,
            twitchApiInitializer: useMockedTwitchApi
                ? MockedTwitchApi.initialize
                : TwitchApi.initialize) {
    // Set up the logger
    Logger.root.onRecord.listen((record) => print(
        '${record.time} - BroadcasterId: $broadcasterId - ${record.message}'));

    _logger.info('Sending welcome message');
    TwitchApi.instance.sendChatMessage('Bienvenue au Train de mots!');

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
          'type': ToAppMessages.isExtensionActive.name,
          'active_version': await TwitchApi.instance.activeExtensionVersion(),
          'accepted_versions': acceptedExtensionVersions,
        }));
  }

  Future<void> _sendGameStateToFrontend() async {
    _logger.info('Sending game state to frontend');

    communicator.sendMessage(MessageProtocol(
        to: MessageTo.frontend,
        from: MessageFrom.ebs,
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
  /// Handle a message from the frontend to get the game state
  Future<MessageProtocol> _frontendRequestedGameState() async {
    _logger.info('Resquesting game state');
    return await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {'type': ToAppMessages.gameStateRequest.name}));
  }

  ///
  /// Relay the try a word request from the frontend to the app
  /// [userId] the id of the user that is trying the word
  /// [word] the word that is being tried
  Future<bool> _frontendTryAWord(String userId, String word) async {
    _logger.info('Resquesting to try the word $word');
    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.tryWord.name,
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

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
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
  Future<bool> _frontendRequestedBoosted(String userId) async {
    _logger.info('Resquesting to boost the train');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
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

  Future<bool> _frontendRequestedRevealTileAt(String userId, int index) async {
    _logger.info('Resquesting to reveal tile at $index');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.revealTileAt.name,
          'player_name': playerName,
          'index': index
        }));
    return response.isSuccess ?? false;
  }

  Future<bool> _frontendRequestedSlingShoot(String userId,
      {required int id, required Vector2 velocity}) async {
    _logger.info('Resquesting to slingshoot at $id');

    final playerName = userIdToLogin[userId];
    if (playerName == null) {
      _logger.severe('User $userId is not registered');
      return false;
    }

    final response = await communicator.sendQuestion(MessageProtocol(
        to: MessageTo.app,
        from: MessageFrom.ebs,
        type: MessageTypes.get,
        data: {
          'type': ToAppMessages.slingShootBlueberry.name,
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
          switch (ToBackendMessages.values.byName(message.data!['type'])) {
            case ToBackendMessages.newLetterProblemRequest:
              final letterProblem = await _appRequestedANewLetterProblem(
                  message.data!['configuration'] as Map<String, dynamic>);
              communicator.sendMessage(message.copyWith(
                  to: MessageTo.app,
                  from: MessageFrom.ebs,
                  type: MessageTypes.response,
                  isSuccess: true,
                  data: {'letter_problem': letterProblem.serialize()}));
              break;
          }
          break;
        case MessageTo.frontend:
          switch (ToFrontendMessages.values.byName(message.data!['type'])) {
            case ToFrontendMessages.gameState:
              gameState = SerializableGameState.deserialize(
                  message.data!['game_state'] as Map<String, dynamic>);
              _sendGameStateToFrontend();
              break;
            case ToFrontendMessages.pardonResponse:
              break;
            case ToFrontendMessages.boostResponse:
              break;
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
      if (message.to != MessageTo.app) {
        throw 'Request not supported';
      }

      switch (ToAppMessages.values.byName(message.data!['type'])) {
        case ToAppMessages.gameStateRequest:
          final response = await _frontendRequestedGameState();
          communicator.sendReponse(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.ebs,
              type: MessageTypes.response,
              data: response.data,
              isSuccess: true));
          break;

        case ToAppMessages.tryWord:
          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebs,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: await _frontendTryAWord(
                  userId, message.data!['word'] as String)));
          break;

        case ToAppMessages.pardonRequest:
          communicator.sendReponse(message.copyWith(
              from: MessageFrom.ebs,
              to: MessageTo.frontend,
              type: MessageTypes.response,
              isSuccess: await _frontendRequestedToPardon(userId)));
          break;

        case ToAppMessages.boostRequest:
          final isSuccess = await _frontendRequestedBoosted(userId);
          communicator.sendReponse(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.ebs,
              type: MessageTypes.response,
              isSuccess: isSuccess));
          break;

        case ToAppMessages.revealTileAt:
          final isSuccess = await _frontendRequestedRevealTileAt(
              userId, message.data!['index'] as int);
          communicator.sendReponse(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.ebs,
              type: MessageTypes.response,
              isSuccess: isSuccess));
          break;

        case ToAppMessages.slingShootBlueberry:
          final isSuccess = await _frontendRequestedSlingShoot(
            userId,
            id: message.data!['id'] as int,
            velocity: Vector2Extension.deserialize(message.data!['velocity']),
          );
          communicator.sendReponse(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.ebs,
              type: MessageTypes.response,
              isSuccess: isSuccess));
          break;

        case ToAppMessages.fireworksRequest:
        case ToAppMessages.attemptTheBigHeist:
        case ToAppMessages.changeLaneRequest:
          throw 'Request is supposed to come from bit transaction';

        case ToAppMessages.bitsRedeemed:
          // This is expected to be from bits transaction
          if (transactionReceipt == null) throw 'Bits transaction not found';

          // Get the sku of the product
          final playerName = message.transaction!.displayName;
          final sku = Sku.fromString(transactionReceipt.product.sku);

          ToAppMessages type = switch (sku) {
            Sku.celebrate => ToAppMessages.fireworksRequest,
            Sku.bigHeist => ToAppMessages.attemptTheBigHeist,
            Sku.changeLane => ToAppMessages.changeLaneRequest,
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

          communicator.sendReponse(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.ebs,
              type: MessageTypes.response,
              isSuccess: response.isSuccess ?? false));
          break;

        case ToAppMessages.isExtensionActive:
          throw 'Request should not come from frontend';
      }
    } catch (e) {
      return communicator.sendErrorReponse(message, e.toString());
    }
  }
}

class MockedTwitchApi extends MockedTwitchApiTemplate {
  static Future<void> initialize({
    required String broadcasterId,
    required TwitchEbsInfo ebsInfo,
  }) async =>
      TwitchApi.initializeMocker(
          broadcasterId: broadcasterId,
          ebsInfo: ebsInfo,
          mockedTwitchApi:
              MockedTwitchApi(broadcasterId: broadcasterId, ebsInfo: ebsInfo));

  MockedTwitchApi({required super.broadcasterId, required super.ebsInfo});

  final _random = Random();
  final _players = <Map<String, dynamic>>[];

  Map<String, dynamic> _addRandomUser(
      {String? userId, String? login, String? displayName}) {
    final id = userId ?? _random.nextInt(1000000) + 1000000;
    final name = login ?? 'user$id';
    final display = displayName ?? 'User $id';

    final newUser = {'id': id, 'login': name, 'display_name': display};
    _players.add(newUser);
    return newUser;
  }

  @override
  Future<String?> userId({required String login}) async =>
      _players.firstWhere((player) => player['login'] == login,
          orElse: () => _addRandomUser(login: login))['id'];

  @override
  Future<String?> login({required String userId}) async =>
      _players.firstWhere((player) => player['id'] == userId,
          orElse: () => _addRandomUser(userId: userId))['login'];

  @override
  Future<String?> displayName({required String userId}) async =>
      _players.firstWhere((player) => player['id'] == userId,
          orElse: () => _addRandomUser(userId: userId))['display_name'];

  ///
  /// Fake a successful API request
  @override
  Future<http.Response> sendPubsubMessage(Map<String, dynamic> message) async =>
      http.Response(
          '{"success": true, "message": "Pubsub message sent successfully"}',
          204,
          headers: {'Content-Type': 'application/json'});
}
