import 'dart:async';
import 'dart:convert';

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
    _instance?._connect();
  }

  ///
  /// Connect to the ebs
  Completer<bool>? _connectingToEbsCompleter;
  Future<bool> _connect() async {
    Future<bool> retryOnFail(String errormessage) async {
      _logger.severe(errormessage);
      _isConnectedToEbs = false;
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
      type: FromClientToEbsMessages.newLetterProblemRequest,
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
  /// Send a message to the EBS server to notify that a stealer has been pardoned
  /// by the broadcaster to the frontends.
  void _sendStealerWasPardonedToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(
          type: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'pardonner_user_id': ''});

  void _sendSolutionWasStolenToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(
          type: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'pardonner_user_id': solution?.stolenFrom.name});

  ///
  /// Handle the messages received from the EBS server
  void _handleMessageFromEbs(message) {
    final messageDecoded = json.decode(message);
    final type = FromEbsToClientMessages.values[messageDecoded['type'] as int];
    final data = messageDecoded['data'] as Map<String, dynamic>?;

    switch (type) {
      case FromEbsToClientMessages.isConnected:
        _logger.info('Client has connected to the EBS server');
        _connectingToEbsCompleter?.complete(true);
        break;

      case FromEbsToClientMessages.newLetterProblemGenerated:
        _receivedNewLetterProblemFromEbs(data!);
        break;

      case FromEbsToClientMessages.pardonRequest:
        final gm = GameManager.instance;
        try {
          final player = gm.players
              .firstWhere((player) => player.name == data!['player_name']);
          gm.pardonLastStealer(playerWhoRequestedPardon: player);
        } catch (e) {
          _logger.severe('Error while pardoning the stealer: $e');
          return;
        }
        break;

      case FromEbsToClientMessages.ping:
        _logger.info('Ping received');
        break;
      case FromEbsToClientMessages.unkownMessageException:
      case FromEbsToClientMessages.noBroadcasterIdException:
      case FromEbsToClientMessages.invalidAlgorithmException:
      case FromEbsToClientMessages.invalidTimeoutException:
      case FromEbsToClientMessages.invalidConfigurationException:
        _logger.severe('Error: $type');
    }
  }

  ///
  /// Send a message to the EBS server
  void _sendMessageToEbs(
      {required FromClientToEbsMessages type, Map<String, dynamic>? data}) {
    final message = {
      'broadcasterId': TwitchManager.instance.broadcasterId,
      'type': type.index,
      'data': data,
    };
    _socket!.sink.add(json.encode(message));
  }
}
