import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key, required this.onClickStart});

  final Function() onClickStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(schemeProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Train de mots',
              style: TextStyle(
                fontSize: 48.0,
                color: scheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            Text(
              'Tchou Tchou!',
              style: TextStyle(
                fontSize: 36.0,
                color: scheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: onClickStart,
              style: scheme.elevatedButtonStyle,
              child: Text(
                'Démarrer la partie',
                style: TextStyle(
                    fontSize: scheme.buttonTextSize,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
