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
    _logger.info('New client connexion');
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

    IsolatedGamesManager.instance.newClient(broadcasterId, socket: socket);

    // Establish a persistent communication with the client
    socket.listen((message) => IsolatedGamesManager.instance
        .messageFromClientToIsolated(message, socket));
  } catch (e) {
    throw ConnexionToWebSocketdRefusedException();
  }
}
