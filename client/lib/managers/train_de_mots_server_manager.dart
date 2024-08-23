import 'dart:convert';

import 'package:common/common.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('TrainDeMotsServerManager');

class TrainDeMotsServerManager {
  // Singleton
  static TrainDeMotsServerManager get instance {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _instance!;
  }

  static TrainDeMotsServerManager? _instance;
  TrainDeMotsServerManager._internal({required Uri uri}) : _uri = uri;

  WebSocketChannel? _socket;

  // Attributes
  final Uri _uri;
  Uri get uri {
    if (_instance == null) {
      throw Exception(
          'TrainDeMotsManager not initialized, call initialize() first');
    }
    return _uri;
  }

  // Methods
  static Future<void> initialize(
      {required Uri uri, required Uri? gameServerUri}) async {
    if (_instance != null) return;

    _instance = TrainDeMotsServerManager._internal(uri: uri);

    if (gameServerUri == null) return;

    _instance!._socket = WebSocketChannel.connect(gameServerUri);
    await _instance!._socket!.ready;
    _logger.info('Connected to the server');

    _instance!._socket!.stream.listen(
      _instance!._onMessageFromServerReceived,
      onDone: () => _logger.info('Connection closed by the server'),
      onError: (error) => _logger.severe('Error: $error'),
    );
  }

  void _onMessageFromServerReceived(message) {
    final data = json.decode(message);
    final type = GameServerToClientMessages.values[data['type'] as int];

    switch (type) {
      case GameServerToClientMessages.newLetterProblemGenerated:
        _receivedNewLetterProblem(data['data'] as Map<String, dynamic>);
        break;
      case GameServerToClientMessages.UnkownMessageException:
      case GameServerToClientMessages.InvalidAlgorithmException:
      case GameServerToClientMessages.InvalidTimeoutException:
      case GameServerToClientMessages.InvalidConfigurationException:
        _logger.severe('Error: $type');
    }
  }

  Future<Map<String, dynamic>> requestNewLetterProblem({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) async {
    final configLetterProblemConfig = {
      'algorithm': 'fromRandomWord',
      'lengthShortestSolutionMin': nbLetterInSmallestWord,
      'lengthShortestSolutionMax': nbLetterInSmallestWord,
      'lengthLongestSolutionMin': minLetters,
      'lengthLongestSolutionMax': maxLetters,
      'nbSolutionsMin': minimumNbOfWords,
      'nbSolutionsMax': maximumNbOfWords,
      'nbUselessLetters': addUselessLetter ? 1 : 0,
      'timeout': maxSearchingTime.inSeconds,
    };

    _logger.info('Requesting a new letter problem with config');
    _lastLetterProblem = null;
    _sendMessageToServer(
      type: GameClientToServerMessages.newLetterProblemRequest,
      data: configLetterProblemConfig,
    );

    // Wait for the server to send the new letter problem
    final startTime = DateTime.now();
    while (_lastLetterProblem == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_socket == null ||
          startTime.difference(DateTime.now()).inSeconds >
              maxSearchingTime.inSeconds) {
        _logger.severe('Failed to get a new letter problem');
        throw Exception('Failed to get a new letter problem');
      }
    }
    final tp = _lastLetterProblem;
    _lastLetterProblem = null;
    return tp!;
  }

  Map<String, dynamic>? _lastLetterProblem;
  void _receivedNewLetterProblem(Map<String, dynamic> message) {
    _logger.info('Received new letter problem: $message');
    _lastLetterProblem = message;
  }

  void _sendMessageToServer(
      {required GameClientToServerMessages type,
      required Map<String, dynamic> data}) {
    final message = {
      'bearer': '123456',
      'type': type.index,
      'data': data,
    };
    _socket!.sink.add(json.encode(message));
  }
}
