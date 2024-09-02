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

    final broadcasterIdString = request.uri.queryParameters['broadcasterId'];
    if (broadcasterIdString == null) {
      _logger.severe('No broadcasterId found');
      socket.add(json.encode({
        'type': FromEbsMessages.noBroadcasterIdException.index,
        'message': NoBroadcasterIdException().message,
      }));
      socket.close();
      return;
    }

    final broadcasterId = int.tryParse(broadcasterIdString);
    if (broadcasterId == null) {
      _logger.severe('Invalid broadcasterId');
      socket.add(json.encode({
        'type': FromEbsMessages.noBroadcasterIdException.index,
        'message': NoBroadcasterIdException().message,
      }));
      socket.close();
      return;
    }

    IsolatedGamesManager.instance
        .handleNewClientConnexion(broadcasterId, socket: socket);
  } catch (e) {
    throw ConnexionToWebSocketdRefusedException();
  }
}
