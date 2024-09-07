import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/screens/between_round_screen.dart';
import 'package:train_de_mots/screens/game_screen.dart';
import 'package:train_de_mots/screens/splash_screen.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/configuration_drawer.dart';
import 'package:train_de_mots/widgets/parchment_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const route = '/game-screen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await TwitchManager.instance
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundIsPreparing.addListener(_refresh);
    gm.onNextProblemReady.addListener(_refresh);
    gm.onRoundStarted.addListener(_refresh);
    gm.onShowMessage = _showMessageDialog;
    gm.onShowcaseSolutionsRequest.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);

    final dm = DatabaseManager.instance;
    dm.onFullyLoggedIn.addListener(_refresh);
    dm.onLoggedOut.addListener(_refresh);

    TwitchManager.instance.onTwitchManagerHasDisconnected
        .addListener(_reconnectedAfterDisconnect);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundIsPreparing.removeListener(_refresh);
    gm.onNextProblemReady.removeListener(_refresh);
    gm.onRoundStarted.removeListener(_refresh);
    gm.onShowcaseSolutionsRequest.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    final dm = DatabaseManager.instance;
    dm.onFullyLoggedIn.removeListener(_refresh);
    dm.onLoggedOut.removeListener(_refresh);

    TwitchManager.instance.onTwitchManagerHasDisconnected
        .removeListener(_reconnectedAfterDisconnect);

    super.dispose();
  }

  void _reconnectedAfterDisconnect() =>
      _setTwitchManager(reloadIfPossible: false);

  Future<void> _showMessageDialog(String message) async {
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    await showDialog(
        context: context,
        builder: (context) {
          SoundManager.instance.playTelegramReceived();
          return ParchmentDialog(
            title: 'Un télégramme pour vous!',
            content: Text(message, style: TextStyle(fontSize: tm.textSize)),
            width: 500,
            height: 600,
            acceptButtonTitle: 'Merci!',
            autoAcceptDuration:
                cm.autoplay ? const Duration(seconds: 10) : null,
            onAccept: () => Navigator.of(context).pop(),
          );
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchManager.instance.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _setTwitchManager(reloadIfPossible: true));
    }
  }

  void _refresh() => setState(() {});

  void _onClickedBegin() => GameManager.instance.requestStartNewRound();

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final dm = DatabaseManager.instance;
    final tm = ThemeManager.instance;

    return Scaffold(
      body: Background(
        child: TwitchManager.instance.isNotConnected
            ? Center(child: CircularProgressIndicator(color: tm.mainColor))
            : Stack(
                children: [
                  dm.isLoggedOut || gm.gameStatus == GameStatus.initializing
                      ? SplashScreen(onClickStart: _onClickedBegin)
                      : Stack(
                          children: [
                            const GameScreen(),
                            if (gm.gameStatus == GameStatus.roundPreparing ||
                                gm.gameStatus == GameStatus.roundReady)
                              const BetweenRoundsOverlay(),
                          ],
                        ),
                  Builder(builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                              size: 32,
                            )),
                      ),
                    );
                  })
                ],
              ),
      ),
      drawer: const ConfigurationDrawer(),
    );
  }
}
