part of 'package:train_de_mots_ebs/network/http_server.dart';

Future<void> _handleClientHttpGetRequest(HttpRequest request) async {
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
        'type': FromEbsToClientMessages.noBroadcasterIdException.index,
        'message': NoBroadcasterIdException().message,
      }));
      socket.close();
      return;
    }

    _logger.info('New client connexion (broadcasterId: $broadcasterId)');
    IsolatedGamesManager.instance.newClient(broadcasterId, socket: socket);

    // Establish a persistent communication with the client
    socket
        .listen((message) => IsolatedGamesManager.instance
            .messageFromClientToIsolated(
                MessageProtocol.decode(message), socket))
        .onDone(
          () => _handleConnexionToClientTerminated(broadcasterId, socket),
        );
  } catch (e) {
    throw ConnexionToWebSocketdRefusedException();
  }
}

Future<void> _handleConnexionToClientTerminated(
    int broadcasterId, WebSocket socket) async {
  IsolatedGamesManager.instance.messageFromClientToIsolated(
      MessageProtocol(
          fromTo: FromClientToEbsMessages.disconnect,
          data: {'broadcaster_id': broadcasterId}),
      socket);
}
