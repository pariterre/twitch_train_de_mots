import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResizedBox extends StatefulWidget {
  const ResizedBox({
    super.key,
    required this.borderWidth,
    required this.initialTop,
    required this.initialLeft,
    required this.initialWidth,
    required this.initialHeight,
    this.draggingChild,
    required this.child,
  });

  final double borderWidth;

  final double initialTop;
  final double initialLeft;
  final double initialWidth;
  final double initialHeight;

  final Widget? draggingChild;
  final Widget child;

  @override
  State<ResizedBox> createState() => _ResizedBoxState();
}

class _ResizedBoxState extends State<ResizedBox> {
  late double height = widget.initialHeight;
  late double width = widget.initialWidth;

  late double top = widget.initialTop;
  late double left = widget.initialLeft;

  void _onDragWindow(newLeft, newTop) {
    setState(() {
      top = newTop;
      left = newLeft;
    });
  }

  void _onDragTopLeft(dx, dy) {
    final newHeight = height - dy;
    final newWidth = width - dx;

    setState(() {
      height = newHeight > 0 ? newHeight : 0;
      width = newWidth > 0 ? newWidth : 0;
      top = top + dy;
      left = left + dx;
    });
  }

  void _onDragBottomRight(dx, dy) {
    final newHeight = height + dy;
    final newWidth = width + dx;

    setState(() {
      height = newHeight > 0 ? newHeight : 0;
      width = newWidth > 0 ? newWidth : 0;
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
          // top left
          Positioned(
            top: topEdge,
            left: leftEdge,
            child: _ManipulatingBorder(
              direction: _Direction.diagonalLeft,
              onDrag: _onDragTopLeft,
              borderWidth: borderWidth,
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
  const _ManipulatingBorder(
      {required this.onDrag,
      required this.direction,
      required this.borderWidth});

  final Function onDrag;
  final _Direction direction;
  final double borderWidth;

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
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
      ),
    );
  }
}
