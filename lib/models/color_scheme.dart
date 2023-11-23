import 'package:flutter/material.dart';

class CustomColorScheme {
  // Declare the singleton
  static final CustomColorScheme _instance = CustomColorScheme._internal();
  CustomColorScheme._internal();
  static CustomColorScheme get instance => _instance;

  final textColor = Colors.white;
  final textUnsolvedColor = Colors.white;
  final textSolvedColor = Colors.black;
  final mainColor = Colors.blueGrey;
  final backgroundColorDark = const Color.fromARGB(255, 25, 133, 116);
  final backgroundColorLight = const Color.fromARGB(255, 109, 135, 148);

  final solutionUnsolvedColor = Colors.green[700];
  final solutionSolvedColor = Colors.yellow[600];
  final solutionStealedColor = Colors.red[700];

  final leaderTitleSize = 26.0;
  final leaderTextColor = Colors.white;
  final leaderTextSize = 20.0;
  final leaderStealerColor = Colors.red;

  late final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: CustomColorScheme.instance.textColor,
    foregroundColor: CustomColorScheme.instance.mainColor,
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  );
}
