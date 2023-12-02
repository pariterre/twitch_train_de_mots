import 'package:flutter/material.dart';

class BouncyContainerController {
  final int bounceCount;
  final int easingInDuration;
  final int bouncingDuration;
  final int easingOutDuration;
  final double minScale;
  final double bouncyScale;
  final double maxScale;
  final double maxOpacity;

  BouncyContainerController({
    this.bounceCount = 3,
    this.easingInDuration = 400,
    this.bouncingDuration = 500,
    this.easingOutDuration = 300,
    this.minScale = 0.5,
    this.bouncyScale = 0.9,
    this.maxScale = 1.0,
    this.maxOpacity = 1.0,
  });

  void dispose() {
    _triggerAnimation = null;
  }

  Function(Widget child)? _triggerAnimation;
  void triggerAnimation(Widget child) {
    child = child;
    if (_triggerAnimation == null) throw Exception('Not initialized');
    _triggerAnimation!(child);
  }
}

class _BouncyContainerCollection {
  final TickerProvider vsync;
  final BouncyContainerController controller;
  final Widget child;

  late AnimationController currentController = appearingController;
  late Animation<double> currentAnimation = appearingAnimation;

  late final appearingController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: controller.easingInDuration));
  late final appearingAnimation = Tween<double>(
          begin: controller.minScale, end: controller.maxScale)
      .animate(
          CurvedAnimation(parent: appearingController, curve: Curves.easeOut));

  late final bouncingController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: controller.bouncingDuration ~/ 2));
  late final bouncingAnimation = Tween<double>(
          begin: controller.maxScale, end: controller.bouncyScale)
      .animate(
          CurvedAnimation(parent: bouncingController, curve: Curves.easeInOut));

  late final disapearingController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: controller.easingOutDuration));
  late final disapearingScale =
      Tween<double>(begin: controller.maxScale, end: controller.minScale)
          .animate(CurvedAnimation(
              parent: disapearingController, curve: Curves.easeInOut));

  double get opacity {
    if (currentController == appearingController) {
      return appearingController.value * controller.maxOpacity;
    } else if (currentController == bouncingController) {
      return controller.maxOpacity;
    } else if (currentController == disapearingController) {
      return (1.0 - disapearingController.value) * controller.maxOpacity;
    } else {
      throw Exception('Unknown controller');
    }
  }

  double get scale {
    if (currentController == appearingController) {
      return appearingAnimation.value;
    } else if (currentController == bouncingController) {
      return bouncingAnimation.value;
    } else if (currentController == disapearingController) {
      return disapearingScale.value;
    } else {
      throw Exception('Unknown controller');
    }
  }

  Animation<double> get animation => currentAnimation;

  ///
  /// Main constructor
  _BouncyContainerCollection(
      {required this.vsync, required this.controller, required this.child});

  ///
  /// Perform the animation
  Future<void> _performAnimation(
      {required Function() onControllerChanged}) async {
    currentAnimation = appearingAnimation;
    currentController = appearingController;
    onControllerChanged();
    await appearingController.forward();

    currentAnimation = bouncingAnimation;
    currentController = bouncingController;
    onControllerChanged();
    for (var i = 0; i < controller.bounceCount; i++) {
      await bouncingController.forward();
      await bouncingController.reverse();
    }

    currentAnimation = disapearingScale;
    currentController = disapearingController;
    onControllerChanged();
    await disapearingController.forward();
  }

  ///
  /// Dispose the animation
  void dispose() {
    appearingController.dispose();
    bouncingController.dispose();
    disapearingController.dispose();
  }
}

class BouncyContainer extends StatefulWidget {
  const BouncyContainer({super.key, required this.controller});

  final BouncyContainerController controller;

  @override
  State<BouncyContainer> createState() => _BouncyContainerState();
}

class _BouncyContainerState extends State<BouncyContainer>
    with TickerProviderStateMixin {
  final List<_BouncyContainerCollection> _animationControllers = [];

  @override
  void initState() {
    super.initState();
    widget.controller._triggerAnimation = _showContainer;
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showContainer(Widget child) async {
    // Prepare all the controllers for the animation
    final controllers = _BouncyContainerCollection(
        vsync: this, controller: widget.controller, child: child);
    _animationControllers.add(controllers);
    setState(() {});

    // Run the appearing animation
    await controllers._performAnimation(
        onControllerChanged: () => setState(() {}));

    // Delete the congratulation message
    _animationControllers.remove(controllers);
    setState(() {});
    controllers.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final controllers in _animationControllers)
          Center(
            child: AnimatedBuilder(
              animation: controllers.animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: controllers.animation.value,
                  child: Opacity(
                    opacity: controllers.opacity,
                    child: child!,
                  ),
                );
              },
              child: controllers.child,
            ),
          ),
      ],
    );
  }
}
