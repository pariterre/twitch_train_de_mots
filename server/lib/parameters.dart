import 'dart:io';

import 'package:logging/logging.dart';

final _logging = Logger('authentication_server');

class Parameters {
  late final String host;
  late final int port;

  bool get usingSecure =>
      certificatePath?.isNotEmpty == true && privateKeyPath?.isNotEmpty == true;
  late final String? certificatePath;
  late final String? privateKeyPath;

  Parameters(List<String> arguments,
      {required hostDefaultValue, required portDefaultValue}) {
    // If the arguments request help, print the help message and exit
    if (arguments.contains('--help') || arguments.contains('-h')) {
      print('Usage: train_de_mots_server [options]\n'
          'Options:\n'
          '  --host=<host> or -h=<host>     The host name to listen on\n'
          '  --port=<port> or -p=<port>     The port number to listen on\n'
          '  --ssl=<cert.pem>,<key.pem> or -s=<cert.pem>,<key.pem>\n'
          '                                  The SSL certificate and key\n'
          '  --log=<filename> or -l=<filename>\n'
          '                                  The log file name\n'
          '  --help or -h                    Print this help message\n');
      exit(0);
    }

    _setupLoggerFromArguments(arguments);
    _processArgumentsConnexion(arguments,
        defaultHost: hostDefaultValue, defaultPort: portDefaultValue);
    _processArgumentsSsl(arguments);
  }

  void _processArgumentsSsl(List<String> arguments) {
    final ssl = arguments
        .firstWhere((e) => e.startsWith('--ssl=') || e.startsWith('-s='),
            orElse: () => '--ssl=')
        .split('=')[1];
    if (ssl.isEmpty) {
      certificatePath = null;
      privateKeyPath = null;

      _logging.info('No SSL certificate and key provided, using HTTP');
      return;
    }

    try {
      certificatePath = ssl.split(',')[0];
      privateKeyPath = ssl.split(',')[1];
    } catch (e) {
      throw ArgumentError(
          'Invalid SSL certificate and key, the expected format is: '
          '--ssl=<cert.pem>,<key.pem>');
    }

    if (ssl.isNotEmpty &&
        (certificatePath!.isEmpty || privateKeyPath!.isEmpty)) {
      throw ArgumentError(
          'Invalid SSL certificate and key, the expected format is: '
          '--ssl=<cert.pem>,<key.pem>');
    }

    _logging.info('SSL certificate and key received, using HTTPS');
    return;
  }

  bool _processArgumentsConnexion(List<String> arguments,
      {required String defaultHost, required int defaultPort}) {
    host = arguments
        .firstWhere((e) => e.startsWith('--host=') || e.startsWith('-h='),
            orElse: () => '--host=$defaultHost')
        .split('=')[1];
    if (host.isEmpty) throw ArgumentError('Host name cannot be empty');

    port = int.parse(arguments
        .firstWhere((e) => e.startsWith('--port=') || e.startsWith('-p='),
            orElse: () => '--port=$defaultPort')
        .split('=')[1]);
    if (port < 0 || port > 65535) {
      throw ArgumentError('Port number must be between 0 and 65535');
    }

    _logging.info('Connexion information received: $host:$port');
    return true;
  }
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
