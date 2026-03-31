import 'dart:async';

import 'package:flutter/material.dart';

class HorizontalScroller extends StatefulWidget {
  const HorizontalScroller({
    super.key,
    this.leftIcon = Icons.chevron_left_sharp,
    this.rightIcon = Icons.chevron_right_sharp,
    this.leftIconPadding = const EdgeInsets.all(0.0),
    this.rightIconPadding = const EdgeInsets.all(0.0),
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.grey,
    required this.child,
  });

  final IconData leftIcon;
  final IconData rightIcon;

  final EdgeInsets leftIconPadding;
  final EdgeInsets rightIconPadding;

  final Color activeColor;
  final Color inactiveColor;

  final Widget child;

  @override
  State<HorizontalScroller> createState() => _HorizontalScrollerState();
}

class _HorizontalScrollerState extends State<HorizontalScroller> {
  late final ScrollController _controller = ScrollController()
    ..addListener(() => setState(() {}));
  final _maxRebuilds = 5;
  int _rebuildCount = 0;

  Timer? _scrollTimer;

  void _startScrolling(double direction) {
    _scrollTimer?.cancel();

    _scrollTimer = Timer.periodic(Duration(milliseconds: 16), (_) {
      if (direction < 0 &&
          _controller.offset <= _controller.position.minScrollExtent) {
        _stopScrolling();
      } else if (direction > 0 &&
          _controller.offset >= _controller.position.maxScrollExtent) {
        _stopScrolling();
      }

      final newOffset = _controller.offset + direction;

      if (_controller.hasClients) {
        final max = _controller.position.maxScrollExtent;
        final min = _controller.position.minScrollExtent;

        _controller.jumpTo(
          newOffset.clamp(min, max),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant HorizontalScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _rebuildCount = 0;
    }
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.hasClients || _controller.position.maxScrollExtent == 0) {
      if (_rebuildCount < _maxRebuilds) {
        _rebuildCount++;
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
      }
    }
    final isLeftActive = _controller.hasClients && _controller.offset > 0;
    final isRightActive = _controller.hasClients &&
        _controller.offset < _controller.position.maxScrollExtent;

    final leftColor = isLeftActive ? widget.activeColor : widget.inactiveColor;
    final rightColor =
        isRightActive ? widget.activeColor : widget.inactiveColor;

    return Row(
      children: [
        Padding(
          padding: widget.leftIconPadding,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: leftColor, width: 2),
              ),
              borderRadius: BorderRadius.circular(25),
              hoverColor: leftColor.withAlpha(50),
              onTapDown: isLeftActive ? (_) => _startScrolling(-7) : null,
              onTapUp: isLeftActive ? (_) => _stopScrolling() : null,
              onTapCancel: isLeftActive ? _stopScrolling : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(widget.leftIcon, color: leftColor),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
        ),
        Padding(
          padding: widget.rightIconPadding,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: rightColor, width: 2),
              ),
              borderRadius: BorderRadius.circular(25),
              hoverColor: rightColor.withAlpha(50),
              onTapDown: isRightActive ? (_) => _startScrolling(7) : null,
              onTapUp: isRightActive ? (_) => _stopScrolling() : null,
              onTapCancel: isRightActive ? _stopScrolling : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(widget.rightIcon, color: rightColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
