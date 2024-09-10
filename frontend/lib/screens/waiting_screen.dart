import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
              'Bien le bonjour cheminot\u00b7e!\n'
              'Nous sommes en attente du départ du train, veuillez patienter...',
              style: TextStyle(
                fontSize: 16.0,
                color: tm.textColor,
              ),
              textAlign: TextAlign.center),
        ),
      ],
    ));
  }
}
