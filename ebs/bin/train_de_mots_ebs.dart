import 'dart:io';

import 'package:common/generic/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots_ebs/managers/ebs_manager.dart';
import 'package:twitch_manager/twitch_ebs.dart';

final _logger = Logger('TrainDeMotsEbs');

const _useTwitchMocker = false;

void main(List<String> arguments) async {
  // If the arguments request help, print the help message and exit
  if (arguments.contains('--help') || arguments.contains('-h')) {
    print('Usage: train_de_mots_ebs [options]\n'
        'Options:\n'
        '  --host=<host> or -h=<host>      The host name to listen on\n'
        '  --port=<port> or -p=<port>      The port number to listen on\n'
        '  --ssl=<cert.pem>,<key.pem> or -s=<cert.pem>,<key.pem>\n'
        '                                  The SSL certificate and key\n'
        '  --log=<filename> or -l=<filename>\n'
        '                                  The log file name\n'
        '  --help or -h                    Print this help message\n');
    exit(0);
  }

  _setupLoggerFromArguments(arguments);

  final networkParameters = _processNetworkArguments(arguments,
      defaultHost: 'localhost', defaultPort: 3010);

  final databasePrivateKey =
      Platform.environment['TRAIN_DE_MOTS_EBS_DATABASE_PRIVATE_KEY'];
  if (databasePrivateKey == null) {
    throw ArgumentError(
        'No database private key provided, please provide one by setting '
        'TRAIN_DE_MOTS_EBS_DATABASE_PRIVATE_KEY environment variable');
  }

  startEbsServer(
      parameters: networkParameters,
      ebsInfo: getTwitchEbsInfo(),
      credentialsStorage: TwitchEbsCredentialsStorageSqlite(
          databasePath: 'ebs_database.db', pragmaKey: databasePrivateKey),
      twitchEbsManagerFactory: ({
        required broadcasterId,
        required ebsInfo,
        required sendPort,
      }) =>
          EbsManager.spawn(
              broadcasterId: broadcasterId,
              ebsInfo: ebsInfo,
              sendPort: sendPort,
              useMockedTwitchApi: _useTwitchMocker));

  _logger.info(
      'EBS server started on ${networkParameters.host}:${networkParameters.port}');
}

NetworkParameters _processNetworkArguments(List<String> arguments,
    {required String defaultHost, required int defaultPort}) {
  _logger.info('Getting host and port connexion information');
  final host = arguments
      .firstWhere((e) => e.startsWith('--host=') || e.startsWith('-h='),
          orElse: () => '--host=$defaultHost')
      .split('=')[1];
  if (host.isEmpty) throw ArgumentError('Host name cannot be empty');

  final port = int.parse(arguments
      .firstWhere((e) => e.startsWith('--port=') || e.startsWith('-p='),
          orElse: () => '--port=$defaultPort')
      .split('=')[1]);
  if (port < 0 || port > 65535) {
    throw ArgumentError('Port number must be between 0 and 65535');
  }
  _logger.info('Connexion information received: $host:$port');

  _logger.info('Getting SSL certificate and key information');
  final ssl = arguments
      .firstWhere((e) => e.startsWith('--ssl=') || e.startsWith('-s='),
          orElse: () => '--ssl=')
      .split('=')[1];

  String? certificatePath;
  String? privateKeyPath;
  if (ssl.isEmpty) {
    _logger.info('No SSL certificate and key provided, using HTTP');
  } else {
    try {
      certificatePath = ssl.split(',')[0];
      privateKeyPath = ssl.split(',')[1];
    } catch (e) {
      throw ArgumentError(
          'Invalid SSL certificate and key, the expected format is: '
          '--ssl=<cert.pem>,<key.pem>');
    }

    if (certificatePath.isEmpty || privateKeyPath.isEmpty) {
      throw ArgumentError(
          'Invalid SSL certificate and key, the expected format is: '
          '--ssl=<cert.pem>,<key.pem>');
    }
    _logger.info('SSL certificate and key received, using HTTPS');
  }

  return NetworkParameters(
      host: host,
      port: port,
      certificatePath: certificatePath,
      privateKeyPath: privateKeyPath);
}

void _setupLoggerFromArguments(List<String> arguments) {
  try {
    final logFilename = arguments
        .firstWhere((e) => e.startsWith('--log=') || e.startsWith('-l='),
            orElse: () => '--log=train_de_mots.log')
        .split('=')[1];
    final logFile = File(logFilename);

    logFile.writeAsStringSync(
        '-----------------------------------\n'
        'Starting new log at ${DateTime.now()}\n',
        mode: FileMode.append);
    Logger.root.onRecord.listen((record) {
      final message = '${record.time}: ${record.message}';
      logFile.writeAsStringSync('$message\n', mode: FileMode.append);
      print(message);
    });
  } catch (e) {
    throw ArgumentError('Starting the logger failed: $e');
  }
}

TwitchEbsInfo getTwitchEbsInfo() {
  final extensionSharedSecret = _useTwitchMocker
      ? mockedSharedSecret
      : Platform.environment['TRAIN_DE_MOTS_EXTENSION_SHARED_SECRET'];
  if (extensionSharedSecret == null) {
    throw ArgumentError(
        'No Twitch extension shared secret provided, please provide one by setting '
        'TRAIN_DE_MOTS_EXTENSION_SHARED_SECRET environment variable');
  }

  final extensionApiClientSecret =
      Platform.environment['TRAIN_DE_MOTS_EXTENSION_API_CLIENT_SECRET'];
  if (extensionApiClientSecret == null) {
    throw ArgumentError(
        'No Twitch extension API client secret key provided, please provide one by setting '
        'TRAIN_DE_MOTS_EXTENSION_API_CLIENT_SECRET environment variable');
  }

  final privateKey = Platform.environment['TRAIN_DE_MOTS_EBS_PRIVATE_KEY'];
  if (privateKey == null) {
    throw ArgumentError(
        'No private key provided, please provide one by setting '
        'TRAIN_DE_MOTS_EBS_PRIVATE_KEY environment variable');
  }

  return TwitchEbsInfo(
    appName: 'Train de mots',
    twitchClientId: '539pzk7h6vavyzmklwy6msq6k3068x',
    extensionVersion: '0.4.1',
    extensionApiClientSecret: extensionApiClientSecret,
    extensionSharedSecret: extensionSharedSecret,
    isTwitchUserIdRequired: true,
    authenticationFlow: TwitchAuthenticationFlow.implicit,
    privateKey: privateKey,
  );
}
