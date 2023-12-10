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
                      MaterialStatePropertyAll(tm.buttonTextStyle.color))
              : tm.elevatedButtonStyle,
          child: Text(widget.buttonText,
              style: widget.reversedStyle
                  ? tm.buttonTextStyle.copyWith(
                      color: tm.elevatedButtonStyle.backgroundColor!
                          .resolve({MaterialState.focused}))
                  : tm.buttonTextStyle)),
    );
  }
}
