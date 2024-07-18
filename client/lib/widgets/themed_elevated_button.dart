import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/theme_manager.dart';

class ThemedElevatedButton extends StatefulWidget {
  const ThemedElevatedButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.reversedStyle = false,
  });

  final Function()? onPressed;
  final String buttonText;
  final bool reversedStyle;

  @override
  State<ThemedElevatedButton> createState() => _ThemedElevatedButtonState();
}

class _ThemedElevatedButtonState extends State<ThemedElevatedButton> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    late TextStyle textStyle;
    if (widget.reversedStyle) {
      textStyle = tm.buttonTextStyle.copyWith(
          color: tm.elevatedButtonStyle.backgroundColor!
              .resolve({WidgetState.focused}));
    } else {
      textStyle = tm.buttonTextStyle;
    }
    if (widget.onPressed == null) {
      final redGray = (textStyle.color!.red * 1.5).toInt().clamp(200, 245);
      final greenGray = (textStyle.color!.green * 1.5).toInt().clamp(200, 245);
      final blueGray = (textStyle.color!.blue * 1.5).toInt().clamp(200, 245);
      textStyle = textStyle.copyWith(
          color: Color(
              0xFF000000 + redGray * 256 * 256 + greenGray * 256 + blueGray));
    }

    return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 4,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: ElevatedButton(
            onPressed: widget.onPressed,
            style: widget.reversedStyle
                ? tm.elevatedButtonStyle.copyWith(
                    backgroundColor:
                        WidgetStatePropertyAll(tm.buttonTextStyle.color))
                : tm.elevatedButtonStyle,
            child: Text(widget.buttonText, style: textStyle)));
  }
}
