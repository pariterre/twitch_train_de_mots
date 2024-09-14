import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/exceptions.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/game_manager.dart';
import 'package:train_de_mots_ebs/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_ebs/models/completers.dart';

final _logger = Logger('IsolatedGameManagers');

class _IsolateData {
  final int twitchBroadcasterId;
  final SendPort mainSendPort;

  _IsolateData({required this.twitchBroadcasterId, required this.mainSendPort});
}

class _IsolateInterface {
  final Isolate isolate;
  SendPort? sendPortMain;
  SendPort? sendPortApp;
  SendPort? sendPortFrontend;

  void clear() {
    isolate.kill(priority: Isolate.immediate);
    sendPortMain = null;
    sendPortApp = null;
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
  /// Returns if a new game was indeed created. If false, it means we should not
  /// listen to the websocket anymore as it is already connected to a game.
  Future<void> newStreamer(int broadcasterId,
      {required WebSocket socket}) async {
    final mainReceivePort = ReceivePort();
    final data = _IsolateData(
        twitchBroadcasterId: broadcasterId,
        mainSendPort: mainReceivePort.sendPort);

    // Create a new game
    if (!_isolates.containsKey(broadcasterId)) {
      _logger.info('Starting a new connexion (broadcasterId: $broadcasterId)');
      _isolates[broadcasterId] = _IsolateInterface(
          isolate:
              await Isolate.spawn(_IsolatedGame.startNewGameManager, data));
    }

    // Establish communication with the worker isolate
    mainReceivePort
        .listen((message) => _handleMessageFromIsolated(message, socket, data));

    // Emulate an is connected message to send to the App
    _handleMessageFromIsolated(
        MessageProtocol(
            fromTo: FromEbsToAppMessages.isConnected,
            target: MessageTargets.app),
        socket,
        data);
  }

  ///
  /// Stop all games
  void killAllIsolates() {
    for (var interface in _isolates.values) {
      interface.clear();
    }
    _isolates.clear();
  }

  Future<void> _handleMessageFromIsolated(
      MessageProtocol message, WebSocket socket, _IsolateData data) async {
    try {
      switch (message.target as MessageTargets) {
        case MessageTargets.main:
          await _handleMessageFromIsolatedToMain(message, data);
          break;
        case MessageTargets.app:
          await _handleMessageFromIsolatedToApp(message, socket);
          break;
        case MessageTargets.frontend:
          await _handleMessageFromIsolatedToFrontend(message, socket);
          break;
      }
    } catch (e) {
      _logger.severe('Error while handling message from isolated: $e');
    }
  }

  Future<void> _handleMessageFromIsolatedToMain(
      MessageProtocol message, _IsolateData isolateData) async {
    final tm = TwitchManagerExtension.instance;

    switch (message.fromTo as FromEbsToMainMessages) {
      case FromEbsToMainMessages.initialize:
        final isolate = _isolates[isolateData.twitchBroadcasterId]!;

        isolate.sendPortMain = message.data!['send_port_main'];
        isolate.sendPortApp = message.data!['send_port_app'];
        isolate.sendPortFrontend = message.data!['send_port_frontend'];
        break;

      case FromEbsToMainMessages.responseInternal:
        final completerId = message.internalIsolate!['completer_id'] as int;
        _completers.complete(completerId, message);
        break;

      case FromEbsToMainMessages.getUserId:
        final response = <String, dynamic>{};
        try {
          response['user_id'] = await tm.userId(login: message.data!['login']);
        } catch (e) {
          response['user_id'] = null;
        }
        messageFromMainToIsolated(
            broadcasterId: isolateData.twitchBroadcasterId,
            message: message.copyWith(data: response));
        break;

      case FromEbsToMainMessages.getDisplayName:
        final response = <String, dynamic>{};
        try {
          response['display_name'] =
              await tm.displayName(userId: message.data!['user_id']);
        } catch (e) {
          response['display_name'] = null;
        }
        messageFromMainToIsolated(
            broadcasterId: isolateData.twitchBroadcasterId,
            message: message.copyWith(data: response));
        break;

      case FromEbsToMainMessages.getLogin:
        final response = <String, dynamic>{};
        try {
          response['login'] = await tm.login(userId: message.data!['user_id']);
        } catch (e) {
          response['login'] = null;
        }
        messageFromMainToIsolated(
            broadcasterId: isolateData.twitchBroadcasterId,
            message: message.copyWith(
                fromTo: FromMainToEbsMessages.getLogin, data: response));
        break;

      case FromEbsToMainMessages.canDestroyIsolated:
        _isolates.remove(isolateData.twitchBroadcasterId)?.clear();
        break;
    }
  }

  Future<void> _handleMessageFromIsolatedToApp(
      MessageProtocol message, WebSocket socket) async {
    socket.add(message.encode());
  }

  Future<void> _handleMessageFromIsolatedToFrontend(
      MessageProtocol message, WebSocket socket) async {
    TwitchManagerExtension.instance.sendPubsubMessage(message.toJson());
  }

  Future<void> messageFromAppToIsolated(
      MessageProtocol message, WebSocket socket) async {
    final broadcasterId = message.data?['broadcaster_id'];

    final sendPortApp = _isolates[broadcasterId]?.sendPortApp;
    if (sendPortApp == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    // Relay the message to the worker isolate
    sendPortApp.send(message.encode());
  }

  Future<MessageProtocol> messageFromFrontendToIsolated(
      {required MessageProtocol message}) async {
    final broadcasterId = message.data?['broadcaster_id'];

    final sendPortFrontend = _isolates[broadcasterId]?.sendPortFrontend;
    if (sendPortFrontend == null) {
      _logger.info('No active game with id: $broadcasterId');
      return MessageProtocol(
          fromTo: FromEbsToGeneric.response,
          isSuccess: false,
          data: {'error_message': 'No active game with id: $broadcasterId'});
    }

    // Relay the message to the worker isolate
    final completerId = _completers.spawn();
    sendPortFrontend.send(message
        .copyWith(internalIsolate: {'completer_id': completerId}).encode());

    return await _completers.get(completerId)!.future;
  }

  Future<void> messageFromMainToIsolated({
    required int broadcasterId,
    required MessageProtocol message,
  }) async {
    final sendPortMain = _isolates[broadcasterId]?.sendPortMain;
    if (sendPortMain == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    sendPortMain.send(message.encode());
  }
}

class _IsolatedGame {
  ///
  /// Start a new game manager, this is the entry point for the worker isolate
  static void startNewGameManager(_IsolateData data) async {
    final sendPort = data.mainSendPort;

    final receivePortMain = ReceivePort();
    final receivePortApp = ReceivePort();
    final receivePortFrontend = ReceivePort();

    final gm = GameManager.appStartedTheGame(
        broadcasterId: data.twitchBroadcasterId, sendPort: sendPort);

    // Send the SendPort to the main isolate, so it can communicate back to the isolate
    gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.main,
        fromTo: FromEbsToMainMessages.initialize,
        data: {
          'send_port_main': receivePortMain.sendPort,
          'send_port_app': receivePortApp.sendPort,
          'send_port_frontend': receivePortFrontend.sendPort
        }));

    // Handle the messages from the main, app or frontends
    receivePortMain.listen((message) async =>
        _handleMessageFromMain(MessageProtocol.decode(message), gm));
    receivePortApp.listen((message) async =>
        _handleMessageFromApp(MessageProtocol.decode(message), gm));
    receivePortFrontend.listen((message) async =>
        _handleMessageFromFrontend(MessageProtocol.decode(message), gm));
  }

  static Future<void> _handleMessageFromMain(
      MessageProtocol message, GameManager gm) async {
    // Parse and handle the message from the main. If the message is invalid,
    // it sends an error message back to the App
    final completerId = message.internalIsolate!['completer_id'];

    switch (message.fromTo as FromMainToEbsMessages) {
      case FromMainToEbsMessages.getUserId:
        _logger.info(
            'Main sent back the user id (broadcastId: ${gm.broadcasterId})');
        gm.communications
            .complete(completerId: completerId, data: message.data!['user_id']);
        break;
      case FromMainToEbsMessages.getDisplayName:
        _logger.info(
            'Main sent back the display name (broadcastId: ${gm.broadcasterId})');
        gm.communications.complete(
            completerId: completerId, data: message.data!['display_name']);
        break;
      case FromMainToEbsMessages.getLogin:
        _logger.info(
            'Main sent back the login (broadcastId: ${gm.broadcasterId})');
        gm.communications
            .complete(completerId: completerId, data: message.data!['login']);
        break;
    }
  }

  ///
  /// Handle messages from the App and relay them to the game manager
  static Future<void> _handleMessageFromApp(
      MessageProtocol message, GameManager gm) async {
    // Parse and handle the message from the App. If the message is invalid,
    // it sends an error message back to the App
    try {
      switch (message.fromTo as FromAppToEbsMessages) {
        case FromAppToEbsMessages.updateGameState:
          await gm.appUpdatedGameState(
              SimplifiedGameState.deserialize(message.data!['game_state']));
          break;

        case FromAppToEbsMessages.newLetterProblemRequest:
          gm.communications.sendMessageViaMain(MessageProtocol(
              target: MessageTargets.app,
              fromTo: FromEbsToAppMessages.newLetterProblemGenerated,
              data: (await gm.appRequestedANewLetterProblem(message.data!))
                  .serialize()));
          break;

        case FromAppToEbsMessages.pardonRequestResponse:
          _logger.info('App answered request pardon status');
          gm.communications.complete(
              completerId: message.internalIsolate!['completer_id'],
              data: message.isSuccess);
          break;

        case FromAppToEbsMessages.boostRequestResponse:
          _logger.info('App answered request boost status');
          gm.communications.complete(
              completerId: message.internalIsolate!['completer_id'],
              data: message.isSuccess);
          break;

        case FromAppToEbsMessages.pong:
          gm.communications.complete(
              completerId: message.internalIsolate!['completer_id'],
              data: message.data!);
          break;

        case FromAppToEbsMessages.disconnect:
          _logger.info('Streamer has ended the game');
          gm.appEndedTheGame();
          break;
      }
    } on InvalidMessageException catch (e) {
      gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.app,
        fromTo: e.message,
      ));
      gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.app,
        fromTo: e.message,
      ));
    } catch (e) {
      gm.communications.sendMessageViaMain(MessageProtocol(
          target: MessageTargets.app,
          fromTo: FromEbsToAppMessages.unkownMessageException));
    }
  }

  ///
  /// Handle messages from the App and relay them to the game manager
  static Future<void> _handleMessageFromFrontend(
      MessageProtocol message, GameManager gm) async {
    // Helper function to send a response to the frontend
    Future<void> sendInternalReponseSubroutine(MessageProtocol message) async {
      gm.communications.sendMessageViaMain(message.copyWith(
          target: MessageTargets.main,
          fromTo: FromEbsToMainMessages.responseInternal));
    }

    Future<void> sendErrorInternalReponseSubroutine(
        FromEbsToGeneric error) async {
      gm.communications
          .sendMessageViaMain(MessageProtocol(fromTo: error, isSuccess: false));
    }

    try {
      late final int userId;
      try {
        userId = message.data!['user_id']!;
      } catch (e) {
        sendErrorInternalReponseSubroutine(FromEbsToGeneric.unauthorizedError);
        return;
      }

      late final String opaqueId;
      try {
        opaqueId = message.data!['opaque_id']!;
      } catch (e) {
        sendErrorInternalReponseSubroutine(FromEbsToGeneric.invalidEndpoint);
        return;
      }

      late final FromFrontendToEbsMessages fromTo;
      try {
        fromTo = message.fromTo as FromFrontendToEbsMessages;
      } catch (e) {
        sendErrorInternalReponseSubroutine(FromEbsToGeneric.unknownError);
        return;
      }

      late final bool isSuccess;
      switch (fromTo) {
        case FromFrontendToEbsMessages.registerToGame:
          _logger.info('Frontend (userId: $userId) registered to the game');

          isSuccess = await gm.frontendRegisteredToTheGame(
              userId: userId, opaqueId: opaqueId);
          break;
        case FromFrontendToEbsMessages.requestGameState:
          _logger.info('Frontend (userId: $userId) requested the game state');
          final gameState = gm.gameState.serialize();
          message.copyWith(data: {'game_state': gameState});
          isSuccess = true;
          break;
        case FromFrontendToEbsMessages.pardonRequest:
          _logger.info('Frontend (userId: $userId) requested to pardon');
          isSuccess = await gm.frontendRequestedToPardon(userId);
          break;
        case FromFrontendToEbsMessages.boostRequest:
          _logger.info('Frontend (userId: $userId) requested to boost');
          isSuccess = await gm.frontendRequestedToBoost(userId);
          break;
      }
      sendInternalReponseSubroutine(message.copyWith(isSuccess: isSuccess));
    } catch (e) {
      sendInternalReponseSubroutine(
          MessageProtocol(fromTo: FromEbsToAppMessages.unkownMessageException));
    }
  }
}
