import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/growing_widget.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class TrainPathController {
  int _nbSteps = 1;
  final List<int> _hallMarks = [];
  final int millisecondsPerStep;

  TrainPathController({required this.millisecondsPerStep});

  set nbSteps(int nbSteps) {
    _currentStep = 0;
    _nbSteps = nbSteps;
    steps = List.generate(_nbSteps, (index) => index / _nbSteps);
  }

  set hallMarks(List<int> hallMarks) {
    nextMoves.clear();
    _controller?.animateTo(1, duration: Duration.zero);
    _isMoving = false;

    _hallMarks.clear();
    _hallMarks.addAll(hallMarks);

    _hallMarks.sort();
    _resetFireworks();
  }

  void _resetFireworks() {
    for (final firework in _fireworksControllers) {
      firework.dispose();
    }
    _fireworksControllers.clear();
    for (final _ in _hallMarks) {
      _fireworksControllers.add(FireworksController(
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
  final List<FireworksController> _fireworksControllers = [];

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
    if (_hallMarks.contains(_currentStep)) {
      _fireworksControllers[_hallMarks.indexOf(_currentStep)].trigger();
      Managers.instance.sound.playTrainReachedStation();
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
    if (_hallMarks.contains(_currentStep + 1)) {
      _fireworksControllers[_hallMarks.indexOf(_currentStep + 1)]
          .triggerReversed();
      Managers.instance.sound.playTrainLostStation();
    }
    if (_refreshCallback != null) _refreshCallback!();
  }

  void dispose() {
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
    final hallmarkSize = widget.height * 0.6;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(width: widget.pathLength + hallmarkSize / 2, height: 0),
        _Rail(
            progressHeight: widget.height * 0.20,
            pathToComeHeight: widget.height * 0.10,
            pathLength: widget.pathLength,
            controller: widget.controller),
        ...widget.controller._hallMarks.map((starPosition) => _Hallmark(
              controller: widget.controller,
              pathLength: widget.pathLength,
              hallmarkSize: hallmarkSize,
              starPosition: starPosition,
            )),
        _Train(
            iconSize: widget.height,
            pathLength: widget.pathLength,
            controller: widget.controller),
        ...widget.controller._hallMarks.asMap().entries.map((e) {
          final index = e.key;
          final starPosition = e.value;
          return _HallmarkFireworks(
            trainController: widget.controller,
            fireworksController: widget.controller._fireworksControllers[index],
            pathLength: widget.pathLength,
            hallmarkSize: widget.height * 0.6,
            starPosition: starPosition,
          );
        }),
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
    required this.starPosition,
    required this.pathLength,
    required this.hallmarkSize,
  });

  final TrainPathController controller;
  final double pathLength;
  final int starPosition;
  final double hallmarkSize;

  @override
  Widget build(BuildContext context) {
    final isSuccess = controller.currentStep > starPosition;
    final color = isSuccess ? Colors.amber : Colors.grey;

    final starWidget = Icon(Icons.star,
        color: color,
        size: hallmarkSize,
        shadows: [
          Shadow(color: color.shade300, blurRadius: hallmarkSize * 0.15)
        ]);

    return Positioned(
        left:
            starPosition * pathLength / controller._nbSteps - hallmarkSize / 2,
        top: hallmarkSize * 0.25,
        child: isSuccess
            ? GrowingWidget(
                growingFactor: 0.9,
                duration: const Duration(milliseconds: 750),
                child: starWidget)
            : starWidget);
  }
}

class _HallmarkFireworks extends StatelessWidget {
  const _HallmarkFireworks({
    required this.trainController,
    required this.fireworksController,
    required this.pathLength,
    required this.starPosition,
    required this.hallmarkSize,
  });

  final TrainPathController trainController;
  final FireworksController fireworksController;
  final double pathLength;
  final int starPosition;
  final double hallmarkSize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: starPosition * pathLength / trainController._nbSteps -
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
