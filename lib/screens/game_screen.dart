import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/widgets/animations_overlay.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/configuration_drawer.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
import 'package:train_de_mots/widgets/splash_screen.dart';
import 'package:train_de_mots/widgets/word_displayer.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static const route = '/game-screen';

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Future<void> _resquestTerminateRound() async {
    if (!mounted) return;
    await ref.read(gameManagerProvider).requestTerminateRound();
  }

  Future<void> _resquestStartNewRound() async {
    if (!mounted) return;
    await ref.read(gameManagerProvider).requestStartNewRound();
  }

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
                  gm.gameStatus == GameStatus.uninitialized
                      ? SplashScreen(onClickStart: _onClickedBegin)
                      : _buildGameScreen(),
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

  Widget _buildGameScreen() {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const _Header(),
              const SizedBox(height: 32),
              gm.isPreparingProblem
                  ? Center(
                      child: CircularProgressIndicator(
                      color: scheme.mainColor,
                    ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WordDisplayer(problem: gm.problem!),
                        const SizedBox(height: 20),
                        const SizedBox(
                          height: 600,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SolutionsDisplayer()),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              Card(
                elevation: 10,
                child: ElevatedButton(
                  onPressed: gm.gameStatus == GameStatus.roundStarted
                      ? _resquestTerminateRound
                      : gm.isNextProblemReady
                          ? _resquestStartNewRound
                          : null,
                  style: scheme.elevatedButtonStyle,
                  child: Text(
                    gm.gameStatus == GameStatus.roundStarted
                        ? 'Terminer la manche'
                        : 'Prochaine manche',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              )
            ],
          ),
        ),
        const Align(alignment: Alignment.topRight, child: LeaderBoard()),
        const AnimationOverlay(),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(schemeProvider);

    return Column(
      children: [
        Text(
          'Le Train de mots! Tchou Tchou!',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: scheme.textColor),
        ),
        const SizedBox(height: 20),
        Card(
          color: scheme.mainColor,
          elevation: 10,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: _HeaderTimer(),
          ),
        ),
      ],
    );
  }
}

class _HeaderTimer extends ConsumerStatefulWidget {
  const _HeaderTimer();

  @override
  ConsumerState<_HeaderTimer> createState() => _HeaderTimerState();
}

class _HeaderTimerState extends ConsumerState<_HeaderTimer> {
  @override
  void initState() {
    super.initState();

    ref.read(gameManagerProvider).onRoundStarted.addListener(_onRoundStarted);
    ref.read(gameManagerProvider).onTimerTicks.addListener(_onClockTicks);
    ref.read(gameManagerProvider).onRoundIsOver.addListener(_onRoundIsOver);
  }

  @override
  void dispose() {
    super.dispose();

    ref
        .read(gameManagerProvider)
        .onRoundStarted
        .removeListener(_onRoundStarted);
    ref.read(gameManagerProvider).onTimerTicks.removeListener(_onClockTicks);
    ref.read(gameManagerProvider).onRoundIsOver.removeListener(_onRoundIsOver);
  }

  void _onRoundStarted() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onRoundIsOver() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

    return Text(
      gm.gameStatus == GameStatus.roundOver
          ? 'Manche terminée!'
          : gm.isNextProblemReady
              ? 'Prochaine manche prête!'
              : 'Temps restant à la manche : ${gm.gameTimer}',
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 26, color: scheme.textColor),
    );
  }
}
