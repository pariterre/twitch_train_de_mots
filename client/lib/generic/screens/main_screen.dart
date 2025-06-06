import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/screens/between_round_screen.dart';
import 'package:train_de_mots/generic/screens/congratulation_layer.dart';
import 'package:train_de_mots/generic/screens/game_screen.dart';
import 'package:train_de_mots/generic/screens/splash_screen.dart';
import 'package:train_de_mots/generic/widgets/configuration_drawer.dart';
import 'package:train_de_mots/generic/widgets/parchment_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const route = '/game-screen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.listen(_refresh);
    gm.onNextProblemReady.listen(_refresh);
    gm.onRoundStarted.listen(_refresh);
    gm.onShowTelegram = _showMessageDialog;
    gm.onShowcaseSolutionsRequest.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);

    final dm = Managers.instance.database;
    dm.onFullyLoggedIn.listen(_refresh);
    dm.onLoggedOut.listen(_refresh);

    Managers.instance.twitch.onTwitchManagerHasDisconnected
        .listen(_reconnectedAfterDisconnect);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.cancel(_refresh);
    gm.onNextProblemReady.cancel(_refresh);
    gm.onRoundStarted.cancel(_refresh);
    gm.onShowcaseSolutionsRequest.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    final dm = Managers.instance.database;
    dm.onFullyLoggedIn.cancel(_refresh);
    dm.onLoggedOut.cancel(_refresh);

    Managers.instance.twitch.onTwitchManagerHasDisconnected
        .cancel(_reconnectedAfterDisconnect);

    super.dispose();
  }

  void _reconnectedAfterDisconnect() =>
      _setTwitchManager(reloadIfPossible: false);

  Future<void> _showMessageDialog(String message) async {
    final cm = Managers.instance.configuration;
    final tm = ThemeManager.instance;

    await showDialog(
        context: context,
        builder: (context) {
          Managers.instance.sound.playTelegramReceived();
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
    if (Managers.instance.twitch.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _setTwitchManager(reloadIfPossible: true));
    }
  }

  void _refresh() => setState(() {});

  void _onClickedBegin() => Managers.instance.train.requestStartNewRound();

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final dm = Managers.instance.database;
    final tm = ThemeManager.instance;

    return Scaffold(
      body: Background(
        backgroundLayer: Image.asset(
          'packages/common/assets/images/train.png',
          height: MediaQuery.of(context).size.height,
          opacity: const AlwaysStoppedAnimation(0.05),
          fit: BoxFit.cover,
        ),
        child: Managers.instance.twitch.isNotConnected
            ? Center(child: CircularProgressIndicator(color: tm.mainColor))
            : Stack(
                children: [
                  dm.isLoggedOut ||
                          gm.gameStatus == WordsTrainGameStatus.initializing
                      ? SplashScreen(onClickStart: _onClickedBegin)
                      : Stack(
                          children: [
                            GameScreen(),
                            if (gm.gameStatus ==
                                    WordsTrainGameStatus.roundPreparing ||
                                gm.gameStatus ==
                                    WordsTrainGameStatus.roundReady ||
                                gm.gameStatus ==
                                    WordsTrainGameStatus.miniGamePreparing ||
                                gm.gameStatus ==
                                    WordsTrainGameStatus.miniGameReady)
                              const BetweenRoundsOverlay(),
                            const CongratulationLayer(),
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
