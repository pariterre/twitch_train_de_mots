import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/screens/between_round_screen.dart';
import 'package:train_de_mots/screens/game_screen.dart';
import 'package:train_de_mots/screens/splash_screen.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/configuration_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const route = '/game-screen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> _setTwitchManager() async {
    await TwitchManager.instance.showConnectManagerDialog(context);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundIsPreparing.addListener(_refresh);
    gm.onNextProblemReady.addListener(_refresh);
    gm.onRoundStarted.addListener(_refresh);
    gm.onTimerTicks.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onRoundIsOver.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);

    final dm = DatabaseManager.instance;
    dm.onFullyLoggedIn.addListener(_refresh);
    dm.onLoggedOut.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundIsPreparing.removeListener(_refresh);
    gm.onNextProblemReady.removeListener(_refresh);
    gm.onRoundStarted.removeListener(_refresh);
    gm.onTimerTicks.removeListener(_refresh);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onRoundIsOver.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    final dm = DatabaseManager.instance;
    dm.onFullyLoggedIn.removeListener(_refresh);
    dm.onLoggedOut.removeListener(_refresh);

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchManager.instance.hasNotManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(solution) => setState(() {});

  void _onClickedBegin() => GameManager.instance.requestStartNewRound();

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final dm = DatabaseManager.instance;

    return Scaffold(
      body: SingleChildScrollView(
          child: Background(
        child: Stack(
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
      )),
      drawer: const ConfigurationDrawer(),
    );
  }
}
