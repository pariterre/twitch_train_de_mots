import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/dragging_screen.dart';
import 'package:frontend/widgets/resized_box.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({
    super.key,
    required this.initialSize,
    required this.child,
  });

  final Size? initialSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mainWidget = _MainContainer(child: child);
    const draggingWidget = _MainContainer(child: DraggingScreen());

    return initialSize == null
        ? mainWidget
        : ResizedBox(
            initialTop: 0,
            initialLeft: 0,
            initialWidth: initialSize!.width,
            initialHeight: initialSize!.height,
            borderWidth: 10,
            draggingChild: draggingWidget,
            child: mainWidget);
  }
}

class _MainContainer extends StatelessWidget {
  const _MainContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Background(
      backgroundLayer: Opacity(
        opacity: 0.05,
        child: Image.asset(
          'assets/images/train.png',
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
