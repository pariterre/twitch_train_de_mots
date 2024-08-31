import 'dart:async';
import 'dart:convert';

import 'package:common/common.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
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
  TrainDeMotsEbsManager._internal({required Uri httpUri, required Uri? ebsUri})
      : _httpUri = httpUri,
        _ebsUri = ebsUri;

  WebSocketChannel? _socket;

  // Attributes
  final Uri _httpUri;
  Uri get httpUri {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _httpUri;
  }

  final Uri? _ebsUri;
  bool _isConnectedToEbs = false;
  bool get isConnectedToEbs => _isConnectedToEbs;

  ///
  /// Initialize the TrainDeMotsEbsManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  static Future<void> initialize(
      {required Uri httpUri, required Uri? ebsUri}) async {
    if (_instance != null) return;

    _instance =
        TrainDeMotsEbsManager._internal(httpUri: httpUri, ebsUri: ebsUri);
  }

  ///
  /// Connect to the ebs
  Future<void> connectToEbs() async {
    // TODO Fail gracefully if the server is not available
    final twitchBroadcasterId = TwitchManager.instance.broadcasterId;
    if (_ebsUri == null) return;

    _instance!._socket = WebSocketChannel.connect(
        Uri.parse('$_ebsUri/startGame?broadcasterId=$twitchBroadcasterId'));
    await _instance!._socket!.ready;
    _logger.info('Connected to the EBS server');

    _instance!._socket!.stream.listen(
      _instance!._onMessageFromEbsReceived,
      onDone: () => _logger.info('Connection closed by the EBS server'),
      onError: (error) => _logger.severe('Error: $error'),
    );

    while (!_isConnectedToEbs) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _logger.info('Connected to the EBS server');
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void dispose() {
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
  Completer requestNewLetterProblem({
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
      type: ToEbsMessages.newLetterProblemRequest,
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
  /// Internal methods
  ///

  ///
  /// Handle the messages received from the EBS server
  void _onMessageFromEbsReceived(message) {
    final data = json.decode(message);
    final type = FromEbsMessages.values[data['type'] as int];

    switch (type) {
      case FromEbsMessages.isConnected:
        _logger.info('Connected to the EBS server');
        _isConnectedToEbs = true;
        break;
      case FromEbsMessages.newLetterProblemGenerated:
        _receivedNewLetterProblem(data['data'] as Map<String, dynamic>);
        break;
      case FromEbsMessages.UnkownMessageException:
      case FromEbsMessages.NoBroadcasterIdException:
      case FromEbsMessages.InvalidAlgorithmException:
      case FromEbsMessages.InvalidTimeoutException:
      case FromEbsMessages.InvalidConfigurationException:
        _logger.severe('Error: $type');
    }
  }

  ///
  /// Handle the new letter problem received from the EBS server and complete the
  /// completer.
  void _receivedNewLetterProblem(Map<String, dynamic> message) {
    _logger.info('Received new letter problem: $message');
    _completers[LetterProblem]!.complete(message);
  }

  ///
  /// Send a message to the EBS server
  void _sendMessageToEbs(
      {required ToEbsMessages type, required Map<String, dynamic> data}) {
    final message = {
      'broadcasterId': TwitchManager.instance.broadcasterId,
      'type': type.index,
      'data': data,
    };
    _socket!.sink.add(json.encode(message));
  }
}
