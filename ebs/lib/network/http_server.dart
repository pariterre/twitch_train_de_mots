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
      _sendErrorResponse(
          request,
          HttpStatus.forbidden,
          MessageProtocol(
              fromTo: FromEbsToGeneric.error,
              isSuccess: false,
              data: {'error_message': 'Connexion refused'}));
      continue;
    }

    _logger.info(
        'New request received from $ipAddress (${parameters.rateLimiter.requestCount(ipAddress) + 1} / ${parameters.rateLimiter.maxRequests})');

    if (parameters.rateLimiter.isRateLimited(ipAddress)) {
      _sendErrorResponse(
          request,
          HttpStatus.tooManyRequests,
          MessageProtocol(
              fromTo: FromEbsToGeneric.error,
              isSuccess: false,
              data: {'error_message': 'Rate limited'}));
      continue;
    }

    if (request.method == 'OPTIONS') {
      _gardedHandleRequest(request, _handleOptionsRequest);
    } else if (request.method == 'GET') {
      _gardedHandleRequest(request, _handleGetHttpRequest);
    } else if (request.method == 'POST') {
      _gardedHandleRequest(request, _handlPostHttpRequest);
    } else {
      _sendErrorResponse(
          request,
          HttpStatus.methodNotAllowed,
          MessageProtocol(
              fromTo: FromEbsToGeneric.error,
              isSuccess: false,
              data: {
                'error_message': 'Invalid request method: ${request.method}'
              }));
    }
  }
}

Future<void> _gardedHandleRequest(
    HttpRequest request, Function(HttpRequest) handler) async {
  try {
    await handler(request);
  } on InvalidEndpointException {
    _sendErrorResponse(
        request,
        HttpStatus.notFound,
        MessageProtocol(
            fromTo: FromEbsToGeneric.error,
            isSuccess: false,
            data: {'error_message': 'Invalid endpoint'}));
  } on UnauthorizedException {
    _sendErrorResponse(
        request,
        HttpStatus.unauthorized,
        MessageProtocol(
            fromTo: FromEbsToGeneric.error,
            isSuccess: false,
            data: {'error_message': 'Unauthorized'}));
  } on ConnexionToWebSocketdRefusedException {
    _sendErrorResponse(
        request,
        HttpStatus.serviceUnavailable,
        MessageProtocol(
            fromTo: FromEbsToGeneric.error,
            isSuccess: false,
            data: {'error_message': 'Connexion to WebSocketd refused'}));
  } catch (e) {
    _sendErrorResponse(
        request,
        HttpStatus.internalServerError,
        MessageProtocol(
            fromTo: FromEbsToGeneric.error,
            isSuccess: false,
            data: {'error_message': 'An error occurred: ${e.toString()}'}));
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
    await _handleFrontendHttpRequest(request);
  } else {
    throw InvalidEndpointException();
  }
}

Future<void> _handlPostHttpRequest(HttpRequest request) async {
  if (request.uri.path.contains('/frontend/')) {
    await _handleFrontendHttpRequest(request);
  } else {
    throw InvalidEndpointException();
  }
}

_sendSuccessResponse(HttpRequest request, MessageProtocol message) {
  _logger.info('Sending success response: ${message.data}');
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(message.encode())
    ..close();
}

_sendErrorResponse(
    HttpRequest request, int statusCode, MessageProtocol message) {
  _logger.severe('Sending error response: ${message.data}');
  request.response
    ..statusCode = statusCode
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(message.encode())
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