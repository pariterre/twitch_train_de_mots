import 'dart:async';
import 'dart:convert';

import 'package:common/common.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
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
  TrainDeMotsServerManager._internal(
      {required Uri uri, required Uri? gameServerUri})
      : _uri = uri,
        _gameServerUri = gameServerUri;

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

  final Uri? _gameServerUri;
  bool _isConnectedToGameServer = false;
  bool get isConnectedToGameServer => _isConnectedToGameServer;

  ///
  /// Initialize the TrainDeMotsServerManager establishing a connection with the
  /// game server if [gameServerUri] is provided.
  static Future<void> initialize(
      {required Uri uri, required Uri? gameServerUri}) async {
    if (_instance != null) return;

    _instance = TrainDeMotsServerManager._internal(
        uri: uri, gameServerUri: gameServerUri);
  }

  ///
  /// Connect to the game server
  Future<void> connectToGameServer() async {
    final twitchBroadcasterId = TwitchManager.instance.broadcasterId;
    if (_gameServerUri == null) return;

    _instance!._socket = WebSocketChannel.connect(Uri.parse(
        '$_gameServerUri/startGame?broadcasterId=$twitchBroadcasterId'));
    await _instance!._socket!.ready;
    _logger.info('Connected to the server');

    _instance!._socket!.stream.listen(
      _instance!._onMessageFromServerReceived,
      onDone: () => _logger.info('Connection closed by the server'),
      onError: (error) => _logger.severe('Error: $error'),
    );

    while (!_isConnectedToGameServer) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _logger.info('Connected to the game server');
  }

  ///
  /// Dispose the TrainDeMotsServerManager by closing the connection with the
  /// game server.
  void dispose() {
    _socket?.sink.close();
  }

  ///
  /// API section under the the for of requests to the server
  ///
  final Map<dynamic, Completer> _completers = {};

  ///
  /// Request a new letter problem, it will return a completer that will complete
  /// when the server sends the new letter problem. Note requesting twice will
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
    _sendMessageToServer(
      type: GameClientToServerMessages.newLetterProblemRequest,
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
  /// Handle the messages received from the server
  void _onMessageFromServerReceived(message) {
    final data = json.decode(message);
    final type = GameServerToClientMessages.values[data['type'] as int];

    switch (type) {
      case GameServerToClientMessages.isConnected:
        _logger.info('Connected to the game server');
        _isConnectedToGameServer = true;
        break;
      case GameServerToClientMessages.newLetterProblemGenerated:
        _receivedNewLetterProblem(data['data'] as Map<String, dynamic>);
        break;
      case GameServerToClientMessages.UnkownMessageException:
      case GameServerToClientMessages.NoBroadcasterIdException:
      case GameServerToClientMessages.InvalidAlgorithmException:
      case GameServerToClientMessages.InvalidTimeoutException:
      case GameServerToClientMessages.InvalidConfigurationException:
        _logger.severe('Error: $type');
    }
  }

  ///
  /// Handle the new letter problem received from the server and complete the
  /// completer.
  void _receivedNewLetterProblem(Map<String, dynamic> message) {
    _logger.info('Received new letter problem: $message');
    _completers[LetterProblem]!.complete(message);
  }

  ///
  /// Send a message to the server
  void _sendMessageToServer(
      {required GameClientToServerMessages type,
      required Map<String, dynamic> data}) {
    final message = {
      'broadcasterId': TwitchManager.instance.broadcasterId,
      'type': type.index,
      'data': data,
    };
    _socket!.sink.add(json.encode(message));
  }
}
