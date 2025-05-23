import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';

class AnimationOverlay extends StatefulWidget {
  const AnimationOverlay({super.key});

  @override
  State<AnimationOverlay> createState() => _AnimationOverlayState();
}

class _AnimationOverlayState extends State<AnimationOverlay> {
  final _pardonedController = BouncyContainerController(
      bounceCount: 1,
      easingInDuration: 700,
      bouncingDuration: 3000,
      easingOutDuration: 300,
      minScale: 0.5,
      bouncyScale: 1.4,
      maxScale: 1.5,
      maxOpacity: 0.9);
  final _trainGotBoostedController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);
  final _changeLaneController = BouncyContainerController(
      bounceCount: 2,
      easingInDuration: 600,
      bouncingDuration: 1500,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.2,
      maxScale: 1.4,
      maxOpacity: 0.9);

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onPardonGranted.listen(_showStealerWasPardoned);
    gm.onBoostGranted.listen(_showTrainGotBoosted);
    gm.onChangeLaneGranted.listen(_showChangeLane);
  }

  @override
  void dispose() {
    _pardonedController.dispose();
    _trainGotBoostedController.dispose();

    final gm = GameManager.instance;
    gm.onPardonGranted.cancel(_showStealerWasPardoned);
    gm.onBoostGranted.cancel(_showTrainGotBoosted);
    gm.onChangeLaneGranted.cancel(_showChangeLane);

    super.dispose();
  }

  void _showStealerWasPardoned(bool isPardonned) {
    _pardonedController.triggerAnimation(const _StealerWasPardoned());
  }

  void _showTrainGotBoosted(bool isBoosted) {
    if (!isBoosted) return;
    _trainGotBoostedController.triggerAnimation(const _TrainGotBoosted());
  }

  void _showChangeLane(bool isChangeLane) {
    if (!isChangeLane) return;
    _changeLaneController.triggerAnimation(const _ChangeLane());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: constraints.maxHeight * 0.15,
            child: Transform.scale(
                scale: constraints.maxWidth / 800,
                child: BouncyContainer(controller: _pardonedController)),
          ),
          Positioned(
            top: constraints.maxHeight * 0.15,
            child: Transform.scale(
                scale: constraints.maxWidth / 800,
                child: BouncyContainer(controller: _trainGotBoostedController)),
          ),
          Positioned(
            top: constraints.maxHeight * 0.15,
            child: Transform.scale(
                scale: constraints.maxWidth / 800,
                child: BouncyContainer(controller: _changeLaneController)),
          ),
        ],
      );
    });
  }
}

class _StealerWasPardoned extends StatelessWidget {
  const _StealerWasPardoned();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    const textColor = Color.fromARGB(255, 237, 243, 151);
    const text = 'Vous avez pardonné!';

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 91, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: textColor, size: 32),
          const SizedBox(width: 10),
          Text(
            text,
            style: tm.textFrontendSc.copyWith(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: textColor, size: 32),
        ],
      ),
    );
  }
}

class _TrainGotBoosted extends StatelessWidget {
  const _TrainGotBoosted();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 10),
          Text(
            'Vous avez boosté le train!',
            style: tm.textFrontendSc.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 157, 243, 151)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}

class _ChangeLane extends StatelessWidget {
  const _ChangeLane();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 10),
          Text(
            'Changement de voie!',
            style: tm.textFrontendSc.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 157, 243, 151)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}
