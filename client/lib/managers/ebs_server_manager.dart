import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/word_solution.dart';
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
  /// Connect to the ebs
  Completer<bool>? _connectingToEbsCompleter;
  Future<bool> _connect() async {
    Future<bool> retryOnFail(String errormessage) async {
      _logger.severe(errormessage);
      _isConnectedToEbs = false;
      // Stop listening to the messages from the EBS server
      _instance!._socket?.sink.close();
      _logger.severe('Reconnecting to EBS in 10 seconds');
      await Future.delayed(const Duration(seconds: 10));
      _connectingToEbsCompleter = null;
      _connect();
      return _connectingToEbsCompleter!.future;
    }

    if (_ebsUri == null) return false;

    // If we already are connecting, return the future
    if (_connectingToEbsCompleter != null) {
      return _connectingToEbsCompleter!.future;
    }
    _connectingToEbsCompleter = Completer();

    // Connect to EBS server
    try {
      final twitchBroadcasterId = TwitchManager.instance.broadcasterId;
      _instance!._socket = WebSocketChannel.connect(Uri.parse(
          '$_ebsUri/client/connect?broadcasterId=$twitchBroadcasterId'));
      await _instance!._socket!.ready;
    } catch (e) {
      return retryOnFail('Could not connect to EBS');
    }

    // Listen to the messages from the EBS server
    _instance!._socket!.stream.listen(
      _instance!._handleMessageFromEbs,
      onDone: () {
        retryOnFail('Connection closed by the EBS server');
      },
      onError: (error) {
        retryOnFail('Error with communicating to the EBS server: $error');
      },
    );

    try {
      _isConnectedToEbs = await _instance!._connectingToEbsCompleter!.future
          .timeout(const Duration(seconds: 10));
      if (!_isConnectedToEbs) throw Exception('Could not connect to EBS');
    } catch (e) {
      return retryOnFail('Could not connect to EBS');
    }

    // Connect the listeners to the GameManager
    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_sendRoundStartedToFrontend);
    gm.onRoundIsOver.addListener(_sendRoundEndedToFrontend);
    gm.onStealerPardoned.addListener(_sendStealerWasPardonedToFrontend);
    gm.onSolutionWasStolen.addListener(_sendSolutionWasStolenToFrontend);
    gm.onRoundIsOver.addListener(_onRoundIsOver);

    _logger.info('Connected to the EBS server');
    return true;
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_sendRoundStartedToFrontend);
    gm.onRoundIsOver.removeListener(_sendRoundEndedToFrontend);
    gm.onStealerPardoned.removeListener(_sendStealerWasPardonedToFrontend);
    gm.onSolutionWasStolen.removeListener(_sendSolutionWasStolenToFrontend);
    gm.onRoundIsOver.removeListener(_onRoundIsOver);
    _socket?.sink.close();
  }

  ///
  /// API section under the the for of requests to the EBS server
  ///
  final Map<dynamic, Completer> _completers = {};

  ///
  /// Request a new letter problem, it will return a completer that will complete
  /// when the EBS server sends the new letter problem. Note requesting twice will
  /// result in undefined behavior.
  Completer generateLetterProblem({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) {
    // Create a new completer with a timout of maxSearchingTime
    _completers[LetterProblem] = Completer();

    _completers[LetterProblem]!.future.timeout(maxSearchingTime, onTimeout: () {
      _logger
          .severe('Failed to get a new letter problem from EBS server in time');
      _completers[LetterProblem]!.completeError(
          'Failed to get a new letter problem from EBS server in time');
    });

    _logger.info('Requesting a new letter problem to EBS server');
    _sendMessageToEbs(
      MessageProtocol(
        fromTo: FromClientToEbsMessages.newLetterProblemRequest,
        data: {
          'algorithm': 'fromRandomWord',
          'lengthShortestSolutionMin': nbLetterInSmallestWord,
          'lengthShortestSolutionMax': nbLetterInSmallestWord,
          'lengthLongestSolutionMin': minLetters,
          'lengthLongestSolutionMax': maxLetters,
          'nbSolutionsMin': minimumNbOfWords,
          'nbSolutionsMax': maximumNbOfWords,
          'nbUselessLetters': addUselessLetter ? 1 : 0,
          'timeout': maxSearchingTime.inSeconds,
        },
      ),
    );

    return _completers[LetterProblem]!;
  }

  void _onRoundIsOver(bool playSound) {
    _sendStealerWasPardonedToFrontend(null);
  }

  ///
  /// Handle the new letter problem received from the EBS server and complete the
  /// completer.
  void _receivedNewLetterProblemFromEbs(Map<String, dynamic> message) {
    _logger.info('Received new letter problem from EBS server: $message');
    _completers[LetterProblem]!.complete(message);
  }

  ///
  /// Send a message to the EBS server to notify that a new round has started
  Future<void> _sendRoundStartedToFrontend() async {
    _sendMessageToEbs(
        MessageProtocol(fromTo: FromClientToEbsMessages.roundStarted));
  }

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendRoundEndedToFrontend(_) async {
    _sendMessageToEbs(
        MessageProtocol(fromTo: FromClientToEbsMessages.roundEnded));
  }

  ///
  /// Send a message to the EBS server to notify that a stealer has been pardoned
  /// by the broadcaster to the frontends.
  void _sendStealerWasPardonedToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(MessageProtocol(
          fromTo: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'pardonner_user_id': ''}));

  ///
  /// Send a message to the EBS server to notify that a solution has been stolen
  /// by a player to the frontends.
  void _sendSolutionWasStolenToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(MessageProtocol(
          fromTo: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'pardonner_user_id': solution?.stolenFrom.name}));

  ///
  /// Handle the messages received from the EBS server
  void _handleMessageFromEbs(raw) {
    final gm = GameManager.instance;
    final message = MessageProtocol.decode(raw);

    switch (message.fromTo as FromEbsToClientMessages) {
      case FromEbsToClientMessages.isConnected:
        _logger.info('Client has connected to the EBS server');
        _connectingToEbsCompleter?.complete(true);
        break;

      case FromEbsToClientMessages.newLetterProblemGenerated:
        _receivedNewLetterProblemFromEbs(message.data!);
        break;

      case FromEbsToClientMessages.pardonRequest:
        try {
          final player = gm.players.firstWhere(
              (player) => player.name == message.data?['player_name']);

          final response = message.copyWith(
              fromTo: FromClientToEbsMessages.pardonRequestStatus,
              isSuccess: gm.pardonLastStealer(pardonner: player));
          _sendMessageToEbs(response);
        } catch (e) {
          _logger.severe('Error while pardoning the stealer: $e');
          final response = message.copyWith(
              fromTo: FromClientToEbsMessages.pardonRequestStatus,
              isSuccess: false);
          _sendMessageToEbs(response);
        }
        break;

      case FromEbsToClientMessages.boostRequest:
        try {
          final player = gm.players.firstWhere(
              (player) => player.name == message.data?['player_name']);

          final response = message.copyWith(
              fromTo: FromClientToEbsMessages.pardonRequestStatus,
              isSuccess: gm.boostTrain(player));
          _sendMessageToEbs(response);
        } catch (e) {
          _logger.severe('Error while boosting the train: $e');
          final response = message.copyWith(
              fromTo: FromClientToEbsMessages.pardonRequestStatus,
              isSuccess: false);
          _sendMessageToEbs(response);
        }
        break;

      case FromEbsToClientMessages.ping:
        _logger.info('Ping received, sending pong');
        final response = message.copyWith(
            fromTo: FromClientToEbsMessages.pong, data: {'response': 'PONG'});
        _sendMessageToEbs(response);
        break;

      case FromEbsToClientMessages.disconnect:
        _logger
            .severe('EBS server has disconnected, reconnecting in 10 seconds');
        Future.delayed(const Duration(seconds: 10)).then((_) => _connect());
        break;
      case FromEbsToClientMessages.unkownMessageException:
      case FromEbsToClientMessages.noBroadcasterIdException:
      case FromEbsToClientMessages.invalidAlgorithmException:
      case FromEbsToClientMessages.invalidTimeoutException:
      case FromEbsToClientMessages.invalidConfigurationException:
        _logger.severe('Error: ${message.fromTo}');
    }
  }

  ///
  /// Send a message to the EBS server
  void _sendMessageToEbs(MessageProtocol message) {
    final augmentedMessage = message.copyWith(
        data: message.data ?? {}
          ..addAll({
            'broadcaster_id': TwitchManager.instance.broadcasterId,
          }));
    _socket!.sink.add(augmentedMessage.encode());
  }
}
