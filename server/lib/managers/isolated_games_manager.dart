import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:common/common.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_server/managers/game_manager.dart';
import 'package:train_de_mots_server/models/letter_problem.dart';

import 'package:http/http.dart' as http;

final _logger = Logger('IsolateGameManagers');

class _IsolateData {
  final int twitchBroadcasterId;
  final SendPort mainSendPort;

  _IsolateData({required this.twitchBroadcasterId, required this.mainSendPort});
}

class IsolatedGamesManager {
  // Prepare the singleton instance
  static final IsolatedGamesManager _instance =
      IsolatedGamesManager._internal();
  static IsolatedGamesManager get instance => _instance;
  IsolatedGamesManager._internal();

  final Map<int, Isolate> _isolates = {};
  final Map<int, SendPort> _workerSendPorts = {};

  ///
  /// Launch a new game
  Future<void> handleNewClientConnexion(int broadcasterId,
      {required WebSocket socket}) async {
    final mainReceivePort = ReceivePort();

    await _startNewGame(
        twitchBroadcasterId: broadcasterId,
        socket: socket,
        mainReceivePort: mainReceivePort);

    // Establish communication with the client
    socket.listen((message) =>
        _handleMessageFromClient(message, mainReceivePort, socket));
  }

  Future<void> _startNewGame({
    required int twitchBroadcasterId,
    required WebSocket socket,
    required ReceivePort mainReceivePort,
  }) async {
    final data = _IsolateData(
        twitchBroadcasterId: twitchBroadcasterId,
        mainSendPort: mainReceivePort.sendPort);

    // Keep track of the isolate game to kill it if required
    _isolates[twitchBroadcasterId] =
        await Isolate.spawn(_GameManagerIsolate.startNewGameManager, data);

    // Establish communication with the worker isolate
    mainReceivePort
        .listen((message) => _handleMessageFromIsolated(message, socket, data));

    socket.add(
        json.encode({'type': GameServerToClientMessages.isConnected.index}));
  }

  ///
  /// Stop all games
  void stopAllGames() {
    for (var isolate in _isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _workerSendPorts.clear();
  }

  void _handleMessageFromIsolated(
      message, WebSocket socket, _IsolateData data) {
    if (message is SendPort) {
      // Store the SendPort to communicate with the worker isolate
      _workerSendPorts[data.twitchBroadcasterId] = message;
    } else if (message is String) {
      // Send messages back to the client via WebSocket
      socket.add(message);
    } else {
      throw Exception('Unknown message type, this should not happen');
    }
  }

  void _handleMessageFromClient(
      message, ReceivePort mainReceivePort, WebSocket socket) {
    final data = jsonDecode(message);

    final broadcasterId = data['broadcasterId'];
    if (broadcasterId == null) {
      _logger.info('No broadcasterId provided in message: $message');
      return;
    }

    final sendPort = _workerSendPorts[broadcasterId];
    if (sendPort == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    // Relay the message to the worker isolate
    sendPort.send(data);
  }

  // TODO ADD WAY TO INFORM THE ISOLATED THAT THE CONNEXION WAS LOST
}

class _GameManagerIsolate {
  ///
  /// Start a new game manager, this is the entry point for the worker isolate
  static void startNewGameManager(_IsolateData data) async {
    final sendPort = data.mainSendPort;

    final receivePort = ReceivePort();
    sendPort
        .send(receivePort.sendPort); // Send the SendPort to the main isolate

    // await exampleAuth();

    final manager = GameManager(
        broadcasterId: data.twitchBroadcasterId, sendPort: sendPort);
    // Handle the relayed messages of the client via the main isolate
    receivePort.listen((message) => _handleMessageFromClient(message, manager));
  }

  ///
  /// Handle messages from the client and relay them to the game manager
  static void _handleMessageFromClient(data, GameManager manager) {
    _logger.info('Received message from client');

    // Parse and handle the message from the client. If the message is invalid,
    // send an error message back to the client
    try {
      final type = GameClientToServerMessages.values[data['type'] as int];

      switch (type) {
        case GameClientToServerMessages.newLetterProblemRequest:
          _handleGetNewLetterProblem(manager, request: data['data']);
          break;
        case GameClientToServerMessages.disconnect:
          manager.requestEndOfGame();
          break;
      }
    } on InvalidMessageException catch (e) {
      _sendMessageToClient(manager, type: e.message);
    } catch (e) {
      _sendMessageToClient(manager,
          type: GameServerToClientMessages.UnkownMessageException);
    }
  }

  static void _handleGetNewLetterProblem(GameManager manager,
      {required request}) {
    final problem = LetterProblem.generateProblemFromRequest(request);
    _sendMessageToClient(manager,
        type: GameServerToClientMessages.newLetterProblemGenerated,
        data: problem.serialize());
  }

  static void _sendMessageToClient(GameManager manager,
      {required GameServerToClientMessages type, dynamic data}) {
    final message = {
      'type': type.index,
      'data': data,
    };
    manager.sendPort.send(json.encode(message));
  }
}

Future<void> exampleAuth() async {
  final broadcasterId = '595803413';
  final extensionId = '539pzk7h6vavyzmklwy6msq6k3068x';
  final extensionVersion = '0.0.1';

  final clientSecret = Platform.environment['TRAIN_DE_MOTS_CLIENT_SECRET_KEY'];
  if (clientSecret == null) {
    throw ArgumentError(
        'No Twitch secret key provided, please provide one by setting '
        'TRAIN_DE_MOTS_CLIENT_SECRET_KEY environment variable');
  }

  final extensionSecret =
      Platform.environment['TRAIN_DE_MOTS_EXTENSION_SECRET'];
  if (extensionSecret == null) {
    throw ArgumentError(
        'No Twitch secret key provided, please provide one by setting '
        'TRAIN_DE_MOTS_EXTENSION_SECRET environment variable');
  }

  final jwt = JWT({
    'user_id': broadcasterId,
    'role': 'external',
    'exp': (DateTime.now().add(Duration(days: 1))).millisecondsSinceEpoch,
    'channel_id': 'all',
    "pubsub_perms": {
      "send": ["global"]
    }
  });

  final token = jwt.sign(SecretKey(clientSecret, isBase64Encoded: true),
      expiresIn: Duration(days: 1));

  final response = await http.post(
    Uri.https('api.twitch.tv', 'helix/extensions/chat',
        {'broadcaster_id': broadcasterId}),
    headers: <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
      'Client-Id': extensionId,
      HttpHeaders.contentTypeHeader: 'application/json',
    },
    body: '{'
        '"text": "Hello world!", '
        '"extension_id": "$extensionId",'
        '"extension_version": "$extensionVersion"'
        '}',
  );
  print('Response from sending message to chat');
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  print('');

  final bearerResponse =
      await http.post(Uri.https('id.twitch.tv', 'oauth2/token'), body: {
    'client_id': extensionId,
    'client_secret': extensionSecret,
    'grant_type': 'client_credentials',
  });
  print('Response from getting bearer token');
  print('Response status: ${bearerResponse.statusCode}');
  print('Response body: ${bearerResponse.body}');
  print('');
  final bearerToken = json.decode(bearerResponse.body)['access_token'];

  final authorizationUrl = Uri.https('id.twitch.tv', 'oauth2/authorize', {
    'response_type': 'code',
    'client_id': extensionId,
    'redirect_uri': 'https://localhost',
    'scope': 'user:write:chat user:bot',
    'state': 'c3ab8aa609ea11e793ae92361f002671',
  });
  print('Navigate to the following URL to authorize the extension:');
  print(authorizationUrl);

  final responseChat = await http.post(
    Uri.https('api.twitch.tv', 'helix/chat/messages',
        {'broadcaster_id': broadcasterId}),
    headers: <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
      'Client-Id': extensionId,
      HttpHeaders.contentTypeHeader: 'application/json',
    },
    body: '{'
        '"broadcaster_id": "$broadcasterId", '
        '"sender_id": "$broadcasterId",'
        '"message": "Yoooo!"'
        '}',
  );
  print('Response from sending message to chat');
  print('Response status: ${responseChat.statusCode}');
  print('Response body: ${responseChat.body}');
  print('');
}
