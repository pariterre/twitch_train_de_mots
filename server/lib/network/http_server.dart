import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/common.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_server/models/letter_problem.dart';
import 'package:train_de_mots_server/models/problem_configuration.dart';
import 'package:train_de_mots_server/models/range.dart';
import 'package:train_de_mots_server/network/network_parameters.dart';

final _logging = Logger('http_server');

void startHttpServer({required NetworkParameters parameters}) async {
  final httpServer = await _startServer(parameters);

  await for (final request in httpServer) {
    final ipAddress = request.connectionInfo?.remoteAddress.address;
    if (ipAddress == null) {
      _logging.severe('No IP address found');
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write('Connexion refused')
        ..close();
      continue;
    }

    _logging.info(
        'New request received from $ipAddress (${parameters.rateLimiter.requestCount(ipAddress) + 1} / ${parameters.rateLimiter.maxRequests})');

    if (parameters.rateLimiter.isRateLimited(ipAddress)) {
      _logging.severe('Rate limited');
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write('Rate limited')
        ..close();
      continue;
    }

    if (request.method == 'OPTIONS') {
      _handleOptionsRequest(request);
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
    ..headers.add('Access-Control-Allow-Headers', 'Content-Type')
    ..close();
}

/// Handle connexion refused
void _handleConnexionRefused(HttpRequest request) {
  _logging.severe('Connexion refused');
  request.response
    ..statusCode = HttpStatus.forbidden
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write('Connexion refused')
    ..close();
}

Future<void> _handleWebSocketRequest(HttpRequest request) async {
  _logging.info('Websocket connexion requested');
  final socket = await WebSocketTransformer.upgrade(request);

  _logging.info('Client connected');

  socket.listen(
    (message) {
      try {
        _onMessageFromClientReceived(socket, message: message);
      } on InvalidMessageException catch (e) {
        _sendMessageToClient(socket, type: e.message);
      } catch (e) {
        _sendMessageToClient(socket,
            type: GameServerToClientMessages.UnkownMessageException);
      }
    },
    onDone: () => _logging.info('WebSocket connection closed'),
    onError: (error) => _logging.severe('WebSocket error: $error'),
  );
}

void _onMessageFromClientReceived(WebSocket socket, {required message}) {
  _logging.info('Message received from client');

  final data = json.decode(message);
  // TODO Validate bearer token

  final type = GameClientToServerMessages.values[data['type'] as int];
  switch (type) {
    case GameClientToServerMessages.newLetterProblemRequest:
      _handleGetNewLetterProblemWebSocket(socket, request: data['data']);
      break;
    default:
      _logging.severe('Unknown message type');
  }
}

void _handleGetNewLetterProblemWebSocket(WebSocket socket, {required request}) {
  final problem = _generateProblemFromRequest(request);
  _sendMessageToClient(socket,
      type: GameServerToClientMessages.newLetterProblemGenerated,
      data: problem.serialize());
}

void _handleGetHttpRequest(HttpRequest request) {
  if (request.uri.path == '/getproblem') {
    try {
      _handleGetNewLetterProblemHttpRequest(request);
    } catch (e) {
      _logging.severe(e);
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(e)
        ..close();
    }
  } else if (request.uri.path == '/wss') {
    _handleWebSocketRequest(request);
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
  final problem = _generateProblemFromRequest(request.uri.queryParameters);

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(json.encode(problem.serialize()))
    ..close();
}

LetterProblem _generateProblemFromRequest(request) {
  final algorithm = _parseAlgorithm(request['algorithm']!);
  final timeout = _parseTimeout(request['timeout']);
  final config = _parseProblemConfiguration(
    lengthShortestSolutionMin: request['lengthShortestSolutionMin'],
    lengthShortestSolutionMax: request['lengthShortestSolutionMax'],
    lengthLongestSolutionMin: request['lengthLongestSolutionMin'],
    lengthLongestSolutionMax: request['lengthLongestSolutionMax'],
    nbSolutionsMin: request['nbSolutionsMin'],
    nbSolutionsMax: request['nbSolutionsMax'],
    nbUselessLetters: request['nbUselessLetters'],
  );

  _logging.info(
    'Generating new word\n'
    'Configuration:\n'
    '\talgorithm: ${request['algorithm']}\n'
    '\tlengthShortestSolution: ${config.lengthShortestSolution.min} - ${config.lengthShortestSolution.max}\n'
    '\tlengthLongestSolution: ${config.lengthLongestSolution.min} - ${config.lengthLongestSolution.max}\n'
    '\tnbSolutions: ${config.nbSolutions.min} - ${config.nbSolutions.max}\n'
    '\tnbUselessLetters: ${config.nbUselessLetters}\n'
    '\tTimeout: ${timeout.inSeconds} seconds',
  );

  final problem = algorithm(config, timeout: timeout);
  _logging.info('Problem generated (${problem.letters.join()})');
  return problem;
}

Future<HttpServer> _startServer(NetworkParameters parameters) async {
  _logging.info(
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

LetterProblem Function(ProblemConfiguration, {required Duration timeout})
    _parseAlgorithm(algorithm) {
  switch (algorithm) {
    case 'fromRandom':
      return LetterProblem.generateFromRandom;
    case 'fromBuildingUp':
      return LetterProblem.generateFromBuildingUp;
    case 'fromRandomWord':
      return LetterProblem.generateFromRandomWord;
    default:
      throw InvalidAlgorithmException();
  }
}

Duration _parseTimeout(timeout) {
  try {
    return Duration(seconds: forceIntParse(timeout));
  } catch (e) {
    throw InvalidTimeoutException();
  }
}

ProblemConfiguration _parseProblemConfiguration({
  lengthShortestSolutionMin,
  lengthShortestSolutionMax,
  lengthLongestSolutionMin,
  lengthLongestSolutionMax,
  nbSolutionsMin,
  nbSolutionsMax,
  nbUselessLetters,
}) {
  try {
    return ProblemConfiguration(
      lengthShortestSolution:
          forceRangeParse(lengthShortestSolutionMin, lengthShortestSolutionMax),
      lengthLongestSolution:
          forceRangeParse(lengthLongestSolutionMin, lengthLongestSolutionMax),
      nbSolutions: forceRangeParse(nbSolutionsMin, nbSolutionsMax),
      nbUselessLetters: forceIntParse(nbUselessLetters),
    );
  } catch (e) {
    throw InvalidConfigurationException();
  }
}

void _sendMessageToClient(WebSocket socket,
    {required GameServerToClientMessages type, dynamic data}) {
  final message = {
    'type': type.index,
    'data': data,
  };
  socket.add(json.encode(message));
}

int forceIntParse(value) => value is int ? value : int.parse(value);
Range forceRangeParse(valueMin, valueMax) =>
    Range(forceIntParse(valueMin), forceIntParse(valueMax));
