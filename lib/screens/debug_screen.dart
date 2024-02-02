import 'package:flutter/material.dart';
import 'package:train_de_mots/widgets/fireworks.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  static const route = '/debug-screen';

  @override
  Widget build(BuildContext context) {
    final controller = FireworksController(
      huge: false,
      minColor: const Color.fromARGB(184, 0, 100, 200),
      maxColor: const Color.fromARGB(184, 100, 120, 255),
    );
    return Scaffold(
      body: Center(
        child: Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(color: Colors.blue),
            child: Fireworks(controller: controller)),
      ),
    );
  }
}
