import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/themed_elevated_button.dart';

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

    final dm = DatabaseManager.instance;
    dm.onLoggedIn.addListener(_refresh);
    dm.onLoggedOut.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onNextProblemReady.removeListener(_onNextProblemReady);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    final dm = DatabaseManager.instance;
    dm.onLoggedIn.removeListener(_refresh);
    dm.onLoggedOut.removeListener(_refresh);
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

    return Background(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: dm.isLoggedIn
              ? Column(
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
                          'Chères cheminots et cheminotes de ${dm.teamName}, bienvenue à bord!\n'
                          '\n'
                          'Nous avons besoin de vous pour énergiser le Petit Train du Nord! '
                          'Trouvez le plus de mots possibles pour emmener le train à destination. '
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
                      'C\'est un départ! Tchou Tchou!!',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: tm.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    ThemedElevatedButton(
                      onPressed:
                          _isGameReadyToPlay ? widget.onClickStart : null,
                      buttonText: _isGameReadyToPlay
                          ? 'Direction première station!'
                          : 'Préparation du train...',
                    ),
                  ],
                )
              : const _ConnexionTile(),
        ),
      ),
    );
  }
}

class _ConnexionTile extends StatefulWidget {
  const _ConnexionTile();

  @override
  State<_ConnexionTile> createState() => _ConnexionTileState();
}

class _ConnexionTileState extends State<_ConnexionTile> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoggingIn = true;

  String? _email;
  String? _password;
  String? _teamName;

  Future<void> _logIn() async {
    if (!_validateForm()) return;

    try {
      await DatabaseManager.instance
          .logIn(email: _email!, password: _password!);
    } on AuthenticationException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _signIn() async {
    if (!_validateForm()) return;

    try {
      await DatabaseManager.instance.signIn(
        email: _email!,
        password: _password!,
        teamName: _teamName!,
      );
    } on AuthenticationException catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String errorMessage) {
    if (!mounted) return;
    final tm = ThemeManager.instance;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage,
          style: TextStyle(color: tm.mainColor, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
    ));
  }

  bool _validateForm() {
    if (_formKey.currentState == null) return false;
    if (!_formKey.currentState!.validate()) return false;

    _formKey.currentState!.save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    final border = OutlineInputBorder(
      borderSide: BorderSide(color: tm.mainColor),
      borderRadius: BorderRadius.circular(10),
    );

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white.withOpacity(0.95)),
      width: 650,
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                    'Ô Capitaine! J\'ai une mission pour vous sur le Petit Train du Nord! '
                    'Mais avant toute chose, veuillez identifier votre équipe!',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: tm.mainColor,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Courriel',
                  labelStyle: TextStyle(color: tm.mainColor),
                  focusedBorder: border,
                  border: border,
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un courriel';
                  }
                  RegExp emailRegex =
                      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Veuillez entrer un courriel valide';
                  }

                  return null;
                },
                onSaved: (value) => _email = value,
              ),
              if (!_isLoggingIn)
                Column(
                  children: [
                    const SizedBox(height: 12.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'équipe',
                        labelStyle: TextStyle(color: tm.mainColor),
                        focusedBorder: border,
                        border: border,
                        prefixIcon: const Icon(Icons.group),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom d\'équipe';
                        }

                        if (value.length < 4) {
                          return 'Le nom de l\'équipe doit contenir au moins 4 caractères';
                        }

                        return null;
                      },
                      onSaved: (value) => _teamName = value,
                    ),
                  ],
                ),
              const SizedBox(height: 12.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: tm.mainColor),
                  focusedBorder: border,
                  border: border,
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                enableSuggestions: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }

                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }

                  return null;
                },
                onSaved: (value) => _password = value,
              ),
              const SizedBox(height: 24.0),
              Center(
                child: ThemedElevatedButton(
                  onPressed: _isLoggingIn ? _logIn : _signIn,
                  reversedStyle: true,
                  buttonText: _isLoggingIn
                      ? 'Embarquer dans le train!'
                      : 'Embaucher mon équipe',
                ),
              ),
              const SizedBox(height: 12.0),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoggingIn = !_isLoggingIn;
                    });
                  },
                  child: Text(
                      _isLoggingIn
                          ? 'Inscrire une nouvelle équipe'
                          : 'J\'ai déjà mon équipe',
                      style: TextStyle(
                        color: tm.mainColor,
                        fontSize: 18,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
