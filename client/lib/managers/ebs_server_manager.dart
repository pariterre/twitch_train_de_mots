import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:twitch_manager/models/ebs/completers.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('EbsServerManager');

class EbsServerManager {
  // Singleton
  static EbsServerManager get instance {
    if (_instance == null) {
      throw Exception(
          'EbsServerManager not initialized, call initialize() first');
    }
    return _instance!;
  }

  static EbsServerManager? _instance;
  EbsServerManager._internal({required Uri? ebsUri}) : _ebsUri = ebsUri;

  WebSocketChannel? _socket;

  final Uri? _ebsUri;
  bool _isConnectedToEbs = false;
  bool get isConnectedToEbs => _isConnectedToEbs;

  ///
  /// Initialize the TrainDeMotsEbsManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  static Future<void> initialize({required Uri? ebsUri}) async {
    if (_instance != null) return;

    _instance = EbsServerManager._internal(ebsUri: ebsUri);
    TwitchManager.instance.onTwitchManagerHasConnected
        .addListener(_instance!._twitchManagerHasConnected);
  }

  void _twitchManagerHasConnected() {
    TwitchManager.instance.onTwitchManagerHasConnected
        .removeListener(_instance!._twitchManagerHasConnected);
    _connect();
  }

  ///
  /// Connect to the EBS server
  bool get _isConnectingToEbs => _hasConnectedToEbsCompleter != null;
  Completer<bool>? _hasConnectedToEbsCompleter;
  StreamSubscription? _ebsStreamSubscription;
  Future<void> _connect() async {
    _logger.info('Connecting to EBS server');

    Future<void> retry(String errorMessage) async {
      if (_isConnectingToEbs) return;

      _logger.severe(errorMessage);
      // Do some clean up
      _isConnectedToEbs = false;
      _ebsStreamSubscription?.cancel();
      _logger.severe('Reconnecting to EBS in 10 seconds');
      await Future.delayed(const Duration(seconds: 10));
      _connect();
    }

    if (_ebsUri == null) return;

    // If we already are connecting, return the future
    if (_hasConnectedToEbsCompleter != null) return;
    _hasConnectedToEbsCompleter = Completer();

    // Connect to EBS server
    try {
      final twitchBroadcasterId = TwitchManager.instance.broadcasterId;
      _instance!._socket = WebSocketChannel.connect(
          Uri.parse('$_ebsUri/app/connect?broadcasterId=$twitchBroadcasterId'));
      await _instance!._socket!.ready;
    } catch (e) {
      retry('Could not connect to EBS');
      return;
    }

    // Listen to the messages from the EBS server
    _ebsStreamSubscription = _instance!._socket!.stream.listen(
      (raw) {
        try {
          _instance!._handleMessageFromEbs(raw);
        } catch (e) {
          // Do nothing, this is to prevent the program from crashing
          // When ill-formatted messages are received
          _logger.severe('Error while handling message from EBS: $e');
        }
      },
      onDone: () {
        dispose();
        retry('Connection closed by the EBS server');
      },
      onError: (error) {
        dispose();
        retry('Error with communicating to the EBS server: $error');
      },
    );

    try {
      final isConnected = await _hasConnectedToEbsCompleter!.future
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
      if (!isConnected) throw Exception('Timeout');
    } catch (e) {
      _hasConnectedToEbsCompleter = null;
      return retry('Error while connecting to EBS: $e');
    }

    // Connect the listeners to the GameManager
    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_sendGameStateToEbs);
    gm.onRoundIsOver.addListener(_sendGameStateToEbsWithParameter);
    gm.onStealerPardoned.addListener(_sendGameStateToEbsWithParameter);
    gm.onSolutionWasStolen.addListener(_sendGameStateToEbsWithParameter);
    gm.onRoundIsOver.addListener(_sendGameStateToEbsWithParameter);

    _logger.info('Connected to the EBS server');
    _hasConnectedToEbsCompleter = null;
    return;
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_sendGameStateToEbs);
    gm.onRoundIsOver.removeListener(_sendGameStateToEbsWithParameter);
    gm.onStealerPardoned.removeListener(_sendGameStateToEbsWithParameter);
    gm.onSolutionWasStolen.removeListener(_sendGameStateToEbsWithParameter);
    gm.onRoundIsOver.removeListener(_sendGameStateToEbsWithParameter);
    _socket?.sink.close();
  }

  ///
  /// API section under the the for of requests to the EBS server
  ///
  final _completers = Completers();

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
    required Duration maxSearchingTime,
  }) async {
    // Create a new completer with a timout of maxSearchingTime
    final completerId = _completers.spawn();

    _completers.get(completerId)!.future.timeout(maxSearchingTime,
        onTimeout: () {
      _logger
          .severe('Failed to get a new letter problem from EBS server in time');
      _completers.get(completerId)!.completeError(
          'Failed to get a new letter problem from EBS server in time');
    });

    _logger.info('Requesting a new letter problem to EBS server');
    _sendMessageToEbs(
      tm.MessageProtocol(
        from: tm.MessageFrom.app,
        to: tm.MessageTo.ebsIsolated,
        type: tm.MessageTypes.get,
        data: {
          'request': ToBackendMessages.newLetterProblemRequest,
          'configuration': {
            'algorithm': 'fromRandomWord',
            'lengthShortestSolutionMin': nbLetterInSmallestWord,
            'lengthShortestSolutionMax': nbLetterInSmallestWord,
            'lengthLongestSolutionMin': minLetters,
            'lengthLongestSolutionMax': maxLetters,
            'nbSolutionsMin': minimumNbOfWords,
            'nbSolutionsMax': maximumNbOfWords,
            'nbUselessLetters': addUselessLetter ? 1 : 0,
            'timeout': maxSearchingTime.inSeconds,
          }
        },
      ),
    );

    return _completers.get(completerId)!.future as Future<Map<String, dynamic>>;
  }

  ///
  /// Send a message to the EBS server to notify that a new round has started
  Future<void> _sendGameStateToEbs(
      [tm.MessageProtocol? previousMessage]) async {
    final type = previousMessage == null
        ? tm.MessageTypes.put
        : tm.MessageTypes.response;
    previousMessage ??= tm.MessageProtocol(
        from: tm.MessageFrom.app, to: tm.MessageTo.frontend, type: type);

    final gm = GameManager.instance;
    _sendMessageToEbs(previousMessage.copyWith(
        from: tm.MessageFrom.app,
        to: tm.MessageTo.frontend,
        type: type,
        data: {
          'type': ToFrontendMessages.gameState,
          'game_state': SimplifiedGameState(
            status: gm.gameStatus,
            round: gm.roundCount,
            pardonRemaining: gm.remainingPardon,
            pardonners: [gm.lastStolenSolution?.stolenFrom.name ?? ''],
            boostRemaining: gm.remainingBoosts,
            boostStillNeeded: gm.numberOfBoostStillNeeded,
          ).serialize(),
        }));
  }

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendGameStateToEbsWithParameter(_) async =>
      _sendGameStateToEbs();

  ///
  /// Handle the messages received from the EBS server
  void _handleMessageFromEbs(raw) {
    final gm = GameManager.instance;
    final message = tm.MessageProtocol.decode(raw);
    final messageType = message.type;

    switch (messageType) {
      case tm.MessageTypes.handShake:
        _logger.info('A streamer has connected to the EBS server');
        _hasConnectedToEbsCompleter?.complete(true);
        return;
      case tm.MessageTypes.ping:
        _logger.info('Ping received, sending pong');
        _sendMessageToEbs(message.copyWith(
            from: tm.MessageFrom.app,
            to: tm.MessageTo.ebsIsolated,
            type: tm.MessageTypes.pong));
        return;
      case tm.MessageTypes.response:
        _logger.info('Received response from the EBS server: $message');
        final completerId = message.internalClient!['completer_id'] as int;
        _completers.get(completerId)!.complete(message);
        return;
      case tm.MessageTypes.disconnect:
        _logger
            .severe('EBS server has disconnected, reconnecting in 10 seconds');
        Future.delayed(const Duration(seconds: 10)).then((_) => _connect());
        break;
      case tm.MessageTypes.get:
      case tm.MessageTypes.pong:
      case tm.MessageTypes.put:
        // From that point, we actually don't really care about the type of message
        // So, just accept all of them and proceed to the next switch
        break;
    }

    if (!message.isSuccess!) {
      _logger.severe(
          'Error while handling message from EBS: ${message.data?['error_message']}');
      return;
    }

    switch (message.data!['type'] as ToAppMessages) {
      case ToAppMessages.gameStateRequest:
        _sendGameStateToEbs(message);
        break;

      case ToAppMessages.pardonRequest:
        try {
          final player = gm.players.firstWhere(
              (player) => player.name == message.data?['player_name']);

          final response = message.copyWith(
              from: tm.MessageFrom.app,
              to: tm.MessageTo.frontend,
              type: tm.MessageTypes.response,
              isSuccess: gm.pardonLastStealer(pardonner: player));
          _sendMessageToEbs(response);
        } catch (e) {
          _logger.severe('Error while pardoning the stealer: $e');
          final response = message.copyWith(
              from: tm.MessageFrom.app,
              to: tm.MessageTo.frontend,
              type: tm.MessageTypes.response,
              isSuccess: false);
          _sendMessageToEbs(response);
        }
        break;

      case ToAppMessages.boostRequest:
        try {
          final player = gm.players.firstWhere(
              (player) => player.name == message.data?['player_name']);

          final response = message.copyWith(
              from: tm.MessageFrom.app,
              to: tm.MessageTo.ebsIsolated,
              type: tm.MessageTypes.response,
              isSuccess: gm.boostTrain(player));
          _sendMessageToEbs(response);
        } catch (e) {
          _logger.severe('Error while boosting the train: $e');
          final response = message.copyWith(
              from: tm.MessageFrom.app,
              to: tm.MessageTo.ebsIsolated,
              type: tm.MessageTypes.response,
              isSuccess: false);
          _sendMessageToEbs(response);
        }
        break;
    }
  }

  ///
  /// Send a message to the EBS server
  void _sendMessageToEbs(tm.MessageProtocol message) {
    final augmentedMessage = message.copyWith(
        from: message.from,
        to: message.to,
        type: message.type,
        data: (message.data ?? {})
          ..addAll({
            'broadcaster_id': TwitchManager.instance.broadcasterId,
          }));
    _socket!.sink.add(augmentedMessage.encode());
  }
}
