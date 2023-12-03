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
            SizedBox(
              width: 700,
              child: Text(
                  'Chères cheminots et cheminotes, bienvenue à bord!\n'
                  '\n'
                  'Nous avons besoin de vous pour énergiser le Petit train du Nord! '
                  'Trouvez le plus de mots possible pour emmener le train à destination. '
                  'Le ou la meilleure cheminot\u2022e sera couronné\u2022e de gloire!\n'
                  '\n'
                  'Mais attention, bien que vous devez travailler ensemble pour arriver à bon port, '
                  'vos collègues sans scrupules peuvent vous voler vos mots!',
                  style: TextStyle(
                    fontSize: 24.0,
                    color: scheme.textColor,
                  ),
                  textAlign: TextAlign.justify),
            ),
            const SizedBox(height: 30.0),
            Text(
              'C\'est un départ! Tchou Tchou!!',
              style: TextStyle(
                fontSize: 24.0,
                color: scheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: onClickStart,
              style: scheme.elevatedButtonStyle,
              child: Text(
                'Direction première station!',
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
