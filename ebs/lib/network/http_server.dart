import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/models/ebs_messages.dart';
import 'package:common/models/exceptions.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/isolated_games_manager.dart';
import 'package:train_de_mots_ebs/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_ebs/models/exceptions.dart';
import 'package:train_de_mots_ebs/models/letter_problem.dart';
import 'package:train_de_mots_ebs/network/network_parameters.dart';

final _logger = Logger('http_server');

void startHttpServer({required NetworkParameters parameters}) async {
  final httpServer = await _startServer(parameters);

  await for (final request in httpServer) {
    final ipAddress = request.connectionInfo?.remoteAddress.address;
    if (ipAddress == null) {
      _sendErrorResponse(request, HttpStatus.forbidden, 'Connexion refused');
      continue;
    }

    _logger.info(
        'New request received from $ipAddress (${parameters.rateLimiter.requestCount(ipAddress) + 1} / ${parameters.rateLimiter.maxRequests})');

    if (parameters.rateLimiter.isRateLimited(ipAddress)) {
      _sendErrorResponse(request, HttpStatus.tooManyRequests, 'Rate limited');
      continue;
    }

    try {
      if (request.method == 'OPTIONS') {
        await _handleOptionsRequest(request);
      } else if (request.method == 'GET') {
        await _handleGetHttpRequest(request);
      } else if (request.method == 'POST') {
        await _handlPostHttpRequest(request);
      } else {
        _sendErrorResponse(request, HttpStatus.methodNotAllowed,
            'Invalid request method: ${request.method}');
      }
    } on InvalidEndpointException {
      _sendErrorResponse(request, HttpStatus.notFound, 'Invalid endpoint');
    } on UnauthorizedException {
      _sendErrorResponse(request, HttpStatus.unauthorized, 'Unauthorized');
    } on ConnexionToWebSocketdRefusedException {
      _sendErrorResponse(request, HttpStatus.serviceUnavailable,
          'Connexion to WebSocketd refused');
    } catch (e) {
      _sendErrorResponse(request, HttpStatus.internalServerError,
          'An error occurred: ${e.toString()}');
    }
  }
}

///
/// Handle OPTIONS request for CORS preflight
Future<void> _handleOptionsRequest(HttpRequest request) async {
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..headers.add('Access-Control-Allow-Headers', 'Authorization, Content-Type')
    ..close();
}

Future<void> _handleGetHttpRequest(HttpRequest request) async {
  if (request.uri.path == '/getproblem') {
    // TODO As soon as EBS is communicating with client, remove this
    try {
      final problem =
          LetterProblem.generateProblemFromRequest(request.uri.queryParameters);

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(json.encode(problem.serialize()))
        ..close();
    } catch (e) {
      _logger.severe(e);
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(e)
        ..close();
    }
  }

  if (request.uri.path.contains('/client/')) {
    if (request.uri.path.contains('/connect')) {
      _handleConnectToWebSocketRequest(request);
    } else {
      throw InvalidEndpointException();
    }
  } else if (request.uri.path.contains('/frontend/')) {
    _handleFrontend(request);
  } else {
    throw InvalidEndpointException();
  }
}

Future<void> _handlPostHttpRequest(HttpRequest request) async {
  if (request.uri.path.contains('/frontend/')) {
    _handleFrontend(request);
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

Future<void> _handleFrontend(HttpRequest request) async {
  _logger.info('Received data request');

  // Extract the payload from the JWT, if it succeeds, the user is authorized,
  // otherwise an exception is thrown
  final payload = _extractJwtPayload(request);

  late final Map<String, dynamic> answer;
  if (request.uri.path.contains('/initialize')) {
    answer = {'authorized': true};
  } else if (request.uri.path.contains('/pong')) {
    answer = {'message': 'OK'};
  } else if (request.uri.path.contains('/pardon')) {
    payload!['user_id']; // Check that user_id is present in the payload
    // Get the message of the POST request
    final message = jsonDecode(await utf8.decoder.bind(request).join());
    // TODO Relay the pardon to GameManager and send back the response from it

    if (message['message'] != 'Pardon my stealer') {
      // TODO Remove this, as it is for testing purposes only
      throw Exception('Invalid message');
    }
    answer = {'response': 'OK'};
  } else {
    throw InvalidEndpointException();
  }

  // Send that the user is authorized
  _sendSuccessResponse(request, answer);
}

_sendSuccessResponse(HttpRequest request, Map<String, dynamic> data) {
  _logger.info('Sending success response: $data');
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(json.encode(data))
    ..close();
}

_sendErrorResponse(HttpRequest request, int statusCode, String message) {
  _logger.severe('Sending error response: $message');
  request.response
    ..statusCode = statusCode
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(message)
    ..close();
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

Future<HttpServer> _startServer(NetworkParameters parameters) async {
  _logger.info(
      'Server starting on ${parameters.host}:${parameters.port}, ${parameters.usingSecure ? '' : 'not '}using SSL');

  return parameters.usingSecure
      ? await HttpServer.bindSecure(
          parameters.host,
          parameters.port,
          SecurityContext()
            ..useCertificateChain(parameters.certificatePath!)
            ..usePrivateKey(parameters.privateKeyPath!))
      : await HttpServer.bind(parameters.host, parameters.port);
}
