import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart';

final _logger = Logger('main');

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });

  await TwitchFrontendManager.factory(
    appInfo: TwitchFrontendInfo(
      appName: 'Train de mots',
      ebsUri: Uri.parse('http://localhost:3010/frontend'),
    ),
    onHasConnectedCallback: () => _logger.info('Connected to Twitch. Yé!'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Twitch Extension Example'),
        ),
        body: const Center(
          child: Text('Check the console for output.'),
        ),
      ),
    );
  }
}
