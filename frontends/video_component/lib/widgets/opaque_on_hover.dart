import 'package:flutter/material.dart';

class OpaqueOnHover extends StatefulWidget {
  const OpaqueOnHover(
      {super.key, this.child, this.opacityIn = 1.0, this.opacityOut = 0.5});

  final Widget? child;
  final double opacityOut;
  final double opacityIn;

  @override
  State<OpaqueOnHover> createState() => _OpaqueOnHoverState();
}

class _OpaqueOnHoverState extends State<OpaqueOnHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        opacity: _isHovered ? widget.opacityIn : widget.opacityOut,
        duration: const Duration(milliseconds: 300),
        child: widget.child,
      ),
    );
  }
}
