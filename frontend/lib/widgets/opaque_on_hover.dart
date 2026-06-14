import 'package:flutter/material.dart';

class OpaqueOnHover extends StatefulWidget {
  const OpaqueOnHover(
      {super.key, this.child, this.opacityMin = 0.5, this.opacityMax = 1.0});

  final Widget? child;
  final double opacityMin;
  final double opacityMax;

  @override
  State<OpaqueOnHover> createState() => _OpaqueOnHoverState();
}

class _OpaqueOnHoverState extends State<OpaqueOnHover> {
  bool _isHovered = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        opacity: _isHovered ? widget.opacityMax : widget.opacityMin,
        duration: const Duration(milliseconds: 300),
        child: widget.child,
      ),
    );
  }
}
