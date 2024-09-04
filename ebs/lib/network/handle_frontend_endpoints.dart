part of 'package:train_de_mots_ebs/network/http_server.dart';

Future<void> _handleFrontendGetHttpRequest(HttpRequest request) async {
  _logger.info('Answering GET request to ${request.uri.path}');

  final requestEndpoint = FrontendHttpGetEndpoints.fromString(request.uri.path);

  // Verify that the user is authorized to access the endpoint. If not, an
  // exception is thrown
  _extractJwtPayload(request);

  switch (requestEndpoint) {
    case FrontendHttpGetEndpoints.initialize:
      _sendSuccessResponse(request, {'authorized': true});
      break;
  }
}

Future<void> _handleFrontendPostHttpRequest(HttpRequest request) async {
  _logger.info('Answering POST request to ${request.uri.path}');
  final requestEndpoint =
      FrontendHttpPostEndpoints.fromString(request.uri.path);

  // Extract the payload from the JWT, if it succeeds, the user is authorized,
  // otherwise an exception is thrown
  final payload = _extractJwtPayload(request);

  switch (requestEndpoint) {
    case FrontendHttpPostEndpoints.pardon:
      final broadcasterId = int.parse(payload?['channel_id']);
      final userId = int.parse(payload?['user_id']);
      // Get the message of the POST request
      IsolatedGamesManager.instance.messageFromFrontendToIsolated(
          broadcasterId: broadcasterId,
          type: FromFrontendToEbsMessages.pardonRequest,
          data: {'user_id': userId});

      _sendSuccessResponse(request, {'response': 'OK'});
      break;

    case FrontendHttpPostEndpoints.dummyRequest:
      /* final message = */ jsonDecode(await utf8.decoder.bind(request).join());
      break;
  }
}

Map<String, dynamic>? _extractJwtPayload(HttpRequest request) {
  // Extract the Authorization header
  final authHeader = request.headers['Authorization']?.first;
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    throw UnauthorizedException();
  }
// Extract the Bearer token by removing 'Bearer ' from the start
  final bearer = authHeader.substring(7);
  // If the token is invalid, an exception is thrown
  final decodedJwt = TwitchManagerExtension.instance.verifyAndDecode(bearer);

  return decodedJwt.payload;
}
