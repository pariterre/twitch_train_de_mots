import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:common/models/ebs_messages.dart';
import 'package:common/models/exceptions.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/game_manager.dart';
import 'package:train_de_mots_ebs/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';

final _logger = Logger('IsolateGameManagers');

class _IsolateData {
  final int twitchBroadcasterId;
  final SendPort mainSendPort;

  _IsolateData({required this.twitchBroadcasterId, required this.mainSendPort});
}

enum MessageTarget {
  internal,
  client,
  frontend;
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
        await Isolate.spawn(_IsolatedGame.startNewGameManager, data);

    // Establish communication with the worker isolate
    mainReceivePort
        .listen((message) => _handleMessageFromIsolated(message, socket, data));

    _handleMessageFromInternalToClient(
        {'type': FromEbsMessages.isConnected.index}, socket);
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
    final target = MessageTarget.values[message['target']];
    switch (target) {
      case MessageTarget.internal:
        _handleMessageFromIsolatedToInternal(message['message'], data, socket);
        break;
      case MessageTarget.client:
        _handleMessageFromInternalToClient(message['message'], socket);
        break;
      case MessageTarget.frontend:
        _handleMessageFromIsolatedToFrontend(message['message'], socket);
        break;
    }
  }

  void _handleMessageFromIsolatedToInternal(
      message, _IsolateData data, WebSocket socket) {
    if (message is SendPort) {
      // Store the SendPort to communicate with the worker isolate
      _workerSendPorts[data.twitchBroadcasterId] = message;
    } else {
      throw Exception('Unknown message type, this should not happen');
    }
  }

  void _handleMessageFromInternalToClient(
      Map<String, dynamic> message, WebSocket socket) {
    socket.add(json.encode(message));
  }

  void _handleMessageFromIsolatedToFrontend(
      Map<String, dynamic> message, WebSocket socket) {
    TwitchManagerExtension.instance.sendExtentionMessage(message['data']);
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

class _IsolatedGame {
  ///
  /// Start a new game manager, this is the entry point for the worker isolate
  static void startNewGameManager(_IsolateData data) async {
    final sendPort = data.mainSendPort;

    final receivePort = ReceivePort();
    sendPort.send({
      'target': MessageTarget.internal.index,
      'message': receivePort.sendPort
    }); // Send the SendPort to the main isolate

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
      final type = ToEbsMessages.values[data['type'] as int];

      switch (type) {
        case ToEbsMessages.newLetterProblemRequest:
          _handleGetNewLetterProblem(manager, request: data['data']);
          break;
        case ToEbsMessages.disconnect:
          manager.requestEndOfGame();
          break;
      }
    } on InvalidMessageException catch (e) {
      _sendMessageToClient(manager, type: e.message);
    } catch (e) {
      _sendMessageToClient(manager,
          type: FromEbsMessages.unkownMessageException);
    }
  }

  static void _handleGetNewLetterProblem(GameManager manager,
      {required request}) {
    final problem = LetterProblem.generateProblemFromRequest(request);
    _sendMessageToClient(manager,
        type: FromEbsMessages.newLetterProblemGenerated,
        data: problem.serialize());
  }

  static void _sendMessageToClient(GameManager manager,
      {required FromEbsMessages type, dynamic data}) {
    final message = {
      'target': MessageTarget.client.index,
      'message': {
        'type': type.index,
        'data': data,
      }
    };
    manager.sendPort.send(message);
  }
}
