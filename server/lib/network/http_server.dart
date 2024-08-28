import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/common.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_server/managers/isolated_games_manager.dart';
import 'package:train_de_mots_server/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_server/models/exceptions.dart';
import 'package:train_de_mots_server/models/letter_problem.dart';
import 'package:train_de_mots_server/network/network_parameters.dart';

final _logger = Logger('http_server');

void startHttpServer({required NetworkParameters parameters}) async {
  final httpServer = await _startServer(parameters);

  await for (final request in httpServer) {
    final ipAddress = request.connectionInfo?.remoteAddress.address;
    if (ipAddress == null) {
      _logger.severe('No IP address found');
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write('Connexion refused')
        ..close();
      continue;
    }

    _logger.info(
        'New request received from $ipAddress (${parameters.rateLimiter.requestCount(ipAddress) + 1} / ${parameters.rateLimiter.maxRequests})');

    if (parameters.rateLimiter.isRateLimited(ipAddress)) {
      _logger.severe('Rate limited');
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write('Rate limited')
        ..close();
      continue;
    }

    if (request.method == 'OPTIONS') {
      try {
        _handleOptionsRequest(request);
      } catch (e) {
        // Do nothing
      }
    } else if (request.method == 'GET') {
      _handleGetHttpRequest(request);
    } else {
      _handleConnexionRefused(request);
    }
  }
}

///
/// Handle OPTIONS request for CORS preflight
void _handleOptionsRequest(HttpRequest request) {
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..headers.add('Access-Control-Allow-Headers', 'Authorization, Content-Type')
    ..close();
}

Future<void> _handleGetHttpRequest(HttpRequest request) async {
  if (request.uri.path == '/getProblem') {
    try {
      _handleGetNewLetterProblemHttpRequest(request);
    } catch (e) {
      _logger.severe(e);
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(e)
        ..close();
    }
  } else if (request.uri.path == '/startGame') {
    _handleWebSocketRequest(request);
  } else if (request.uri.path.contains('/frontend/')) {
    try {
      _handleFrontend(request);
    } catch (e) {
      _logger.severe('Token verification failed');
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(json.encode({'Error': 'Unauthorized'}))
        ..close();
      return;
    }
  } else {
    _handleConnexionRefused(request);
  }
}

/// Handle GET request for a new problem
/// The request must contain the following parameters:
/// - algorithm: the algorithm to generate the problem
/// - timeout: the timeout for the problem
/// - configuration: the configuration of the problem
void _handleGetNewLetterProblemHttpRequest(HttpRequest request) {
  // TODO Remove all this http stuff when actual server is implemented
  final problem =
      LetterProblem.generateProblemFromRequest(request.uri.queryParameters);

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(json.encode(problem.serialize()))
    ..close();
}

Future<void> _handleWebSocketRequest(HttpRequest request) async {
  _logger.info('Websocket connexion requested');
  final socket = await WebSocketTransformer.upgrade(request);

  _logger.info('Client connected');
  final broadcasterIdString = request.uri.queryParameters['broadcasterId'];
  if (broadcasterIdString == null) {
    _logger.severe('No broadcasterId found');
    socket.add(json.encode({
      'type': GameServerToClientMessages.NoBroadcasterIdException.index,
      'message': NoBroadcasterIdException().message,
    }));
    socket.close();
    return;
  }

  final broadcasterId = int.tryParse(broadcasterIdString);
  if (broadcasterId == null) {
    _logger.severe('Invalid broadcasterId');
    socket.add(json.encode({
      'type': GameServerToClientMessages.NoBroadcasterIdException.index,
      'message': NoBroadcasterIdException().message,
    }));
    socket.close();
    return;
  }

  IsolatedGamesManager.instance
      .handleNewClientConnexion(broadcasterId, socket: socket);
}

void _handleFrontend(HttpRequest request) {
  _logger.info('Received data request');

  // Extract the payload from the JWT, if it succeeds, the user is authorized,
  // otherwise an exception is thrown
  final payload = _extractJwtPayload(request);

  if (request.uri.path.contains('/initialize')) {
    // Do nothing more
  }

  // Send that the user is authorized
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
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

/// Handle connexion refused
void _handleConnexionRefused(HttpRequest request) {
  _logger.severe('Connexion refused');
  request.response
    ..statusCode = HttpStatus.forbidden
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write('Connexion refused')
    ..close();
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
