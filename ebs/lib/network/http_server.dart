import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/exceptions.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/isolated_games_manager.dart';
import 'package:train_de_mots_ebs/managers/twitch_manager_extension.dart';
import 'package:train_de_mots_ebs/network/network_parameters.dart';

part 'package:train_de_mots_ebs/network/handle_client_endpoints.dart';
part 'package:train_de_mots_ebs/network/handle_frontend_endpoints.dart';

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
  if (request.uri.path.contains('/client/')) {
    await _handleClientHttpGetRequest(request);
  } else if (request.uri.path.contains('/frontend/')) {
    await _handleFrontendGetHttpRequest(request);
  } else {
    throw InvalidEndpointException();
  }
}

Future<void> _handlPostHttpRequest(HttpRequest request) async {
  if (request.uri.path.contains('/frontend/')) {
    await _handleFrontendPostHttpRequest(request);
  } else {
    throw InvalidEndpointException();
  }
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
