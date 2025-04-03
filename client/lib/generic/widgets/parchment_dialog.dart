import 'dart:async';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class ParchmentDialog extends StatefulWidget {
  const ParchmentDialog({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    this.padding,
    required this.content,
    this.onAccept,
    this.acceptButtonTitle = 'OK',
    this.autoAcceptDuration,
    this.onCancel,
    this.cancelButtonTitle,
    this.cancelButtonDisabledTooltip = '',
  });

  final String title;
  final double width;
  final double height;
  final EdgeInsets? padding;
  final Widget content;

  final String acceptButtonTitle;
  final Function()? onAccept;
  final Duration? autoAcceptDuration;

  final String? cancelButtonTitle;
  final String cancelButtonDisabledTooltip;
  final Function()? onCancel;

  @override
  State<ParchmentDialog> createState() => _ParchmentDialogState();
}

class _ParchmentDialogState extends State<ParchmentDialog> {
  Duration? _autoAcceptDuration;

  @override
  void initState() {
    super.initState();
    if (widget.autoAcceptDuration != null) {
      _autoAcceptDuration = widget.autoAcceptDuration;

      Timer(widget.autoAcceptDuration!, () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _autoAcceptDuration =
              Duration(seconds: _autoAcceptDuration!.inSeconds - 1);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return AlertDialog(
      content: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
                width: widget.width,
                height: widget.height,
                child: Image.asset(
                    'packages/common/assets/images/parchment.png',
                    fit: BoxFit.fill)),
            Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: tm.clientMainTextStyle.copyWith(
                          color: Colors.black,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  widget.content,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.cancelButtonTitle != null)
                            Tooltip(
                              message: widget.onCancel == null
                                  ? widget.cancelButtonDisabledTooltip
                                  : '',
                              child: TextButton(
                                onPressed: widget.onCancel,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                child: Text(
                                  widget.cancelButtonTitle!,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          if (widget.onAccept != null)
                            TextButton(
                              onPressed: widget.onAccept,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(
                                '${widget.acceptButtonTitle}'
                                '${_autoAcceptDuration != null ? ' (${_autoAcceptDuration!.inSeconds} secondes)' : ''}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      shadowColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }
}
