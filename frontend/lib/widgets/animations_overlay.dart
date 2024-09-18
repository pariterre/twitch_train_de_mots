import 'package:common/widgets/bouncy_container.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';

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

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onPardonGranted.addListener(_showStealerWasPardoned);
    gm.onBoostGranted.addListener(_showTrainGotBoosted);
  }

  @override
  void dispose() {
    _pardonedController.dispose();
    _trainGotBoostedController.dispose();

    final gm = GameManager.instance;
    gm.onPardonGranted.removeListener(_showStealerWasPardoned);
    gm.onBoostGranted.removeListener(_showTrainGotBoosted);

    super.dispose();
  }

  void _showStealerWasPardoned(bool isPardonned) {
    _pardonedController.triggerAnimation(const _StealerWasPardoned());
  }

  void _showTrainGotBoosted(bool isBoosted) {
    if (!isBoosted) return;
    _trainGotBoostedController.triggerAnimation(const _TrainGotBoosted());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.065,
            child: Transform.scale(
                scale: 0.5,
                child: BouncyContainer(controller: _pardonedController)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.065,
            child: Transform.scale(
                scale: 0.5,
                child: BouncyContainer(controller: _trainGotBoostedController)),
          ),
        ],
      ),
    );
  }
}

class _StealerWasPardoned extends StatelessWidget {
  const _StealerWasPardoned();

  @override
  Widget build(BuildContext context) {
    const textColor = Color.fromARGB(255, 237, 243, 151);
    const text = 'Vous avez pardonné!';

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 91, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: textColor, size: 32),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          SizedBox(width: 10),
          Icon(Icons.star, color: textColor, size: 32),
        ],
      ),
    );
  }
}

class _TrainGotBoosted extends StatelessWidget {
  const _TrainGotBoosted();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 23, 99, 18),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 32),
          SizedBox(width: 10),
          Text(
            'Vous avez boosté le train!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 157, 243, 151)),
          ),
          SizedBox(width: 10),
          Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}
