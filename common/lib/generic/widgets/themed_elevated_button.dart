import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';

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
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

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
      final redGray = (textStyle.color!.r * 1.5).clamp(0.78, 0.96);
      final greenGray = (textStyle.color!.g * 1.5).clamp(0.78, 0.96);
      final blueGray = (textStyle.color!.b * 1.5).clamp(0.78, 0.96);
      textStyle = textStyle.copyWith(
          color: Color.from(
              red: redGray, green: greenGray, blue: blueGray, alpha: 1.0));
    }

    return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
