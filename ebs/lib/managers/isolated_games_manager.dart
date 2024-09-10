import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/exceptions.dart';
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
  SendPort? sendPortClient;
  SendPort? sendPortFrontend;

  void clear() {
    isolate.kill(priority: Isolate.immediate);
    sendPortMain = null;
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
    _handleMessageFromIsolated(
        MessageProtocol(
            fromTo: FromEbsToClientMessages.isConnected,
            target: MessageTargets.client),
        socket,
        data);
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
      MessageProtocol message, WebSocket socket, _IsolateData data) async {
    try {
      switch (message.target as MessageTargets) {
        case MessageTargets.main:
          await _handleMessageFromIsolatedToMain(message, data, socket);
          break;
        case MessageTargets.client:
          await _handleMessageFromIsolatedToClient(message, socket);
          break;
        case MessageTargets.frontend:
          await _handleMessageFromIsolatedToFrontend(message, socket);
          break;
      }
    } catch (e) {
      _logger.severe('Error while handling message from isolated: $e');
    }
  }

  Future<void> _handleMessageFromIsolatedToMain(MessageProtocol message,
      _IsolateData isolateData, WebSocket socket) async {
    final tm = TwitchManagerExtension.instance;

    switch (message.fromTo as FromEbsToMainMessages) {
      case FromEbsToMainMessages.initialize:
        final isolate = _isolates[isolateData.twitchBroadcasterId]!;

        isolate.sendPortMain = message.data!['send_port_main'];
        isolate.sendPortClient = message.data!['send_port_client'];
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

  Future<void> _handleMessageFromIsolatedToClient(
      MessageProtocol message, WebSocket socket) async {
    socket.add(message.encode());
  }

  Future<void> _handleMessageFromIsolatedToFrontend(
      MessageProtocol message, WebSocket socket) async {
    TwitchManagerExtension.instance.sendPubsubMessage(message.toJson());
  }

  Future<void> messageFromClientToIsolated(
      MessageProtocol message, WebSocket socket) async {
    final broadcasterId = message.data?['broadcaster_id'];

    final sendPortClient = _isolates[broadcasterId]?.sendPortClient;
    if (sendPortClient == null) {
      _logger.info('No active game with id: $broadcasterId');
      return;
    }

    // Relay the message to the worker isolate
    sendPortClient.send(message.encode());
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
    final receivePortClient = ReceivePort();
    final receivePortFrontend = ReceivePort();

    final gm = GameManager.clientStartedTheGame(
        broadcasterId: data.twitchBroadcasterId, sendPort: sendPort);

    // Send the SendPort to the main isolate, so it can communicate back to the isolate
    gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.main,
        fromTo: FromEbsToMainMessages.initialize,
        data: {
          'send_port_main': receivePortMain.sendPort,
          'send_port_client': receivePortClient.sendPort,
          'send_port_frontend': receivePortFrontend.sendPort
        }));

    // Handle the messages from the main, client or frontends
    receivePortMain.listen((message) async =>
        _handleMessageFromMain(MessageProtocol.decode(message), gm));
    receivePortClient.listen((message) async =>
        _handleMessageFromClient(MessageProtocol.decode(message), gm));
    receivePortFrontend.listen((message) async =>
        _handleMessageFromFrontend(MessageProtocol.decode(message), gm));
  }

  static Future<void> _handleMessageFromMain(
      MessageProtocol message, GameManager gm) async {
    _logger.info('Received message from main');

    // Parse and handle the message from the main. If the message is invalid,
    // it sends an error message back to the client
    final completerId = message.internalIsolate!['completer_id'];

    switch (message.fromTo as FromMainToEbsMessages) {
      case FromMainToEbsMessages.getUserId:
        gm.communications
            .complete(completerId: completerId, data: message.data!['user_id']);
        break;
      case FromMainToEbsMessages.getDisplayName:
        gm.communications.complete(
            completerId: completerId, data: message.data!['display_name']);
        break;
      case FromMainToEbsMessages.getLogin:
        gm.communications
            .complete(completerId: completerId, data: message.data!['login']);
        break;
    }
  }

  ///
  /// Handle messages from the client and relay them to the game manager
  static Future<void> _handleMessageFromClient(
      MessageProtocol message, GameManager gm) async {
    _logger.info('Received message from client or frontend');

    // Parse and handle the message from the client. If the message is invalid,
    // it sends an error message back to the client
    try {
      switch (message.fromTo as FromClientToEbsMessages) {
        case FromClientToEbsMessages.roundStarted:
          gm.clientStartedARound();
          break;

        case FromClientToEbsMessages.roundEnded:
          gm.clientEndedARound();
          break;

        case FromClientToEbsMessages.newLetterProblemRequest:
          gm.communications.sendMessageViaMain(MessageProtocol(
              target: MessageTargets.client,
              fromTo: FromEbsToClientMessages.newLetterProblemGenerated,
              data: (await gm.clientRequestedANewLetterProblem(message.data!))
                  .serialize()));
          break;

        case FromClientToEbsMessages.pardonStatusUpdate:
          gm.clientUpdatedPardonnersStatus(
              message.data?['pardonner_user_id'] ?? '');
          break;

        case FromClientToEbsMessages.pardonRequestStatus:
          gm.communications.complete(
              completerId: message.internalIsolate!['completer_id'],
              data: message.isSuccess);
          break;

        case FromClientToEbsMessages.pong:
          gm.communications.complete(
              completerId: message.internalIsolate!['completer_id'],
              data: message.data!);
          break;

        case FromClientToEbsMessages.disconnect:
          gm.clientEndedTheGame();
          break;
      }
    } on InvalidMessageException catch (e) {
      gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.client,
        fromTo: e.message,
      ));
      gm.communications.sendMessageViaMain(MessageProtocol(
        target: MessageTargets.client,
        fromTo: e.message,
      ));
    } catch (e) {
      gm.communications.sendMessageViaMain(MessageProtocol(
          target: MessageTargets.client,
          fromTo: FromEbsToClientMessages.unkownMessageException));
    }
  }

  ///
  /// Handle messages from the client and relay them to the game manager
  static Future<void> _handleMessageFromFrontend(
      MessageProtocol message, GameManager gm) async {
    // Helper function to send a response to the frontend
    Future<void> sendReponseSubroutine(MessageProtocol message) async {
      gm.communications.sendMessageViaMain(message.copyWith(
          target: MessageTargets.main,
          fromTo: FromEbsToMainMessages.responseInternal));
    }

    _logger.info('Received message from client or frontend');

    // Parse and handle the message from the client. If the message is invalid,
    // it sends an error message back to the client
    try {
      switch (message.fromTo as FromFrontendToEbsMessages) {
        case FromFrontendToEbsMessages.registerToGame:
          try {
            final userId = message.data!['user_id'];
            final opaqueId = message.data!['opaque_id'];
            if (userId == null || opaqueId == null) throw 'Not enough data';

            sendReponseSubroutine(
              message.copyWith(
                  isSuccess: await gm.frontendRegisteredToTheGame(
                      userId: userId, opaqueId: opaqueId)),
            );
          } catch (e) {
            sendReponseSubroutine(
              message.copyWith(isSuccess: false),
            );
          }

        case FromFrontendToEbsMessages.pardonRequest:
          try {
            final userId = message.data!['user_id'];
            if (userId == null) throw 'Not enough data';

            final login = (await gm.communications.sendQuestionToMain(
                MessageProtocol(
                    target: MessageTargets.main,
                    fromTo: FromEbsToMainMessages.getLogin,
                    data: {'user_id': userId}))) as String?;
            if (login == null) throw 'Could not get login';

            sendReponseSubroutine(message.copyWith(
                isSuccess: await gm.frontendRequestedToPardon(login)));
          } catch (e) {
            sendReponseSubroutine(message.copyWith(isSuccess: false));
          }
          break;
      }
    } on InvalidMessageException catch (e) {
      sendReponseSubroutine(MessageProtocol(fromTo: e.message));
    } catch (e) {
      sendReponseSubroutine(MessageProtocol(
          fromTo: FromEbsToClientMessages.unkownMessageException));
    }
  }
}
