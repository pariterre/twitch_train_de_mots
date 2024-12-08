import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResizedBox extends StatefulWidget {
  const ResizedBox({
    super.key,
    required this.borderWidth,
    this.decoration = const BoxDecoration(color: Colors.transparent),
    required this.initialTop,
    required this.initialLeft,
    required this.initialWidth,
    required this.initialHeight,
    this.minTop,
    this.minLeft,
    this.minWidth,
    this.minHeight,
    this.maxTop,
    this.maxLeft,
    this.maxWidth,
    this.maxHeight,
    required this.child,
    this.draggingChild,
    this.preserveAspectRatio = false,
  });

  final double borderWidth;
  final Decoration decoration;

  final double initialTop;
  final double initialLeft;
  final double initialWidth;
  final double initialHeight;

  final double? minTop;
  final double? minLeft;
  final double? minWidth;
  final double? minHeight;

  final double? maxTop;
  final double? maxLeft;
  final double? maxWidth;
  final double? maxHeight;

  final Widget child;
  final Widget? draggingChild;

  final bool preserveAspectRatio;

  @override
  State<ResizedBox> createState() => _ResizedBoxState();
}

class _ResizedBoxState extends State<ResizedBox> {
  late double _height = widget.initialHeight;
  double get height => _height;
  set height(double value) {
    if (widget.minHeight != null && value < widget.minHeight!) {
      value = widget.minHeight!;
    }
    if (widget.maxHeight != null && value > widget.maxHeight!) {
      value = widget.maxHeight!;
    }

    if (widget.preserveAspectRatio) {
      final aspectRatio = widget.initialWidth / widget.initialHeight;
      _width = value * aspectRatio;

      if (widget.minWidth != null && width < widget.minWidth!) {
        _width = widget.minWidth!;
        value = width / aspectRatio;
      }
      if (widget.maxWidth != null && width > widget.maxWidth!) {
        _width = widget.maxWidth!;
        value = width / aspectRatio;
      }
    }

    _height = value;
  }

  late double _width = widget.initialWidth;
  double get width => _width;
  set width(double value) {
    if (widget.minWidth != null && value < widget.minWidth!) {
      value = widget.minWidth!;
    }
    if (widget.maxWidth != null && value > widget.maxWidth!) {
      value = widget.maxWidth!;
    }

    if (widget.preserveAspectRatio) {
      final aspectRatio = widget.initialWidth / widget.initialHeight;
      _height = value / aspectRatio;

      if (widget.minHeight != null && height < widget.minHeight!) {
        _height = widget.minHeight!;
        value = height * aspectRatio;
      }
      if (widget.maxHeight != null && height > widget.maxHeight!) {
        _height = widget.maxHeight!;
        value = height * aspectRatio;
      }
    }

    _width = value;
  }

  late double _top = widget.initialTop;
  double get top => _top;
  set top(double value) {
    if (widget.minTop != null && value < widget.minTop!) {
      value = widget.minTop!;
    }
    if (widget.maxTop != null && value > widget.maxTop!) {
      value = widget.maxTop!;
    }
    _top = value;
  }

  late double _left = widget.initialLeft;
  double get left => _left;
  set left(double value) {
    if (widget.minLeft != null && value < widget.minLeft!) {
      value = widget.minLeft!;
    }
    if (widget.maxLeft != null && value > widget.maxLeft!) {
      value = widget.maxLeft!;
    }
    _left = value;
  }

  void _onDragWindow(newLeft, newTop) {
    setState(() {
      top = newTop;
      left = newLeft;
    });
  }

  void _onDragTopLeft(dx, dy) {
    final newHeight = height - dy > 0 ? height - dy : 0.0;
    final newWidth = width - dx > 0 ? width - dx : 0.0;

    setState(() {
      if (widget.preserveAspectRatio) {
        if (newWidth == width) {
          height = newHeight;
        } else {
          width = newWidth;
        }
      } else {
        height = newHeight;
        width = newWidth;
      }

      top = top + dy;
      left = left + dx;
    });
  }

  void _onDragBottomRight(dx, dy) {
    final newHeight = height + dy > 0 ? height + dy : 0.0;
    final newWidth = width + dx > 0 ? width + dx : 0.0;

    setState(() {
      if (widget.preserveAspectRatio) {
        if (newWidth == width) {
          height = newHeight;
        } else {
          width = newWidth;
        }
      } else {
        height = newHeight;
        width = newWidth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftEdge = left;
    final topEdge = top;
    final rightEdge = MediaQuery.of(context).size.width - (left + width);
    final bottomEdge = MediaQuery.of(context).size.height - (top + height);

    final borderWidth = widget.borderWidth;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: topEdge,
            left: leftEdge,
            child: Draggable(
              feedback: Opacity(
                  opacity: 0.5,
                  child: Material(
                      child: SizedBox(
                          width: width,
                          height: height,
                          child: widget.draggingChild))),
              onDragEnd: (details) =>
                  _onDragWindow(details.offset.dx, details.offset.dy),
              child:
                  SizedBox(width: width, height: height, child: widget.child),
            ),
          ),
          // top middle
          Positioned(
            top: topEdge,
            left: leftEdge + borderWidth,
            right: rightEdge + borderWidth,
            child: _ManipulatingBorder(
              direction: _Direction.vertical,
              onDrag: (double x, double y) => _onDragTopLeft(0, y),
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // center right
          Positioned(
            top: topEdge + borderWidth,
            bottom: bottomEdge + borderWidth,
            left: left + width - borderWidth,
            child: _ManipulatingBorder(
              direction: _Direction.horizontal,
              onDrag: (double x, double y) => _onDragBottomRight(x, 0),
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // bottom center
          Positioned(
            bottom: bottomEdge,
            left: leftEdge + borderWidth,
            right: rightEdge + borderWidth,
            child: _ManipulatingBorder(
              direction: _Direction.vertical,
              onDrag: (double x, double y) => _onDragBottomRight(0, y),
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // top left
          Positioned(
            top: topEdge,
            left: leftEdge,
            child: _ManipulatingBorder(
              direction: _Direction.diagonalLeft,
              onDrag: _onDragTopLeft,
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // left center
          Positioned(
            top: topEdge + borderWidth,
            left: left,
            bottom: bottomEdge + borderWidth,
            child: _ManipulatingBorder(
              direction: _Direction.horizontal,
              onDrag: (double x, double y) => _onDragTopLeft(x, 0),
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),

          // top right
          Positioned(
            top: topEdge,
            right: rightEdge,
            child: _ManipulatingBorder(
              direction: _Direction.diagonalRight,
              onDrag: (x, y) {
                _onDragTopLeft(0, y);
                _onDragBottomRight(x, 0);
              },
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // bottom right
          Positioned(
            bottom: bottomEdge,
            right: rightEdge,
            child: _ManipulatingBorder(
              direction: _Direction.diagonalLeft,
              onDrag: _onDragBottomRight,
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
          // bottom left
          Positioned(
            bottom: bottomEdge,
            left: leftEdge,
            child: _ManipulatingBorder(
              direction: _Direction.diagonalRight,
              onDrag: (x, y) {
                _onDragTopLeft(x, 0);
                _onDragBottomRight(0, y);
              },
              borderWidth: borderWidth,
              decoration: widget.decoration,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Direction {
  vertical,
  horizontal,
  diagonalRight,
  diagonalLeft,
  move;

  SystemMouseCursor get cursor {
    switch (this) {
      case _Direction.vertical:
        return SystemMouseCursors.resizeRow;
      case _Direction.horizontal:
        return SystemMouseCursors.resizeColumn;
      case _Direction.diagonalRight:
        return SystemMouseCursors.resizeDownLeft;
      case _Direction.diagonalLeft:
        return SystemMouseCursors.resizeDownRight;
      case _Direction.move:
        return SystemMouseCursors.basic;
    }
  }
}

class _ManipulatingBorder extends StatefulWidget {
  const _ManipulatingBorder({
    required this.onDrag,
    required this.direction,
    required this.borderWidth,
    required this.decoration,
  });

  final Function onDrag;
  final _Direction direction;
  final double borderWidth;
  final Decoration decoration;

  @override
  _ManipulatingBorderState createState() => _ManipulatingBorderState();
}

class _ManipulatingBorderState extends State<_ManipulatingBorder> {
  late double initX;
  late double initY;

  _handleDrag(DragStartDetails details) {
    setState(() {
      initX = details.globalPosition.dx;
      initY = details.globalPosition.dy;
    });
  }

  _handleUpdate(DragUpdateDetails details) {
    var dx = details.globalPosition.dx - initX;
    var dy = details.globalPosition.dy - initY;
    initX = details.globalPosition.dx;
    initY = details.globalPosition.dy;
    widget.onDrag(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.direction.cursor,
      child: GestureDetector(
        onPanStart: _handleDrag,
        onPanUpdate: _handleUpdate,
        child: Container(
          width: widget.borderWidth,
          height: widget.borderWidth,
          decoration: widget.decoration,
        ),
      ),
    );
  }
}
