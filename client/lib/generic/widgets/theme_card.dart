import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Card(
      color: tm.mainColor,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: child,
      ),
    );
  }
}
