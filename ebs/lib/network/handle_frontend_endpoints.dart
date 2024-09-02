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

    default:
      throw InvalidEndpointException();
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
      payload!['user_id']; // Check that user_id is present in the payload
      // Get the message of the POST request
      final message = jsonDecode(await utf8.decoder.bind(request).join());
      // TODO Relay the pardon to GameManager and send back the response from it

      if (message['message'] != 'Pardon my stealer') {
        // TODO Remove this, as it is for testing purposes only
        throw Exception('Invalid message');
      }
      _sendSuccessResponse(request, {'response': 'OK'});
      break;

    default:
      throw InvalidEndpointException();
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
