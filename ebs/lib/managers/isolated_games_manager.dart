import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/exceptions.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/game_manager.dart';
import 'package:train_de_mots_ebs/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_ebs/models/completers.dart';

final _logger = Logger('IsolateGameManagers');

class _IsolateData {
  final int twitchBroadcasterId;
  final SendPort mainSendPort;

  _IsolateData({required this.twitchBroadcasterId, required this.mainSendPort});
}

enum MessageTarget {
  manager,
  client,
  frontend;
}

class _IsolateInterface {
  final Isolate isolate;
  SendPort? sendPortManager;
  SendPort? sendPortClient;
  SendPort? sendPortFrontend;

  void clear() {
    isolate.kill(priority: Isolate.immediate);
    sendPortManager = null;
    sendPortClient = null;
    sendPortFrontend = null;
  }

  _IsolateInterface({required this.isolate});
}

class IsolatedGamesManager {
  // Prepare the singleton instance
  static final IsolatedGamesManager _instance =
      IsolatedGamesManager._internal();
  static IsolatedGamesManager get instance => _instance;
  IsolatedGamesManager._internal();

  final _completers = Completers();
  final Map<int, _IsolateInterface> _isolates = {};

  ///
  /// Launch a new game
  Future<void> newClient(int broadcasterId, {required WebSocket socket}) async {
    final mainReceivePort = ReceivePort();
    final data = _IsolateData(
        twitchBroadcasterId: broadcasterId,
        mainSendPort: mainReceivePort.sendPort);

    // Keep track of the isolate game to kill it if required
    _isolates[broadcasterId] = _IsolateInterface(
        isolate: await Isolate.spawn(_IsolatedGame.startNewGameManager, data));

    // Establish communication with the worker isolate
    mainReceivePort
        .listen((message) => _handleMessageFromIsolated(message, socket, data));

    // Emulate an is connected message to send to the client
    _handleMessageFromIsolatedToClient({
      'message': {'type': FromEbsToClientMessages.isConnected.index}
    }, socket);
  }

  ///
  /// Stop all games
  void stopAllGames() {
    for (var interface in _isolates.values) {
      interface.clear();
    }
    _isolates.clear();
  }

  Future<void> _handleMessageFromIsolated(
      message, WebSocket socket, _IsolateData data) async {
    final target = MessageTarget.values[message['target']];
    switch (target) {
      case MessageTarget.manager:
        await _handleMessageFromIsolatedToManager(message, data, socket);
        break;
      case MessageTarget.client:
        await _handleMessageFromIsolatedToClient(message, socket);
        break;
      case MessageTarget.frontend:
        await _handleMessageFromIsolatedToFrontend(message, socket);
        break;
    }
  }

  Future<void> _handleMessageFromIsolatedToManager(
      rawMessage, _IsolateData isolateData, WebSocket socket) async {
    final message = rawMessage['message'];

    final tm = TwitchManagerExtension.instance;
    final type = FromEbsToManagerMessages.values[message['type'] as int];
    final data = message['data'];

    switch (type) {
      case FromEbsToManagerMessages.initialize:
        final isolate = _isolates[isolateData.twitchBroadcasterId]!;

        isolate.sendPortManager = data['sendPortManager'];
        isolate.sendPortClient = data['sendPortClient'];
        isolate.sendPortFrontend = data['sendPortFrontend'];
        break;

      case FromEbsToManagerMessages.responseInternal:
        final completerId = rawMessage['internal_main']['completer_id'] as int;
        _completers.complete(completerId, data);
        break;

      case FromEbsToManagerMessages.getUserId:
        final login = data['login'];
        final userId = await tm.userId(login: login);

        messageFromManagerToIsolated(
          broadcasterId: isolateData.twitchBroadcasterId,
          type: FromManagerToEbsMessages.getUserId,
          data: {'user_id': userId},
          internalIsolate: rawMessage['internal_isolate'],
        );
        break;
      case FromEbsToManagerMessages.getDisplayName:
        final userId = data['user_id'];
        final displayName = await tm.displayName(userId: userId);

        messageFromManagerToIsolated(
          broadcasterId: isolateData.twitchBroadcasterId,
          type: FromManagerToEbsMessages.getDisplayName,
          data: {'display_name': displayName},
          internalIsolate: rawMessage['internal_isolate'],
        );
        break;

      case FromEbsToManagerMessages.getLogin:
        final userId = data['user_id'];
        final login = await tm.login(userId: userId);

        messageFromManagerToIsolated(
          broadcasterId: isolateData.twitchBroadcasterId,
          type: FromManagerToEbsMessages.getLogin,
          data: {'login': login},
          internalIsolate: rawMessage['internal_isolate'],
        );
        break;
    }
  }

  Future<void> _handleMessageFromIsolatedToClient(
      Map<String, dynamic> message, WebSocket socket) async {
    socket.add(json.encode(message['message']));
  }

  Future<void> _handleMessageFromIsolatedToFrontend(
      Map<String, dynamic> message, WebSocket socket) async {
    TwitchManagerExtension.instance.sendExtentionMessage(message['message']);
  }

  Future<void> messageFromClientToIsolated(message, WebSocket socket) async {
    final data = jsonDecode(message);

    final broadcasterId = data['broadcasterId'];
    final sendPortClient = _isolates[broadcasterId]?.sendPortClient;
    if (sendPortClient == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    // Relay the message to the worker isolate
    sendPortClient.send(data);
  }

  // TODO Add a way to inform the client that the connexion was lost and kill the isolate if too long before reconnecting

  Future<Map<String, dynamic>> messageFromFrontendToIsolated({
    required int broadcasterId,
    required FromFrontendToEbsMessages type,
    Map<String, dynamic>? data,
  }) async {
    final sendPortFrontend = _isolates[broadcasterId]?.sendPortFrontend;
    if (sendPortFrontend == null) {
      _logger.info('No active game with id: $broadcasterId');
      return {'status': 'NOK'};
    }

    // Relay the message to the worker isolate
    final completerId = _completers.spawn();
    sendPortFrontend.send({
      'type': type.index,
      'data': data,
      'internal_main': {'completer_id': completerId}
    });

    return await _completers.get(completerId)!.future;
  }

  Future<void> messageFromManagerToIsolated({
    required int broadcasterId,
    required FromManagerToEbsMessages type,
    Map<String, dynamic>? data,
    Map<String, dynamic>? internalIsolate,
  }) async {
    final sendPortManager = _isolates[broadcasterId]?.sendPortManager;
    if (sendPortManager == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    // Relay the message to the worker isolate
    final response = {
      'type': type.index,
      'data': data,
      'internal_isolate': internalIsolate
    };

    sendPortManager.send(response);
  }
}

class _IsolatedGame {
  ///
  /// Start a new game manager, this is the entry point for the worker isolate
  static void startNewGameManager(_IsolateData data) async {
    final sendPort = data.mainSendPort;

    final receivePortManager = ReceivePort();
    final receivePortClient = ReceivePort();
    final receivePortFrontend = ReceivePort();

    final manager = GameManager(
        broadcasterId: data.twitchBroadcasterId, sendPort: sendPort);

    // Send the SendPort to the main isolate, so it can communicate back to the isolate
    manager.communications
        .sendMessageToManager(type: FromEbsToManagerMessages.initialize, data: {
      'sendPortManager': receivePortManager.sendPort,
      'sendPortClient': receivePortClient.sendPort,
      'sendPortFrontend': receivePortFrontend.sendPort
    });

    // Handle the messages from the manager, client or frontends
    receivePortManager
        .listen((message) => _handleMessageFromManager(message, manager));
    receivePortClient
        .listen((message) => _handleMessageFromClient(message, manager));
    receivePortFrontend
        .listen((message) => _handleMessageFromFrontend(message, manager));
  }

  static Future<void> _handleMessageFromManager(
      message, GameManager manager) async {
    _logger.info('Received message from manager');

    // Parse and handle the message from the manager. If the message is invalid,
    // it sends an error message back to the client
    final type = FromManagerToEbsMessages.values[message['type'] as int];
    final data = message['data'];
    final completerId = message['internal_isolate']['completer_id'];

    switch (type) {
      case FromManagerToEbsMessages.getUserId:
        manager.communications
            .complete(completerId: completerId, data: data['user_id']);
        break;
      case FromManagerToEbsMessages.getDisplayName:
        manager.communications
            .complete(completerId: completerId, data: data['display_name']);
        break;
      case FromManagerToEbsMessages.getLogin:
        manager.communications
            .complete(completerId: completerId, data: data['login']);
        break;
    }
  }

  ///
  /// Handle messages from the client and relay them to the game manager
  static Future<void> _handleMessageFromClient(
      message, GameManager manager) async {
    _logger.info('Received message from client or frontend');

    // Parse and handle the message from the client. If the message is invalid,
    // it sends an error message back to the client
    try {
      final type = FromClientToEbsMessages.values[message['type'] as int];
      final data = message['data'];

      switch (type) {
        case FromClientToEbsMessages.newLetterProblemRequest:
          manager.communications.sendMessageToClient(
              type: FromEbsToClientMessages.newLetterProblemGenerated,
              data: (await manager.generateProblem(data)).serialize());
          break;

        case FromClientToEbsMessages.pardonStatusUpdate:
          manager.pardonStatusUpdate(data['pardonner_user_id']);
          break;

        case FromClientToEbsMessages.disconnect:
          manager.requestEndOfGame();
          break;
      }
    } on InvalidMessageException catch (e) {
      manager.communications.sendMessageToClient(type: e.message);
    } catch (e) {
      manager.communications.sendMessageToClient(
          type: FromEbsToClientMessages.unkownMessageException);
    }
  }

  ///
  /// Handle messages from the client and relay them to the game manager
  static Future<void> _handleMessageFromFrontend(
      message, GameManager manager) async {
    // Helper function to send a response to the frontend
    Future<void> sendReponseSubroutine(
        {required bool isSuccess,
        Map<String, dynamic>? data,
        Map<String, dynamic>? internalMain}) async {
      if (internalMain?['completer_id'] == null) return;
      manager.communications.sendMessageToManager(
          type: FromEbsToManagerMessages.responseInternal,
          data: {'status': isSuccess ? 'OK' : 'NOK', 'data': data},
          internalMain: internalMain);
    }

    _logger.info('Received message from client or frontend');

    // Parse and handle the message from the client. If the message is invalid,
    // it sends an error message back to the client
    try {
      final type = FromFrontendToEbsMessages.values[message['type'] as int];
      final data = message['data'];
      final internalMain = message['internal_main'];

      switch (type) {
        case FromFrontendToEbsMessages.registerToGame:
          final userId = data['user_id'];
          final opaqueId = data['opaque_id'];
          if (userId == null || opaqueId == null) {
            sendReponseSubroutine(isSuccess: false, internalMain: internalMain);
            return;
          }
          final isConnected =
              await manager.registerToGame(userId: userId, opaqueId: opaqueId);
          sendReponseSubroutine(
              isSuccess: isConnected, internalMain: internalMain);

        case FromFrontendToEbsMessages.pardonRequest:
          final userId = data['user_id'];

          final login = (await manager.communications.sendQuestionToManager(
              type: FromEbsToManagerMessages.getLogin,
              data: {'user_id': userId})) as String;

          manager.requestPardonStealer(login);

          sendReponseSubroutine(isSuccess: true, internalMain: internalMain);
          break;
      }
    } on InvalidMessageException catch (e) {
      manager.communications.sendMessageToClient(type: e.message);
    } catch (e) {
      manager.communications.sendMessageToClient(
          type: FromEbsToClientMessages.unkownMessageException);
    }
  }
}
