import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:train_de_mots_server/letter_problem.dart';
import 'package:train_de_mots_server/parameters.dart';
import 'package:train_de_mots_server/problem_configuration.dart';
import 'package:train_de_mots_server/range.dart';
import 'package:train_de_mots_server/rate_limiter.dart';

final _logging = Logger('authentication_server');

void main(List<String> arguments) async {
  final p = Parameters(arguments,
      hostDefaultValue: 'localhost', portDefaultValue: 3010);

  final server = await _startingServer(p);
  final rateLimiter = RateLimiter(20, Duration(minutes: 1));

  _handleRequests(server: server, rateLimiter: rateLimiter);
}

Future<HttpServer> _startingServer(Parameters p) async {
  _logging.info(
      'Server starting on ${p.host}:${p.port}, ${p.usingSecure ? '' : 'not '}using SSL');
  return p.usingSecure
      ? await HttpServer.bindSecure(
          p.host,
          p.port,
          SecurityContext()
            ..useCertificateChain(p.certificatePath!)
            ..usePrivateKey(p.privateKeyPath!))
      : await HttpServer.bind(p.host, p.port);
}

void _handleRequests(
    {required HttpServer server, required RateLimiter rateLimiter}) async {
  await for (final request in server) {
    final ipAddress = request.connectionInfo?.remoteAddress.address;
    if (ipAddress == null) {
      _logging.severe('No IP address found');
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Connexion refused')
        ..close();
      continue;
    }

    _logging.info(
        'New request received from $ipAddress (${rateLimiter.requestCount(ipAddress) + 1} / ${rateLimiter.maxRequests})');

    if (rateLimiter.isRateLimited(ipAddress)) {
      _logging.severe('Rate limited');
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..write('Rate limited')
        ..close();
      continue;
    }

    if (request.method == 'OPTIONS') {
      _handleOptionsRequest(request);
    } else if (request.method == 'GET' && request.uri.path == '/getproblem') {
      _handleGetProblemRequest(request);
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
    ..write('Connexion refused')
    ..close();
}

LetterProblem Function(ProblemConfiguration, {required Duration timeout})
    _parseAlgorithm(String algorithm) {
  switch (algorithm) {
    case 'fromRandom':
      return LetterProblem.generateFromRandom;
    case 'fromBuildingUp':
      return LetterProblem.generateFromBuildingUp;
    case 'fromRandomWord':
      return LetterProblem.generateFromRandomWord;
    default:
      throw ArgumentError('Unknown algorithm');
  }
}

/// Handle GET request for a new problem
/// The request must contain the following parameters:
/// - algorithm: the algorithm to generate the problem
/// - timeout: the timeout for the problem
/// - configuration: the configuration of the problem
void _handleGetProblemRequest(HttpRequest request) {
  late final LetterProblem Function(ProblemConfiguration,
      {required Duration timeout}) algorithm;
  try {
    algorithm = _parseAlgorithm(request.uri.queryParameters['algorithm']!);
  } catch (e) {
    _logging.severe('Invalid algorithm');
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Invalid algorithm')
      ..close();
    return;
  }

  late final Duration timeout;
  try {
    timeout =
        Duration(seconds: int.parse(request.uri.queryParameters['timeout']!));
  } catch (e) {
    _logging.severe('Invalid timeout');
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Invalid timeout')
      ..close();
    return;
  }

  late final ProblemConfiguration config;
  try {
    // Get the problem configuration from the parameters of the request
    final lengthShortestSolution = Range(
        int.parse(request.uri.queryParameters['lengthShortestSolutionMin']!),
        int.parse(request.uri.queryParameters['lengthShortestSolutionMax']!));
    final lengthLongestSolution = Range(
        int.parse(request.uri.queryParameters['lengthLongestSolutionMin']!),
        int.parse(request.uri.queryParameters['lengthLongestSolutionMax']!));
    final nbSolutions = Range(
        int.parse(request.uri.queryParameters['nbSolutionsMin']!),
        int.parse(request.uri.queryParameters['nbSolutionsMax']!));
    final nbUselessLetters =
        int.parse(request.uri.queryParameters['nbUselessLetters']!);

    config = ProblemConfiguration(
      lengthShortestSolution: lengthShortestSolution,
      lengthLongestSolution: lengthLongestSolution,
      nbSolutions: nbSolutions,
      nbUselessLetters: nbUselessLetters,
    );
  } catch (e) {
    _logging.severe('Invalid configuration');
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Invalid configuration')
      ..close();
    return;
  }

  _logging.info('Algorithm: ${request.uri.queryParameters['algorithm']}\n'
      'Timeout: ${request.uri.queryParameters['timeout']}\n'
      'Configuration:\n'
      '\tlengthShortestSolution: ${request.uri.queryParameters['lengthShortestSolutionMin']} - ${request.uri.queryParameters['lengthShortestSolutionMax']}\n'
      '\tlengthLongestSolution: ${request.uri.queryParameters['lengthLongestSolutionMin']} - ${request.uri.queryParameters['lengthLongestSolutionMax']}\n'
      '\tnbSolutions: ${request.uri.queryParameters['nbSolutionsMin']} - ${request.uri.queryParameters['nbSolutionsMax']}\n'
      '\tnbUselessLetters: ${request.uri.queryParameters['nbUselessLetters']}');

  try {
    final problem = algorithm(config, timeout: timeout);

    _logging.info('Problem generated (${problem.letters.join()})\n');
    request.response
      ..statusCode = HttpStatus.ok
      ..write(json.encode(problem.serialize()))
      ..close();
    return;
  } on TimeoutException {
    _logging.severe('Timeout');
    request.response
      ..statusCode = HttpStatus.requestTimeout
      ..write('Timeout')
      ..close();
    return;
  } catch (e) {
    _logging.severe('Internal server error');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Internal server error')
      ..close();
    return;
  }
}
