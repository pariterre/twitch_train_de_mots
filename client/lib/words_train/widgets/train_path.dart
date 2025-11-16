import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/growing_widget.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class TrainPathController {
  int _nbSteps = 1;
  final List<int> _starHallMarks = [];
  int _boostHallMarks = -1;
  final int millisecondsPerStep;

  TrainPathController({required this.millisecondsPerStep});

  set nbSteps(int nbSteps) {
    _currentStep = 0;
    _nbSteps = nbSteps;
    steps = List.generate(_nbSteps, (index) => index / _nbSteps);
  }

  set starHallMarks(List<int> hallMarks) {
    nextMoves.clear();
    _controller?.animateTo(1, duration: Duration.zero);
    _isMoving = false;

    _starHallMarks.clear();
    _starHallMarks.addAll(hallMarks);

    _starHallMarks.sort();
    _resetStarFireworks();
  }

  set boostHallMark(int boostHallMark) {
    _boostHallMarks = boostHallMark;
  }

  void _resetStarFireworks() {
    for (final firework in _starFireworksControllers) {
      firework.dispose();
    }
    _starFireworksControllers.clear();
    for (final _ in _starHallMarks) {
      _starFireworksControllers.add(FireworksController(
          minColor: const Color.fromARGB(185, 255, 155, 0),
          maxColor: const Color.fromARGB(185, 255, 255, 50)));
    }
  }

  Function()? _refreshCallback;

  final List<Function()> nextMoves = [];
  int _currentStep = 0;
  int get currentStep => _currentStep;
  bool _isMoving = false;
  bool _reversed = false;
  bool _isStationary = false;
  List<double> steps = [];

  AnimationController? _controller;
  late Animation<double> _animation;
  final List<FireworksController> _starFireworksControllers = [];
  final FireworksController _boostFireworksController = FireworksController(
      minColor: const Color.fromARGB(184, 109, 58, 1),
      maxColor: const Color.fromARGB(184, 255, 145, 0));

  double get position =>
      _reversed ? _getReversedPosition() : _getForwardPosition();

  double _getForwardPosition() {
    final starting = (_currentStep - (_isStationary ? 0 : 1)) / _nbSteps;
    final ending = _currentStep / _nbSteps;
    return starting + (ending - starting) * _animation.value;
  }

  double _getReversedPosition() {
    final starting = (_currentStep + (_isStationary ? 0 : 1)) / _nbSteps;
    final ending = _currentStep / _nbSteps;
    return ending - (ending - starting) * _animation.value;
  }

  void moveForward() {
    nextMoves.add(_moveForward);
    _move();
  }

  void moveBackward() {
    nextMoves.add(_moveBack);
    _move();
  }

  void _move() async {
    if (_isMoving) return;

    _isMoving = true;
    try {
      while (nextMoves.isNotEmpty) {
        final performNext = nextMoves.removeAt(0);
        await performNext();
      }
    } catch (e) {
      // Do nothing, this may happen when the train is reset (race condition)
    }
    _isMoving = false;
  }

  Future<void> _moveForward() async {
    _isStationary = false;

    _currentStep++;
    if (_currentStep > _nbSteps) {
      _currentStep = _nbSteps;
      _isStationary = true;
    }

    _reversed = false;
    await _controller?.forward(from: 0.0);
    if (_starHallMarks.contains(_currentStep)) {
      _starFireworksControllers[_starHallMarks.indexOf(_currentStep)].trigger();
      Managers.instance.sound.playTrainReachedStation();
    }

    final gm = Managers.instance.train;
    if (!gm.boostWasGrantedThisRound && _boostHallMarks == _currentStep) {
      _boostFireworksController.trigger();
    }

    if (_refreshCallback != null) _refreshCallback!();
  }

  Future<void> _moveBack() async {
    _isStationary = false;

    _currentStep--;
    if (_currentStep < 0) {
      _currentStep = 0;
      _isStationary = true;
    }

    _reversed = true;
    await _controller?.reverse(from: 1.0);
    if (_starHallMarks.contains(_currentStep + 1)) {
      _starFireworksControllers[_starHallMarks.indexOf(_currentStep + 1)]
          .triggerReversed();
      Managers.instance.sound.playTrainLostStation();
    }
    if (_refreshCallback != null) _refreshCallback!();
  }

  void dispose() {
    for (final firework in _starFireworksControllers) {
      firework.dispose();
    }
    _boostFireworksController.dispose();
    _controller?.dispose();
  }

  void _initialize(
    TickerProvider provider, {
    required Function() refreshCallback,
  }) {
    _controller = AnimationController(
        vsync: provider, duration: Duration(milliseconds: millisecondsPerStep));
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.linear,
    );
    _controller?.animateTo(1, duration: Duration.zero);

    _refreshCallback = refreshCallback;
  }
}

class TrainPath extends StatefulWidget {
  const TrainPath({
    super.key,
    required this.controller,
    required this.pathLength,
    required this.height,
  });

  final TrainPathController controller;
  final double height;
  final double pathLength;

  @override
  State<TrainPath> createState() => _TrainPathState();
}

class _TrainPathState extends State<TrainPath>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    widget.controller._initialize(this, refreshCallback: () => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final hallmarkSize = widget.height * 0.6;
    final boostSize = hallmarkSize * 3 / 4;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(width: widget.pathLength + hallmarkSize / 2, height: 0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _Rail(
              progressHeight: widget.height * 0.20,
              pathToComeHeight: widget.height * 0.10,
              pathLength: widget.pathLength,
              controller: widget.controller),
        ),
        ...widget.controller._starHallMarks.map((starPosition) {
          final starColor = widget.controller.currentStep > starPosition
              ? Colors.amber
              : Colors.grey;
          return _Hallmark(
            controller: widget.controller,
            icon: Icon(Icons.star,
                color: starColor,
                size: hallmarkSize,
                shadows: [
                  Shadow(
                      color: starColor.shade300,
                      blurRadius: hallmarkSize * 0.15)
                ]),
            pathLength: widget.pathLength,
            hallmarkSize: hallmarkSize,
            hallmarkPosition: starPosition,
          );
        }),
        if (!gm.boostWasGrantedThisRound)
          _Hallmark(
            icon: Icon(Icons.bolt_sharp,
                size: boostSize,
                color: Colors.amber,
                shadows: [
                  Shadow(
                      color: Colors.amber.shade300,
                      blurRadius: boostSize * 0.15)
                ]),
            controller: widget.controller,
            pathLength: widget.pathLength,
            hallmarkSize: boostSize,
            hallmarkPosition: widget.controller._boostHallMarks,
          ),
        _Train(
            iconSize: widget.height,
            pathLength: widget.pathLength,
            controller: widget.controller),
        ...widget.controller._starHallMarks.asMap().entries.map((e) {
          final index = e.key;
          final starPosition = e.value;
          return _HallmarkFireworks(
            trainController: widget.controller,
            fireworksController:
                widget.controller._starFireworksControllers[index],
            pathLength: widget.pathLength,
            hallmarkSize: widget.height * 0.6,
            hallmarkPosition: starPosition,
          );
        }),
        _HallmarkFireworks(
          trainController: widget.controller,
          fireworksController: widget.controller._boostFireworksController,
          pathLength: widget.pathLength,
          hallmarkSize: widget.height * 0.6,
          hallmarkPosition: widget.controller._boostHallMarks,
        )
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.controller,
    required this.progressHeight,
    required this.pathToComeHeight,
    required this.pathLength,
  });

  final TrainPathController controller;
  final double progressHeight;
  final double pathToComeHeight;
  final double pathLength;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return AnimatedBuilder(
        animation: controller._animation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tm.backgroundColorDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                ),
                height: progressHeight,
                width: pathLength * controller.position,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.grey, // Set the color of the rail
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                ),
                height: pathToComeHeight,
                width: pathLength * (1 - controller.position),
              ),
            ],
          );
        });
  }
}

class _Hallmark extends StatelessWidget {
  const _Hallmark({
    required this.controller,
    required this.icon,
    required this.hallmarkPosition,
    required this.pathLength,
    required this.hallmarkSize,
  });

  final TrainPathController controller;
  final Icon icon;
  final double pathLength;
  final int hallmarkPosition;
  final double hallmarkSize;

  @override
  Widget build(BuildContext context) {
    final isSuccess = controller.currentStep > hallmarkPosition;

    return Positioned(
        left: hallmarkPosition * pathLength / controller._nbSteps -
            hallmarkSize / 2,
        top: hallmarkSize * 0.25,
        child: isSuccess
            ? GrowingWidget(
                growingFactor: 0.9,
                duration: const Duration(milliseconds: 750),
                child: icon)
            : icon);
  }
}

class _HallmarkFireworks extends StatelessWidget {
  const _HallmarkFireworks({
    required this.trainController,
    required this.fireworksController,
    required this.pathLength,
    required this.hallmarkPosition,
    required this.hallmarkSize,
  });

  final TrainPathController trainController;
  final FireworksController fireworksController;
  final double pathLength;
  final int hallmarkPosition;
  final double hallmarkSize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: hallmarkPosition * pathLength / trainController._nbSteps -
            hallmarkSize / 2,
        top: hallmarkSize * 0.25,
        child: SizedBox(
            width: hallmarkSize,
            height: hallmarkSize,
            child: Fireworks(controller: fireworksController)));
  }
}

class _Train extends StatelessWidget {
  const _Train({
    required this.controller,
    required this.iconSize,
    required this.pathLength,
  });

  final TrainPathController controller;
  final double iconSize;
  final double pathLength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller._animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(controller.position * pathLength + iconSize * 0.5,
              -iconSize * 0.1),
          child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              width: iconSize,
              height: iconSize,
              padding: EdgeInsets.all(iconSize / 10),
              transform: Transform.flip(flipX: true).transform,
              child: GrowingWidget(
                growingFactor: 0.97,
                duration: const Duration(milliseconds: 1500),
                child: Image.asset('packages/common/assets/images/train.png',
                    opacity: const AlwaysStoppedAnimation(0.9)),
              )),
        );
      },
    );
  }
}
