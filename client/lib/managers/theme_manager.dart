import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';

const _textSizeDefault = 20.0;
const _mainColorDefault = Color.fromARGB(255, 0, 0, 95);

class ThemeManager {
  // Declare the singleton
  static ThemeManager? _instance;
  ThemeManager._internal() {
    _updateBackgroundColors();
    _load();
  }
  static ThemeManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'ThemeManager must be initialized before being used');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'ThemeManager should not be initialized twice');
    }
    ThemeManager._instance = ThemeManager._internal();
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = CustomCallback();

  final textColor = Colors.white;
  double _textSize = _textSizeDefault;
  double get textSize => _textSize;
  set textSize(double size) {
    _textSize = size;
    _updateLeaderTextSizes();
    _save();
  }

  final titleSize = 32.0;

  final textUnsolvedColor = const Color.fromARGB(255, 243, 253, 206);
  final textSolvedColor = Colors.black;
  Color _mainColor = _mainColorDefault;
  Color get mainColor => _mainColor;
  set mainColor(Color color) {
    _mainColor = color;
    _updateBackgroundColors();
    _save();
  }

  late Color _backgroundColorDark;
  Color get backgroundColorDark => _backgroundColorDark;
  late Color _backgroundColorLight;
  Color get backgroundColorLight => _backgroundColorLight;
  void _updateBackgroundColors() {
    final darkRed = min(mainColor.red, 100);
    final darkGreen = min(mainColor.green, 100);
    final darkBlue = min(mainColor.blue, 100);
    _backgroundColorDark =
        Color(0xFF000000 + darkRed * 0x10000 + darkGreen * 0x100 + darkBlue);

    final red = max(mainColor.red, 150);
    final green = max(mainColor.green, 150);
    final blue = max(mainColor.blue, 150);
    _backgroundColorLight =
        Color(0xFF000000 + red * 0x10000 + green * 0x100 + blue);
  }

  final solutionUnsolvedColorLight = Colors.green[200];
  final solutionUnsolvedColorDark = Colors.green[700];

  final solutionSolvedColorLight = Colors.yellow[100];
  final solutionSolvedColorDark = Colors.yellow[800];

  final solutionSolvedByMvpColorLight =
      const Color.fromARGB(255, 255, 231, 196);
  final solutionSolvedByMvpColorDark = const Color.fromARGB(255, 131, 74, 1);

  final solutionStolenColorLight = Colors.red[200];
  final solutionStolenColorDark = Colors.red[700];

  final letterColorLight = const Color.fromARGB(255, 247, 217, 127);
  final letterColorDark = const Color.fromARGB(255, 200, 150, 0);
  final uselessLetterColorLight = const Color.fromARGB(255, 255, 140, 111);
  final uselessLetterColorDark = const Color.fromARGB(255, 201, 57, 0);
  final hiddenLetterColorLight = const Color.fromARGB(255, 111, 221, 255);
  final hiddenLetterColorDark = const Color.fromARGB(255, 0, 137, 201);

  double _leaderTitleSize = 26.0;
  double get leaderTitleSize => _leaderTitleSize;
  double _leaderTextSize = 20.0;
  double get leaderTextSize => _leaderTextSize;
  void _updateLeaderTextSizes() {
    _leaderTitleSize = _textSize;
    _leaderTextSize = _textSize * 0.75;
    _save();
  }

  final leaderTextColor = Colors.white;
  final leaderStealerColor = Colors.red;

  late final buttonTextStyle = TextStyle(
      color: backgroundColorDark, fontSize: 20, fontWeight: FontWeight.bold);
  late final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: textColor,
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  );

  void _save() async {
    onChanged.notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('customScheme', jsonEncode(serialize()));
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customScheme');
    if (data != null) {
      final map = jsonDecode(data);
      _textSize = map['textSize'] ?? _textSizeDefault;
      _updateLeaderTextSizes();

      _mainColor = Color(map['mainColor'] ?? _mainColorDefault.value);
      _updateBackgroundColors();
    }
    onChanged.notifyListeners();
  }

  void reset() {
    _textSize = _textSizeDefault;
    _mainColor = _mainColorDefault;

    _updateBackgroundColors();
    _save();
  }

  Map<String, dynamic> serialize() => {
        'textSize': _textSize,
        'mainColor': _mainColor.value,
      };
}
