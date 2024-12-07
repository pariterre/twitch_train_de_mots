import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/widgets/header.dart';

class DraggingScreen extends StatelessWidget {
  const DraggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Header(
              titleText: GameManager.instance.isRoundRunning
                  ? 'Le train est en route!\n'
                      'Prochaine station : ${GameManager.instance.currentRound + 1}!'
                  : 'Le Train de mots!'),
        ],
      ),
    );
  }
}
