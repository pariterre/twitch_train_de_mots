import 'dart:async';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/generic/models/ebs_helpers.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';
import 'package:twitch_manager/twitch_app.dart';

final _logger = Logger('EbsServerManager');

class TwitchAppEbsManager extends TwitchAppEbsManagerAbstract {
  ///
  /// Initialize the EbsServerManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  TwitchAppEbsManager({required super.appInfo}) {
    if (appInfo.ebsUri == null) {
      throw ManagerNotInitializedException(
          'EbsServerManager cannot be initialized because no EBS URI is provided in TwitchAppInfo.');
    }

    _asyncInitializations();
  }

  /// If the broadcaster have activated the extension
  bool? _isExtensionActive;
  bool get isExtensionActive =>
      (_isExtensionActive ?? false) || MocksConfiguration.showDebugOptions;
  set isExtensionActive(bool value) {
    if (_isExtensionActive == value) return;

    _isExtensionActive = value;
    onConfirmationExtensionIsActive
        .notifyListeners((callback) => callback(value));
  }

  final onConfirmationExtensionIsActive = GenericListener<Function(bool)>();

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    while (true) {
      try {
        final tm = Managers.instance.twitch;
        tm.onTwitchManagerHasTriedConnecting
            .listen(_twitchManagerHasTriedConnecting);
        _twitchManagerHasTriedConnecting(isSuccess: tm.isConnected);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    onEbsHasConnected.listen(_listenToGameManagerCallbacks);
    onEbsHasDisconnected.listen(_disposeListeners);

    _isInitialized = true;
    _logger.config('Ready');
  }

  void _twitchManagerHasTriedConnecting({required bool isSuccess}) {
    if (!isSuccess) return;

    Managers.instance.twitch.onTwitchManagerHasTriedConnecting
        .cancel(_twitchManagerHasTriedConnecting);
    connect(Managers.instance.twitch.broadcasterId);
  }

  void _listenToGameManagerCallbacks() {
    // Connect the listeners to the GameManager
    final gm = Managers.instance.train;
    gm.onRoundStarted.listen(_sendGameStateToEbs);
    gm.onRoundIsOver.listen(_sendGameStateToEbs);
    gm.onStealerPardoned.listen(_sendGameStateToEbsWithParameter);
    gm.onSolutionFound.listen(_sendCooldownToEbs);
    gm.onSolutionWasStolen.listen(_sendCooldownToEbs);
    gm.onAttemptingTheBigHeist.listen(_sendGameStateToEbsWithPlayerName);
    gm.onScrablingLetters.listen(_sendGameStateToEbs);
    gm.onRevealUselessLetter.listen(_sendGameStateToEbs);
    gm.onRevealHiddenLetter.listen(_sendGameStateToEbs);

    final cm = Managers.instance.configuration;
    cm.onShowExtensionChanged.listen(_sendGameStateToEbs);

    // Check if we need to send something to the EBS server at each tick
    //gm.onClockTicked.listen(_sendGameStateToEbs);

    final mgm = Managers.instance.miniGames;
    mgm.onMinigameStarted.listen(_connectMiniGame);
    mgm.onMinigameEnded.listen(_disconnectMiniGame);

    _sendGameStateToEbs();
  }

  ///
  /// Dispose the EbsServerManager by closing the connection with the
  /// EBS server.
  void _disposeListeners() {
    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_sendGameStateToEbs);
    gm.onRoundIsOver.cancel(_sendGameStateToEbs);
    gm.onStealerPardoned.cancel(_sendGameStateToEbsWithParameter);
    gm.onSolutionFound.cancel(_sendCooldownToEbs);
    gm.onSolutionWasStolen.cancel(_sendCooldownToEbs);
    gm.onAttemptingTheBigHeist.cancel(_sendGameStateToEbsWithPlayerName);
    gm.onScrablingLetters.cancel(_sendGameStateToEbs);
    gm.onRevealUselessLetter.cancel(_sendGameStateToEbs);
    gm.onRevealHiddenLetter.cancel(_sendGameStateToEbs);
    //gm.onClockTicked.cancel(_sendGameStateToEbs);

    final mgm = Managers.instance.miniGames;
    mgm.onMinigameStarted.cancel(_connectMiniGame);
    mgm.onMinigameEnded.cancel(_disconnectMiniGame);

    final cm = Managers.instance.configuration;
    cm.onShowExtensionChanged.cancel(_sendGameStateToEbs);
  }

  void _connectMiniGame() {
    final mgm = Managers.instance.miniGames.manager;
    mgm?.onInitialized.listen(_sendGameStateToEbs);
    mgm?.onGameUpdated.listen(_sendGameStateToEbs);
    mgm?.onRoundEnded.listen(_sendGameStateToEbs);
  }

  void _disconnectMiniGame() {
    final mgm = Managers.instance.miniGames.manager;
    mgm?.onInitialized.cancel(_sendGameStateToEbs);
    mgm?.onGameUpdated.cancel(_sendGameStateToEbs);
    mgm?.onRoundEnded.cancel(_sendGameStateToEbs);
  }

  ///
  /// Request a new letter problem, it will return a completer that will complete
  /// when the EBS server sends the new letter problem. Note requesting twice will
  /// result in undefined behavior.
  Future<Map<String, dynamic>> generateLetterProblem({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) async {
    // Create a new completer with a timout of maxSearchingTime

    _logger.info('Requesting a new letter problem to EBS server');
    final message = await sendQuestionToEbs(
      MessageProtocol(
        to: MessageTo.ebs,
        from: MessageFrom.app,
        type: MessageTypes.get,
        data: {
          'type': ToBackendMessages.newLetterProblemRequest.name,
          'configuration': {
            'algorithm': 'fromRandomWord',
            'lengthShortestSolutionMin': nbLetterInSmallestWord,
            'lengthShortestSolutionMax': nbLetterInSmallestWord,
            'lengthLongestSolutionMin': minLetters,
            'lengthLongestSolutionMax': maxLetters,
            'nbSolutionsMin': minimumNbOfWords,
            'nbSolutionsMax': maximumNbOfWords,
            'nbUselessLetters': addUselessLetter ? 1 : 0,
          }
        },
      ),
    );

    return message.data!['letter_problem'];
  }

  Future<void> _sendCooldownToEbs(WordSolution solution) async {
    _sendGameStateToEbs();
  }

  ///
  /// Get a serializable version of the GameState
  SerializableGameState serializableGameState() =>
      Managers.instance.train.serialize();

  Future<void> _sendGameStateToEbs() async => sendMessageToEbs(MessageProtocol(
          to: MessageTo.frontend,
          from: MessageFrom.app,
          type: MessageTypes.put,
          data: {
            'type': ToFrontendMessages.gameState.name,
            'game_state': serializableGameState().serialize(),
          }));

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendGameStateToEbsWithParameter(dynamic _) async =>
      _sendGameStateToEbs();

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendGameStateToEbsWithPlayerName(
          {required String playerName}) async =>
      _sendGameStateToEbs();

  @override
  Future<void> handleGetRequest(MessageProtocol message) async {
    try {
      final requestType = ToAppMessages.values.byName(message.data!['type']);
      switch (requestType) {
        // General requests
        case ToAppMessages.isExtensionActive:
        case ToAppMessages.gameStateRequest:
          return await _handleGeneralRequests(message);

        // Main game requests
        case ToAppMessages.tryWord:
        case ToAppMessages.pardonRequest:
        case ToAppMessages.boostRequest:
        case ToAppMessages.fireworksRequest:
        case ToAppMessages.attemptTheBigHeist:
        case ToAppMessages.changeLaneRequest:
        case ToAppMessages.fixTracksMiniGameRequest:
          return await _handleMainGameRequest(message);

        // Mini-game requests
        case ToAppMessages.revealTileAt:
        case ToAppMessages.slingShootBlueberry:
          return await _handleMiniGameRequest(message);

        case ToAppMessages.bitsRedeemed:
          throw UnimplementedError(
              'Bits redeemed should be handled by the EBS and rerouted properly');
      }
    } catch (e) {
      _logger.severe('Error while handling message from EBS: $e');
      sendResponseToEbs(message.copyWith(
          to: MessageTo.frontend,
          from: MessageFrom.app,
          type: MessageTypes.response,
          isSuccess: false));
    }
  }

  Future<void> _handleGeneralRequests(MessageProtocol message) async {
    final requestType = ToAppMessages.values.byName(message.data!['type']);
    switch (requestType) {
      // General requests
      case ToAppMessages.isExtensionActive:
        final activeVersion = message.data!['active_version'] as String?;
        final acceptedExtensionVersions =
            (message.data!['accepted_versions'] as List).cast<String>();
        isExtensionActive = activeVersion != null &&
            acceptedExtensionVersions.contains(activeVersion);
        _logger.info(
            'Extension is now ${isExtensionActive ? 'active' : 'inactive'}');
        break;

      case ToAppMessages.gameStateRequest:
        sendResponseToEbs(message.copyWith(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: true,
            data: {
              'type': ToFrontendMessages.gameState.name,
              'game_state': serializableGameState().serialize(),
            }));
        break;

      // Non-general requests
      case ToAppMessages.tryWord:
      case ToAppMessages.pardonRequest:
      case ToAppMessages.boostRequest:
      case ToAppMessages.fireworksRequest:
      case ToAppMessages.attemptTheBigHeist:
      case ToAppMessages.changeLaneRequest:
      case ToAppMessages.fixTracksMiniGameRequest:
      case ToAppMessages.revealTileAt:
      case ToAppMessages.slingShootBlueberry:
      case ToAppMessages.bitsRedeemed:
        throw UnimplementedError(
            'This is not a main game request and should be handled in the main handler');
    }
  }

  Future<void> _handleMainGameRequest(MessageProtocol message) async {
    final gm = Managers.instance.train;

    final requestType = ToAppMessages.values.byName(message.data!['type']);
    final playerName = message.data!['player_name'] as String;
    final player = gm.players.firstWhereOrAdd(playerName);

    switch (requestType) {
      // Single-pass requests
      case ToAppMessages.tryWord:
      case ToAppMessages.pardonRequest:
      case ToAppMessages.boostRequest:
        final isSuccess = switch (requestType) {
          ToAppMessages.tryWord => await gm.trySolution(
              playerName: playerName, word: message.data!['word'] as String),
          ToAppMessages.pardonRequest =>
            gm.pardonLastStealer(pardonner: player),
          ToAppMessages.boostRequest => gm.boostTrain(player: player),
          _ => throw UnimplementedError(
              'Handler for $requestType is not implemented'),
        };

        sendResponseToEbs(message.copyWith(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: isSuccess));
        break;

      // Two-pass requests
      case ToAppMessages.fireworksRequest:
      case ToAppMessages.attemptTheBigHeist:
      case ToAppMessages.changeLaneRequest:
      case ToAppMessages.fixTracksMiniGameRequest:
        final requester = switch (requestType) {
          ToAppMessages.fireworksRequest => gm.congratulationFireworksRequester,
          ToAppMessages.attemptTheBigHeist => gm.attemptTheBigHeistRequester,
          ToAppMessages.changeLaneRequest => gm.changeLaneRequester,
          ToAppMessages.fixTracksMiniGameRequest =>
            gm.fixTracksMiniGameRequester,
          _ => throw UnimplementedError(
              'Requester for $requestType is not implemented'),
        };

        final canRequest = await requester.canRequest(playerName: playerName);
        sendResponseToEbs(message.copyWith(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: canRequest));

        if (canRequest) {
          // False if it is the first pass, true if the permission was granted and it is the second pass.
          final isRedeemed = message.data!['is_redeemed'] as bool? ?? false;
          if (isRedeemed) {
            requester.confirmRequest(playerName: playerName, isConfirmed: true);
          } else {
            requester.initiateRequest(playerName: playerName);
          }
        }

        break;

      // Non-game requests
      case ToAppMessages.isExtensionActive:
      case ToAppMessages.gameStateRequest:
      case ToAppMessages.revealTileAt:
      case ToAppMessages.slingShootBlueberry:
      case ToAppMessages.bitsRedeemed:
        // These requests are not handled in this method
        throw UnimplementedError(
            'This is not a main game request and should be handled in the main handler');
    }
  }

  Future<void> _handleMiniGameRequest(MessageProtocol message) async {
    final gm = Managers.instance.train;

    final requestType = ToAppMessages.values.byName(message.data!['type']);
    late bool isSuccess;
    switch (requestType) {
      case ToAppMessages.revealTileAt:
        final playerName = message.data!['player_name'] as String;
        isSuccess = gm.players.hasPlayer(playerName)
            ? Managers.instance.miniGames.treasureHunt
                .revealTile(tileIndex: message.data!['index'] as int)
            : false;
        break;

      case ToAppMessages.slingShootBlueberry:
        final bwm = Managers.instance.miniGames.blueberryWar;
        final blueberryId = message.data!['id'] as int;
        final blueberry = bwm.allAgents
            .firstWhere((agent) => agent.id == blueberryId) as BlueberryAgent;

        final velocity =
            Vector2Extension.deserialize(message.data!['velocity']);
        bwm.slingShoot(blueberry: blueberry, newVelocity: velocity);
        isSuccess = true;
        break;

      // Non-mini-game requests
      case ToAppMessages.isExtensionActive:
      case ToAppMessages.gameStateRequest:
      case ToAppMessages.tryWord:
      case ToAppMessages.pardonRequest:
      case ToAppMessages.boostRequest:
      case ToAppMessages.fireworksRequest:
      case ToAppMessages.attemptTheBigHeist:
      case ToAppMessages.changeLaneRequest:
      case ToAppMessages.fixTracksMiniGameRequest:
      case ToAppMessages.bitsRedeemed:
        throw UnimplementedError(
            'Bits redeemed should be handled by the EBS and rerouted properly');
    }

    sendResponseToEbs(message.copyWith(
        to: MessageTo.frontend,
        from: MessageFrom.app,
        type: MessageTypes.response,
        isSuccess: isSuccess));
  }

  @override
  Future<void> handlePutRequest(MessageProtocol message) {
    // There is currently no put request to handle
    throw UnimplementedError();
  }
}

class TwitchAppEbsManagerMocked extends TwitchAppEbsManager {
  TwitchAppEbsManagerMocked({required super.appInfo}) {
    // Simulate receiving extension is active after 2 seconds
    Future.delayed(const Duration(seconds: 1), () async {
      handleGetRequest(MessageProtocol(
          to: MessageTo.app,
          from: MessageFrom.ebs,
          type: MessageTypes.get,
          data: {
            'type': ToAppMessages.isExtensionActive.name,
            'active_version': null,
            'accepted_versions': [],
          }));
    });
  }
}
