import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';

class FrontendTextInput extends StatefulWidget {
  const FrontendTextInput(
      {super.key,
      required this.onWordSubmitted,
      this.onFocusChanged,
      this.suffix});

  final Function(String)? onWordSubmitted;
  final ValueChanged<bool>? onFocusChanged;
  final Widget? suffix;

  @override
  State<FrontendTextInput> createState() => _FrontendTextInputState();
}

class _FrontendTextInputState extends State<FrontendTextInput> {
  late final FocusNode _focusNode = FocusNode();

  late final TextEditingController _controller = TextEditingController()
    ..addListener(() {
      _controller.value = _controller.value.copyWith(
        text: _controller.text.toUpperCase(),
        selection: _controller.selection,
        composing: TextRange.empty,
      );
      setState(() {});
    });

  void _onSendPressed() {
    final text = _controller.text.trim();
    _controller.clear();

    widget.onWordSubmitted!(text);
  }

  @override
  void initState() {
    super.initState();
    if (widget.onFocusChanged != null) {
      _focusNode.addListener(() => widget.onFocusChanged!(_focusNode.hasFocus));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              fillColor: Colors.white,
              labelText: 'Tenter une réponse',
              labelStyle: tm.textFrontendSc,
            ),
            onSubmitted: widget.onWordSubmitted == null
                ? null
                : (value) => _onSendPressed(),
            cursorColor: Colors.white,
            style: tm.textInputFrontend.copyWith(letterSpacing: 5.0),
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: IconButton(
                  onPressed: _controller.text.isNotEmpty &&
                          widget.onWordSubmitted != null
                      ? _onSendPressed
                      : null,
                  icon: Icon(
                    Icons.send,
                    color: _controller.text.isNotEmpty
                        ? Colors.white
                        : Colors.grey,
                  )),
            ),
            if (widget.suffix != null) widget.suffix!,
          ],
        ),
      ],
    );
  }
}
