part of 'package:train_de_mots_ebs/network/http_server.dart';

Future<void> _handleFrontendHttpRequest(HttpRequest request) async {
  _logger.info('Answering GET request to ${request.uri.path}');

  // Extract the payload from the JWT, if it succeeds, the user is authorized,
  // otherwise an exception is thrown
  final payload = _extractJwtPayload(request);

  final broadcasterId = int.parse(payload?['channel_id']);
  final userId = int.tryParse(payload?['user_id']);
  final opaqueUserId = payload?['opaque_user_id'];

  // Get the message of the POST request
  final response = await IsolatedGamesManager.instance
      .messageFromFrontendToIsolated(
          message: MessageProtocol(
              fromTo: FromFrontendToEbsMessages.fromString(request.uri.path),
              data: {
        'broadcaster_id': broadcasterId,
        'user_id': userId,
        'opaque_id': opaqueUserId
      }));

  final isSuccess = response.isSuccess ?? false;
  if (!isSuccess) {
    try {
      switch (response.data!['error'] as FromEbsToGeneric) {
        case FromEbsToGeneric.unauthorizedError:
          throw UnauthorizedException();
        case FromEbsToGeneric.invalidEndpoint:
          throw InvalidEndpointException();
        case FromEbsToGeneric.unknownError:
        case FromEbsToGeneric.response:
          throw Exception();
      }
    } catch (e) {
      throw Exception();
    }
  }

  _sendSuccessResponse(request, response);
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
