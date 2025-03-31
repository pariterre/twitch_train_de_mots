import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.titleText});

  final String titleText;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Text(
          titleText,
          style: ThemeManager.instance.textFrontendSc.copyWith(fontSize: 36),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
