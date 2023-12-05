import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/screens/between_round_screen.dart';
import 'package:train_de_mots/screens/game_screen.dart';
import 'package:train_de_mots/screens/splash_screen.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/configuration_drawer.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  static const route = '/game-screen';

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Future<void> _setTwitchManager() async {
    await TwitchInterface.instance.showConnectManagerDialog(context);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundIsPreparing.addListener(_refresh);
    gm.onNextProblemReady.addListener(_refresh);
    gm.onRoundStarted.addListener(_refresh);
    gm.onTimerTicks.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onRoundIsOver.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchInterface.instance.hasNotManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
  }

  @override
  void dispose() {
    final gm = ref.read(gameManagerProvider);
    gm.onRoundIsPreparing.removeListener(_refresh);
    gm.onNextProblemReady.removeListener(_refresh);
    gm.onRoundStarted.removeListener(_refresh);
    gm.onTimerTicks.removeListener(_refresh);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onRoundIsOver.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(solution) => setState(() {});

  void _onClickedBegin() =>
      ref.read(gameManagerProvider).requestStartNewRound();

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final tm = ThemeManager.instance;

    return Scaffold(
      body: TwitchInterface.instance.hasNotManager
          ? Center(
              child: CircularProgressIndicator(color: tm.mainColor),
            )
          : TwitchInterface.instance.debugOverlay(
              child: SingleChildScrollView(
                  child: Background(
              child: Stack(
                children: [
                  gm.gameStatus == GameStatus.initializing
                      ? SplashScreen(onClickStart: _onClickedBegin)
                      : const GameScreen(),
                  if (gm.roundCount > 0 &&
                          gm.gameStatus == GameStatus.roundPreparing ||
                      gm.gameStatus == GameStatus.roundReady)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.only(top: 80.0),
                      child: BetweenRoundsOverlay(),
                    )),
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
                  }),
                ],
              ),
            ))),
      drawer: const ConfigurationDrawer(),
    );
  }
}
