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
  final backgroundColor = Colors.teal[900];
  final solutionUnsolvedBackgroundColor = Colors.green[700];
  final solutionSolvedBackgroundColor = Colors.yellow[600];
}
