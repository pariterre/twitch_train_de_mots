import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:train_de_mots_server/letter_problem.dart';
import 'package:train_de_mots_server/problem_configuration.dart';
import 'package:train_de_mots_server/range.dart';

LetterProblem Function(ProblemConfiguration, {required Duration timeout})
    parseAlgorithm(String algorithm) {
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

void main(List<String> arguments) async {
  // Wait for a GET request on port 3010
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3010);

  print('Listening on localhost:${server.port}');

  await for (HttpRequest request in server) {
    print('New request received');

    late final LetterProblem Function(ProblemConfiguration,
        {required Duration timeout}) algorithm;
    try {
      algorithm = parseAlgorithm(request.uri.queryParameters['algorithm']!);
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid algorithm')
        ..close();
    }

    late final Duration timeout;
    try {
      timeout =
          Duration(seconds: int.parse(request.uri.queryParameters['timeout']!));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid timeout')
        ..close();
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
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid configuration')
        ..close();
    }

    print('Algorithm: ${request.uri.queryParameters['algorithm']}');
    print('Timeout: ${request.uri.queryParameters['timeout']}');
    print('Configuration:\n'
        '\tlengthShortestSolution: ${request.uri.queryParameters['lengthShortestSolutionMin']} - ${request.uri.queryParameters['lengthShortestSolutionMax']}\n'
        '\tlengthLongestSolution: ${request.uri.queryParameters['lengthLongestSolutionMin']} - ${request.uri.queryParameters['lengthLongestSolutionMax']}\n'
        '\tnbSolutions: ${request.uri.queryParameters['nbSolutionsMin']} - ${request.uri.queryParameters['nbSolutionsMax']}\n'
        '\tnbUselessLetters: ${request.uri.queryParameters['nbUselessLetters']}');

    try {
      final problem = algorithm(config, timeout: timeout);

      print('Problem generated (${problem.letters.join()})');
      print('');
      request.response
        ..statusCode = HttpStatus.ok
        ..write(json.encode(problem.serialize()))
        ..close();
    } on TimeoutException {
      request.response
        ..statusCode = HttpStatus.requestTimeout
        ..write('Timeout')
        ..close();
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal server error')
        ..close();
    }
  }
}
