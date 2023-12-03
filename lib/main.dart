import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/sound_manager.dart';
import 'package:train_de_mots/screens/main_screen.dart';

void main() async {
  // Initialize singleton
  SoundManager.instance;

  runApp(ProviderScope(child: Consumer(builder: (context, ref, child) {
    ref.read(gameManagerProvider).initialize();
    return const MyApp();
  })));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: MainScreen.route,
      routes: {MainScreen.route: (ctx) => const MainScreen()},
    );
  }
}
