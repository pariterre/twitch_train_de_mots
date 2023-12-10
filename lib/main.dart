import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/screens/main_screen.dart';

void main() async {
  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();

  await ConfigurationManager.initialize();
  await GameManager.initialize();
  await Future.wait([
    DatabaseManagerMock.initialize(),
    SoundManager.initialize(),
    ThemeManager.initialize(),
  ]);

  runApp(const MyApp());
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
