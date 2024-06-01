import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/widgets/train_path.dart';

void main() async {
  await ConfigurationManager.initialize();
  await GameManager.initialize();
  await ThemeManager.initialize();
  await SoundManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DebugScreen());
  }
}

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  static const route = '/debug-screen';

  @override
  Widget build(BuildContext context) {
    final controller = TrainPathController(millisecondsPerStep: 50);
    controller.nbSteps = 50;

    controller.hallMarks = [10, 20, 49];

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      controller.moveForward();
    });

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: TrainPath(
            controller: controller,
            pathLength: 500,
            height: 100,
          ),
        ),
      ),
    );
  }
}
