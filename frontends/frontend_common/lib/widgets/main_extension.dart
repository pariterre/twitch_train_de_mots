import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/screens/blueberry_war_play_screen.dart';
import 'package:frontend_common/screens/dragging_screen.dart';
import 'package:frontend_common/screens/non_authorized_screen.dart';
import 'package:frontend_common/screens/play_screen.dart';
import 'package:frontend_common/screens/treasure_hunt_play_screen.dart';
import 'package:frontend_common/screens/waiting_screen.dart';
import 'package:frontend_common/widgets/opaque_on_hover.dart';
import 'package:frontend_common/widgets/resized_box.dart';

class MainExtension extends StatefulWidget {
  const MainExtension({
    super.key,
    required this.isFullScreen,
    required this.alwaysOpaque,
    required this.canBeHidden,
  });

  final bool isFullScreen;
  final bool alwaysOpaque;
  final bool canBeHidden;

  @override
  State<MainExtension> createState() => _MainExtensionState();
}

class _MainExtensionState extends State<MainExtension> {
  final boxSizeController = ResizedBoxController();
  late bool _shouldHide = widget.canBeHidden;

  void _reloadOnConnection() {
    TwitchManager.instance.frontendManager.authenticator.onHasConnected
        .cancel(_reloadOnConnection);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onGameStatusUpdated.listen(_updateStatus);
  }

  @override
  void dispose() {
    GameManager.instance.onGameStatusUpdated.cancel(_updateStatus);

    super.dispose();
  }

  void _updateStatus() {
    // Check if we should hide the extension
    final gm = GameManager.instance;

    double sizeFactor = 1.2;
    if (gm.status == WordsTrainGameStatus.miniGameStarted &&
        boxSizeController.factor != sizeFactor) {
      setState(() {
        boxSizeController.factor = sizeFactor;
      });
    } else if (gm.status != WordsTrainGameStatus.miniGameStarted &&
        boxSizeController.factor == sizeFactor) {
      setState(() {
        boxSizeController.factor = 1 / sizeFactor;
      });
    }

    // If the status hasn't changed, do nothing
    final shouldHide = gm.status == WordsTrainGameStatus.uninitialized ||
        !gm.shouldShowExtension;
    if (shouldHide == _shouldHide) return;

    setState(() {
      _shouldHide = shouldHide;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainWidget = _MainWindow(
      initialSize: (widget.isFullScreen)
          ? null
          : Size(MediaQuery.of(context).size.width * 0.20,
              MediaQuery.of(context).size.width * 0.30),
      boxSizeController: boxSizeController,
      child: FutureBuilder(
          future: TwitchManager.instance.onHasInitialized,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!TwitchManager.instance.userHasGrantedIdAccess) {
              if (TwitchManager.instance is! TwitchManagerMock) {
                TwitchManager
                    .instance.frontendManager.authenticator.onHasConnected
                    .listen(_reloadOnConnection);
              }
              return const NonAuthorizedScreen();
            }

            return const _MainScreen();
          }),
    );

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.canBeHidden && _shouldHide
            ? null
            : widget.alwaysOpaque
                ? mainWidget
                : OpaqueOnHover(
                    opacityMin: GameManager.instance.isRoundRunning ? 0.1 : 0.5,
                    opacityMax: 1.0,
                    child: mainWidget,
                  ),
      ),
    );
  }
}

class _MainWindow extends StatelessWidget {
  const _MainWindow(
      {required this.initialSize,
      required this.boxSizeController,
      required this.child});

  final ResizedBoxController? boxSizeController;
  final Size? initialSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mainWidget = _MainContainer(child: child);
    const draggingWidget = _MainContainer(child: DraggingScreen());

    return initialSize == null
        ? mainWidget
        : ResizedBox(
            sizeController: boxSizeController,
            initialTop: MediaQuery.of(context).size.height * 0.1,
            minTop: 0,
            maxTop: MediaQuery.of(context).size.height - 50,
            initialLeft: 20,
            minLeft: 0,
            maxLeft: MediaQuery.of(context).size.width - 50,
            initialWidth: initialSize!.width,
            initialHeight: initialSize!.height,
            borderWidth: 2,
            draggingChild: draggingWidget,
            preserveAspectRatio: true,
            decoration: const BoxDecoration(color: Colors.black),
            child: mainWidget,
          );
  }
}

class _MainContainer extends StatelessWidget {
  const _MainContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Background(
      backgroundLayer: Opacity(
        opacity: 0.05,
        child: Image.asset(
          'packages/common/assets/images/train.png',
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

class _MainScreen extends StatefulWidget {
  const _MainScreen();

  @override
  State<_MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreen> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onGameStatusUpdated.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onGameStatusUpdated.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    switch (GameManager.instance.status) {
      case WordsTrainGameStatus.uninitialized:
      case WordsTrainGameStatus.initializing:
      case WordsTrainGameStatus.roundPreparing:
      case WordsTrainGameStatus.roundReady:
      case WordsTrainGameStatus.roundEnding:
        return const WaitingScreen();
      case WordsTrainGameStatus.roundStarted:
        return const PlayScreen();
      case WordsTrainGameStatus.miniGamePreparing:
      case WordsTrainGameStatus.miniGameReady:
      case WordsTrainGameStatus.miniGameEnding:
        return const WaitingScreen();
      case WordsTrainGameStatus.miniGameStarted:
        {
          switch (GameManager.instance.currentMiniGameType!) {
            case MiniGames.treasureHunt:
              return const TreasureHuntPlayScreen();
            case MiniGames.blueberryWar:
              return const BlueberryWarPlayScreen();
          }
        }
    }
  }
}
