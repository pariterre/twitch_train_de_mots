import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onClickStart});

  final Function() onClickStart;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isGameReadyToPlay = false;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onNextProblemReady.addListener(_onNextProblemReady);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onNextProblemReady.removeListener(_onNextProblemReady);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _onNextProblemReady() {
    _isGameReadyToPlay = true;
    setState(() {});
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final dm = DatabaseManager.instance;

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
                color: tm.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            SizedBox(
              width: 700,
              child: Text(
                  'Chères cheminots et cheminotes, bienvenue à bord!\n'
                  '\n'
                  'Nous avons besoin de vous pour énergiser le Petit Train du Nord! '
                  'Trouvez le plus de mots possible pour emmener le train à destination. '
                  'Le ou la meilleure cheminot\u2022e sera couronné\u2022e de gloire!\n'
                  '\n'
                  'Mais attention, bien que vous devez travailler ensemble pour arriver à bon port, '
                  'vos collègues sans scrupules peuvent vous voler vos mots!',
                  style: TextStyle(
                    fontSize: 24.0,
                    color: tm.textColor,
                  ),
                  textAlign: TextAlign.justify),
            ),
            const SizedBox(height: 30.0),
            Text(
              dm.isUserLoggedIn
                  ? 'C\'est un départ! Tchou Tchou!!'
                  : 'Mais avant le départ, veuillez vous connecter!',
              style: TextStyle(
                fontSize: 24.0,
                color: tm.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            if (!dm.isUserLoggedIn) const _ConnexionTile(),
            if (dm.isUserLoggedIn) _buildContinueButton(tm),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildContinueButton(ThemeManager tm) {
    return ElevatedButton(
      onPressed: _isGameReadyToPlay ? widget.onClickStart : null,
      style: tm.elevatedButtonStyle,
      child: Text(
        _isGameReadyToPlay
            ? 'Direction première station!'
            : 'Préparation du train...',
        style:
            TextStyle(fontSize: tm.buttonTextSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ConnexionTile extends StatelessWidget {
  const _ConnexionTile();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0)),
      width: 500,
      child: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Courriel',
                    labelStyle: TextStyle(
                      color: tm.mainColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tm.mainColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tm.mainColor)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(
                    color: tm.mainColor,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: tm.mainColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                obscureText: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
