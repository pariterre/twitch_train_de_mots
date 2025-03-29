import 'package:common/models/game_status.dart';
import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/screens/dragging_screen.dart';
import 'package:frontend_common/screens/non_authorized_screen.dart';
import 'package:frontend_common/screens/play_screen.dart';
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
  late bool _shouldHide = widget.canBeHidden;

  void _reloadOnConnection() {
    TwitchManager.instance.frontendManager.authenticator.onHasConnected
        .cancel(_reloadOnConnection);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    GameManager.instance.onGameStatusUpdated.listen(_toggleVisibility);
  }

  @override
  void dispose() {
    GameManager.instance.onGameStatusUpdated.cancel(_toggleVisibility);

    super.dispose();
  }

  void _toggleVisibility() {
    final gm = GameManager.instance;
    final shouldHide = gm.status == WordsTrainGameStatus.uninitialized ||
        !gm.shouldShowExtension;

    // Check for the nothing-to-do cases
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
          : Size(MediaQuery.of(context).size.width * 0.2,
              MediaQuery.of(context).size.width * 0.22),
      child: FutureBuilder(
          future: TwitchManager.instance.onInitialized,
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
  const _MainWindow({required this.initialSize, required this.child});

  final Size? initialSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mainWidget = _MainContainer(child: child);
    const draggingWidget = _MainContainer(child: DraggingScreen());

    return initialSize == null
        ? mainWidget
        : ResizedBox(
            initialTop: MediaQuery.of(context).size.height * 0.5,
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
          'assets/images/train.png',
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
    return GameManager.instance.isRoundRunning
        ? const PlayScreen()
        : const WaitingScreen();
  }
}
