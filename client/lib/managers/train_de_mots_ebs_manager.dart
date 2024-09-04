import 'dart:async';
import 'dart:convert';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('TrainDeMotEbsManager');

class TrainDeMotsEbsManager {
  // Singleton
  static TrainDeMotsEbsManager get instance {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _instance!;
  }

  static TrainDeMotsEbsManager? _instance;
  TrainDeMotsEbsManager._internal({required Uri? ebsUri}) : _ebsUri = ebsUri;

  WebSocketChannel? _socket;

  final Uri? _ebsUri;
  bool _isConnectedToEbs = false;
  bool get isConnectedToEbs => _isConnectedToEbs;

  ///
  /// Initialize the TrainDeMotsEbsManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  static Future<void> initialize({required Uri? ebsUri}) async {
    if (_instance != null) return;

    _instance = TrainDeMotsEbsManager._internal(ebsUri: ebsUri);
  }

  ///
  /// Connect to the ebs
  Future<void> connectToEbs() async {
    // TODO Fail gracefully if the server is not available
    final twitchBroadcasterId = TwitchManager.instance.broadcasterId;
    if (_ebsUri == null) return;

    _instance!._socket = WebSocketChannel.connect(Uri.parse(
        '$_ebsUri/client/connect?broadcasterId=$twitchBroadcasterId'));
    await _instance!._socket!.ready;
    _logger.info('Connected to the EBS server');

    _instance!._socket!.stream.listen(
      _instance!._handleMessageFromEbs,
      onDone: () => _logger.info('Connection closed by the EBS server'),
      onError: (error) => _logger.severe('Error: $error'),
    );

    while (!_isConnectedToEbs) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Connect the listeners to the GameManager
    GameManager.instance.onStealerPardoned
        .addListener(_sendStealerWasPardonedToFrontend);
    GameManager.instance.onSolutionWasStolen
        .addListener(_sendSolutionWasStolenToFrontend);

    _logger.info('Connected to the EBS server');
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void dispose() {
    GameManager.instance.onStealerPardoned
        .removeListener(_sendStealerWasPardonedToFrontend);
    GameManager.instance.onSolutionWasStolen
        .removeListener(_sendSolutionWasStolenToFrontend);
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
      _logger.severe('Failed to get a new letter problem in time');
      _completers[LetterProblem]!
          .completeError('Failed to get a new letter problem in time');
    });

    _logger.info('Requesting a new letter problem with config');
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

  ///
  /// Handle the new letter problem received from the EBS server and complete the
  /// completer.
  void _receivedNewLetterProblemFromEbs(Map<String, dynamic> message) {
    _logger.info('Received new letter problem: $message');
    _completers[LetterProblem]!.complete(message);
  }

  ///
  /// Send a message to the EBS server to notify that a stealer has been pardoned
  /// by the broadcaster to the frontends.
  void _sendStealerWasPardonedToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(
          type: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'users_who_can_pardon': ''});

  void _sendSolutionWasStolenToFrontend(WordSolution? solution) =>
      _sendMessageToEbs(
          type: FromClientToEbsMessages.pardonStatusUpdate,
          data: {'users_who_can_pardon': solution?.stolenFrom.name});

  ///
  /// Handle the messages received from the EBS server
  void _handleMessageFromEbs(message) {
    final messageDecoded = json.decode(message);
    final type = FromEbsToClientMessages.values[messageDecoded['type'] as int];
    final data = messageDecoded['data'] as Map<String, dynamic>?;

    switch (type) {
      case FromEbsToClientMessages.isConnected:
        _logger.info('Connected to the EBS server');
        _isConnectedToEbs = true;
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
