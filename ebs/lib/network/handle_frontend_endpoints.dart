part of 'package:train_de_mots_ebs/network/http_server.dart';

Future<void> _handleFrontendHttpRequest(HttpRequest request) async {
  _logger.info('Answering GET request to ${request.uri.path}');

  final requestEndpoint =
      FromFrontendToEbsMessages.fromString(request.uri.path);

  // Extract the payload from the JWT, if it succeeds, the user is authorized,
  // otherwise an exception is thrown
  final payload = _extractJwtPayload(request);

  final broadcasterId = int.parse(payload?['channel_id']);
  final userId = int.tryParse(payload?['user_id']);
  final opaqueUserId = payload?['opaque_user_id'];

  switch (requestEndpoint) {
    case FromFrontendToEbsMessages.registerToGame:
      // Get the message of the POST request
      final response = await IsolatedGamesManager.instance
          .messageFromFrontendToIsolated(
              broadcasterId: broadcasterId,
              type: FromFrontendToEbsMessages.registerToGame,
              data: {'user_id': userId, 'opaque_id': opaqueUserId});

      if (response['status'] != 'OK') {
        _sendErrorResponse(
            request, HttpStatus.unauthorized, 'Could not register to game');
        return;
      }
      _sendSuccessResponse(request, response);
      break;

    case FromFrontendToEbsMessages.pardonRequest:
      // Get the message of the POST request
      final response = await IsolatedGamesManager.instance
          .messageFromFrontendToIsolated(
              broadcasterId: broadcasterId,
              type: FromFrontendToEbsMessages.pardonRequest,
              data: {'user_id': userId});

      if (response['status'] != 'OK') {
        _sendErrorResponse(
            request, HttpStatus.unauthorized, 'Could not pardon the stealer');
        return;
      }
      _sendSuccessResponse(request, response);
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
