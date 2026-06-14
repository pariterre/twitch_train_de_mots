import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      color: Colors.black.withAlpha(200),
      padding: const EdgeInsets.symmetric(horizontal: 100.0),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Text(
              'Votre cheminot·e en chef fait\nune petite pause café!',
              style: tm.textFrontendSc,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
