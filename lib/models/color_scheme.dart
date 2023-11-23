import 'package:flutter/material.dart';

class CustomColorScheme {
  // Declare the singleton
  static final CustomColorScheme _instance = CustomColorScheme._internal();
  CustomColorScheme._internal();
  static CustomColorScheme get instance => _instance;

  final textColor = Colors.white;
  final textSize = 26.0;

  final textUnsolvedColor = Colors.white;
  final textSolvedColor = Colors.black;
  final mainColor = Colors.blueGrey;

  final backgroundColorDark = const Color.fromARGB(255, 3, 77, 66);
  final backgroundColorLight = const Color.fromARGB(255, 195, 200, 202);

  final solutionUnsolvedColorLight = Colors.green[200];
  final solutionUnsolvedColorDark = Colors.green[700];

  final solutionSolvedColorLight = Colors.yellow[100];
  final solutionSolvedColorDark = Colors.yellow[800];

  final solutionStolenColorLight = Colors.red[200];
  final solutionStolenColorDark = Colors.red[700];

  final letterColorLight = const Color.fromARGB(255, 247, 217, 127);
  final letterColorDark = const Color.fromARGB(255, 200, 150, 0);

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
