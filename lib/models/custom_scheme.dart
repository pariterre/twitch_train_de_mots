import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schemeProvider = ChangeNotifierProvider<_CustomScheme>((ref) {
  return _CustomScheme.instance;
});

class _CustomScheme with ChangeNotifier {
  // Declare the singleton
  static final _CustomScheme _instance = _CustomScheme._internal();
  _CustomScheme._internal();
  static _CustomScheme get instance => _instance;

  final textColor = Colors.white;
  final textSize = 26.0;

  final textUnsolvedColor = Colors.white;
  final textSolvedColor = Colors.black;
  Color _mainColor = Colors.blueGrey;
  Color get mainColor => _mainColor;
  set mainColor(Color color) {
    _mainColor = color;
    backgroundColorDark = color;
    backgroundColorLight = Color(color.value.toInt() ~/ 3);
    notifyListeners();
  }

  late Color backgroundColorDark = mainColor;
  late Color backgroundColorLight = Color(mainColor.value.toInt() ~/ 3);

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
    backgroundColor: textColor,
    foregroundColor: mainColor,
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  );
}
