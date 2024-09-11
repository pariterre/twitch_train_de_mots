import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Center(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Text(
        'Bien le bonjour cheminot\u00b7e,\n'
        '\n'
        'Nous sommes en attente du départ du train, veuillez patienter...',
        textAlign: TextAlign.left,
        style: tm.textFrontendSc,
      ),
    ));
  }
}
