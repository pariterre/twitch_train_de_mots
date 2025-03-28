import 'dart:async';
import 'dart:math';

import 'package:common/widgets/bouncy_container.dart';
import 'package:common/widgets/fireworks.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class CongratulationLayer extends StatefulWidget {
  const CongratulationLayer(
      {super.key,
      this.maxFireworksCount = 10,
      this.duration = const Duration(seconds: 8)});

  final int maxFireworksCount;
  final Duration duration;

  @override
  State<CongratulationLayer> createState() => _CongratulationLayerState();
}

class _CongratulationLayerState extends State<CongratulationLayer> {
  final _congratulationMessageController = BouncyContainerController(
      bounceCount: 10,
      easingInDuration: 600,
      bouncingDuration: 1100,
      easingOutDuration: 300,
      minScale: 0.9,
      bouncyScale: 1.0,
      maxScale: 1.1,
      maxOpacity: 0.9);
  final _fireworksController = <FireworksController>[];
  final _positions = <Offset>[];
  bool _isFiring = false;

  @override
  void initState() {
    super.initState();

    final random = Random();
    for (var i = 0; i < widget.maxFireworksCount; i++) {
      // Randomize the fireworks color
      _positions
          .add(Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5));

      _fireworksController.add(FireworksController(
          isHuge: true,
          minColor: const Color.fromARGB(100, 50, 50, 50),
          maxColor: const Color.fromARGB(255, 250, 250, 250),
          explodeOnTap: false));
    }

    Managers.instance.train.onCongratulationFireworks.listen(_launchFireworks);
  }

  @override
  void dispose() {
    Managers.instance.train.onCongratulationFireworks.cancel(_launchFireworks);
    for (var e in _fireworksController) {
      e.dispose();
    }
    _congratulationMessageController.dispose();
    super.dispose();
  }

  void _launchFireworks(Map<String, dynamic> info) {
    bool isCongratulating = (info['is_congratulating'] as bool?) ?? false;
    if (!isCongratulating) return;

    final now = DateTime.now();
    setState(() => _isFiring = true);

    _congratulationMessageController.triggerAnimation(_CongratulationMessage(
        congratulerName: info['player_name'] ?? 'Anonymous'));

    Random random = Random();
    for (int i = 0; i < widget.maxFireworksCount; i++) {
      Future.delayed(Duration(milliseconds: random.nextInt(1000))).then((_) {
        _fireworksController[i].trigger();
        Managers.instance.sound.playFireworks();
      });

      Timer.periodic(Duration(milliseconds: 1000 + random.nextInt(5000)),
          (timer) {
        if (DateTime.now().difference(now) > widget.duration) {
          timer.cancel();
        }
        _fireworksController[i].trigger();
        Managers.instance.sound.playFireworks();
        _positions[i] =
            Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5);
      });
    }

    Future.delayed(widget.duration + const Duration(milliseconds: 6000))
        .then((_) => setState(() {
              _isFiring = false;
              Managers.instance.train.onCongratulationFireworks.notifyListeners(
                  (callback) => callback({'is_congratulating': false}));
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      if (_isFiring)
        ..._fireworksController.asMap().keys.map((index) {
          return Positioned(
            bottom: -_positions[index].dy * MediaQuery.of(context).size.height,
            top: _positions[index].dy * MediaQuery.of(context).size.height,
            left: -_positions[index].dx * MediaQuery.of(context).size.width,
            right: _positions[index].dx * MediaQuery.of(context).size.width,
            child: Fireworks(
              controller: _fireworksController[index],
            ),
          );
        }),
      BouncyContainer(controller: _congratulationMessageController),
    ]);
  }
}

class _CongratulationMessage extends StatelessWidget {
  const _CongratulationMessage({required this.congratulerName});

  final String congratulerName;

  @override
  Widget build(BuildContext context) {
    final tm = Managers.instance.theme;

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
          Row(
            children: [
              Text(
                congratulerName,
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 157, 243, 151)),
              ),
              Text(
                ' nous félicite de notre magnifique travail d\'équipe!',
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: const Color.fromARGB(255, 157, 243, 151)),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star, color: Colors.amber, size: 32),
        ],
      ),
    );
  }
}
