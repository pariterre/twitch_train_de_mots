import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
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

    ref
        .read(gameManagerProvider)
        .onRoundIsPreparing
        .addListener(_onRoundIsPreparing);
    ref
        .read(gameManagerProvider)
        .onNextProblemReady
        .addListener(_onRoundIsReady);
    ref.read(gameManagerProvider).onRoundStarted.addListener(_onRoundStarted);
    ref.read(gameManagerProvider).onTimerTicks.addListener(_onClockTicks);
    ref.read(gameManagerProvider).onSolutionFound.addListener(_onSolutionFound);
    ref.read(gameManagerProvider).onRoundIsOver.addListener(_onRoundIsOver);
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
    super.dispose();

    ref
        .read(gameManagerProvider)
        .onRoundIsPreparing
        .removeListener(_onRoundIsPreparing);
    ref
        .read(gameManagerProvider)
        .onNextProblemReady
        .removeListener(_onRoundIsReady);
    ref
        .read(gameManagerProvider)
        .onRoundStarted
        .removeListener(_onRoundStarted);
    ref.read(gameManagerProvider).onTimerTicks.removeListener(_onClockTicks);
    ref
        .read(gameManagerProvider)
        .onSolutionFound
        .removeListener(_onSolutionFound);
    ref.read(gameManagerProvider).onRoundIsOver.removeListener(_onRoundIsOver);
  }

  void _onRoundIsPreparing() => setState(() {});
  void _onRoundIsReady() => setState(() {});
  void _onRoundStarted() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onSolutionFound(solution) => setState(() {});

  void _onRoundIsOver() => setState(() {});

  void _onClickedBegin() =>
      ref.read(gameManagerProvider).requestStartNewRound();

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

    return Scaffold(
      body: TwitchInterface.instance.hasNotManager
          ? Center(
              child: CircularProgressIndicator(color: scheme.mainColor),
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
