import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/blueberry_war/screens/blueberry_war_game_screen.dart';
import 'package:train_de_mots/blueberry_war/to_remove/any_dumb_stuff.dart';

final _logger = Logger('Main');

void main() {
  // Set up logging
  Logger.root.level = Level.INFO; // Set the logging level
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  _logger.info('Starting Twitch Blueberry War App');

  Managers.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(body: BlueberryWarGameScreen()),
    );
  }
}
