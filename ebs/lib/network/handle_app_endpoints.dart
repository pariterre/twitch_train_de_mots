part of 'package:train_de_mots_ebs/network/http_server.dart';

Future<void> _handleAppHttpGetRequest(HttpRequest request) async {
  if (request.uri.path.contains('/connect')) {
    _handleConnectToWebSocketRequest(request);
  } else {
    throw InvalidEndpointException();
  }
}

Future<void> _handleConnectToWebSocketRequest(HttpRequest request) async {
  try {
    final socket = await WebSocketTransformer.upgrade(request);

    final broadcasterId =
        int.tryParse(request.uri.queryParameters['broadcasterId'] ?? '');
    if (broadcasterId == null) {
      _logger.severe('No broadcasterId found');
      socket.add(json.encode({
        'type': FromEbsToAppMessages.noBroadcasterIdException.index,
        'message': NoBroadcasterIdException().message,
      }));
      socket.close();
      return;
    }

    _logger.info('New App connexion (broadcasterId: $broadcasterId)');
    IsolatedGamesManager.instance.newStreamer(broadcasterId, socket: socket);

    // Establish a persistent communication with the App
    socket
        .listen((message) => IsolatedGamesManager.instance
            .messageFromAppToIsolated(MessageProtocol.decode(message), socket))
        .onDone(
          () => _handleConnexionToAppTerminated(broadcasterId, socket),
        );
  } catch (e) {
    throw ConnexionToWebSocketdRefusedException();
  }
}

Future<void> _handleConnexionToAppTerminated(
    int broadcasterId, WebSocket socket) async {
  IsolatedGamesManager.instance.messageFromAppToIsolated(
      MessageProtocol(
          fromTo: FromAppToEbsMessages.disconnect,
          data: {'broadcaster_id': broadcasterId}),
      socket);
}
