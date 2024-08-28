import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

String? channelId;
String? clientId;
String? token;
String? helixToken;
String? userId;

void main() {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });

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
