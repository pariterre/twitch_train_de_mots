import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/to_remove/any_dumb_stuff.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_animated_text_overlay.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_header.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_playing_field.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class BlueberryWarGameScreen extends StatefulWidget {
  const BlueberryWarGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<BlueberryWarGameScreen> createState() => _BlueberryWarGameScreenState();
}

class _BlueberryWarGameScreenState extends State<BlueberryWarGameScreen> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.listen(_clockTicked);
  }

  // Dispose
  @override
  void dispose() {
    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.cancel(_clockTicked);

    super.dispose();
  }

  void _clockTicked() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final headerHeight = 88.0;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: headerHeight,
            child: const BlueberryWarHeader(),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            children: [
              SizedBox(height: headerHeight),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gm = Managers.instance.miniGames.blueberryWar;
                    gm.fieldSize = vector_math.Vector2(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return Container(
                      color: Colors.blue.withAlpha(100),
                      width: MediaQuery.of(context).size.width,
                      child: const BlueberryWarPlayingField(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const BluberryWarAnimatedTextOverlay(),
      ],
    );
  }
}
