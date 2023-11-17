import 'package:flutter/material.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/word_manipulation.dart';
import 'package:train_de_mots/screens/game_screen.dart';

void main() async {
  // Initialize singleton
  await Future.wait([
    Configuration.instance.initialize(),
    WordManipulation.instance.initialize(),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GameScreen(),
    );
  }
}
