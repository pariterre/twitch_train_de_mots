import 'dart:convert';
import 'dart:math';

import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('ThemeManager');
const _textSizeDefault = 20.0;
const _mainColorDefault = Color.fromARGB(255, 0, 0, 95);

class ThemeManager {
  // Declare the singleton
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;

  ThemeManager._() {
    _logger.config('Initializing...');
    _load();
    _updateBackgroundColors();
    _logger.config('Ready');
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = GenericListener<Function()>();

  final textColor = Colors.white;
  double _textSize = _textSizeDefault;
  double get textSize => _textSize;
  set textSize(double size) {
    _textSize = size;
    _updateLeaderTextSizes();
    _save();
  }

  late final clientMainTextStyle = TextStyle().copyWith(
      fontFamily: 'BaskervvilleSC',
      color: textColor,
      fontSize: textSize,
      package: 'common');
  late final textFrontendSc = TextStyle().copyWith(
      fontFamily: 'BaskervvilleSC',
      fontFeatures: [FontFeature.enable('smcp')],
      color: textColor,
      fontSize: textSize,
      package: 'common');

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
    final darkRed = min(mainColor.r, 0.39);
    final darkGreen = min(mainColor.g, 0.39);
    final darkBlue = min(mainColor.b, 0.39);
    _backgroundColorDark =
        Color.from(red: darkRed, green: darkGreen, blue: darkBlue, alpha: 1.0);

    final red = max(mainColor.r, 0.58);
    final green = max(mainColor.g, 0.58);
    final blue = max(mainColor.b, 0.58);
    _backgroundColorLight =
        Color.from(red: red, green: green, blue: blue, alpha: 1.0);
  }

  final solutionUnsolvedColorLight = Colors.green[200];
  final solutionUnsolvedColorDark = Colors.green[700];

  final solutionSolvedColorLight = Colors.yellow[100];
  final solutionSolvedColorDark = Colors.yellow[800];

  final solutionIsGoldenLight = const Color.fromARGB(255, 255, 241, 117);
  final solutionIsGoldenDark = const Color.fromARGB(255, 114, 90, 39);

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

  final leaderBoardBestScoreColor = Colors.amber;
  late final leaderBoardBestSartsColor =
      const Color.fromARGB(255, 230, 217, 181);
  final leaderBoardBiggestStealerColor =
      const Color.fromARGB(255, 255, 200, 200);

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

  late final buttonTextStyle = textFrontendSc.copyWith(
      color: backgroundColorDark, fontSize: 20, fontWeight: FontWeight.bold);
  late final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: textColor,
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  );

  Future<void> _save() async {
    _logger.info('Saving custom scheme');
    onChanged.notifyListeners((callback) => callback());

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('customScheme', jsonEncode(serialize()));
  }

  Future<void> _load() async {
    _logger.info('Loading custom scheme');

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customScheme');
    if (data != null) {
      final map = jsonDecode(data);
      _textSize = map['textSize'] ?? _textSizeDefault;
      _updateLeaderTextSizes();

      if (map['mainColor'] == null) {
        _mainColor = _mainColorDefault;
      } else {
        if (map['mainColor'] is int) {
          _mainColor = Color(map['mainColor']);
        } else if (map['mainColor'] is Map) {
          _mainColor = Color.from(
            red: map['mainColor']['r'],
            green: map['mainColor']['g'],
            blue: map['mainColor']['b'],
            alpha: map['mainColor']['a'],
          );
        } else {
          _logger.warning('Invalid mainColor format: ${map['mainColor']}, '
              'using default value');
          _mainColor = _mainColorDefault;
        }
      }

      _updateBackgroundColors();
    }
    onChanged.notifyListeners((callback) => callback());
  }

  void reset() {
    _logger.info('Resetting custom scheme');
    _textSize = _textSizeDefault;
    _mainColor = _mainColorDefault;

    _updateBackgroundColors();
    _save();
  }

  Map<String, dynamic> serialize() => {
        'textSize': _textSize,
        'mainColor': {
          'r': _mainColor.r,
          'g': _mainColor.g,
          'b': _mainColor.b,
          'a': _mainColor.a
        }
      };
}
