import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';

class ConnectNoIntegrationScreen extends StatefulWidget {
  const ConnectNoIntegrationScreen({super.key});

  @override
  State<ConnectNoIntegrationScreen> createState() =>
      _ConnectNoIntegrationScreenState();
}

class _ConnectNoIntegrationScreenState
    extends State<ConnectNoIntegrationScreen> {
  late final _loginController = TextEditingController()
    ..addListener(() {
      setState(() {});
    });
  late final _codeController = TextEditingController(
      text: _UpperCaseAlphanumericFormatter(
              maxCharacters: 6, forceCapitalize: true)
          .formatEditUpdate(TextEditingValue.empty,
              TextEditingValue(text: Uri.base.queryParameters['code'] ?? ''))
          .text)
    ..addListener(() {
      setState(() {});
    });

  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final im = IntegrationManager.instance as NoIntegrationManager;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const FittedBox(
            fit: BoxFit.scaleDown,
            child: Header(titleText: 'Le Train de mots!')),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bonjour cheminot·e,\n'
                    'Afin d\'embarquer\n'
                    'dans le train, vous devez\n'
                    'choisir un identifiant et\n'
                    'fournir le code de connexion\n'
                    'de votre cheminot·e en chef',
                    textAlign: TextAlign.left,
                    style: tm.textFrontendSc,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _loginController,
                      enabled: !_isConnecting,
                      decoration: InputDecoration(
                          labelText: 'Pseudonyme',
                          labelStyle: tm.clientMainTextStyle,
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: tm.textColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: tm.textColor))),
                      style: tm.clientMainTextStyle,
                      cursorColor: tm.textColor,
                      inputFormatters: [
                        _UpperCaseAlphanumericFormatter(
                            maxCharacters: 16, allowExtendedCharacters: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                          labelText: 'Code de connexion',
                          labelStyle: tm.clientMainTextStyle,
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: tm.textColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: tm.textColor))),
                      style: tm.clientMainTextStyle,
                      cursorColor: tm.textColor,
                      inputFormatters: [
                        _UpperCaseAlphanumericFormatter(
                            maxCharacters: 6, forceCapitalize: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isConnecting)
                    ElevatedButton(
                        onPressed: () async {
                          setState(() => _isConnecting = false);
                          await im.disconnectFromStreamer();
                        },
                        child: const Text('Annuler'))
                  else
                    ElevatedButton(
                        onPressed: _loginController.text.isNotEmpty &&
                                _codeController.text.isNotEmpty
                            ? () async {
                                setState(() => _isConnecting = true);
                                await im.connectToStreamer(
                                    login: _loginController.text,
                                    channelId: _codeController.text);
                              }
                            : null,
                        child: const Text('Connexion')),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _UpperCaseAlphanumericFormatter extends TextInputFormatter {
  _UpperCaseAlphanumericFormatter(
      {required this.maxCharacters,
      this.forceCapitalize = false,
      this.allowExtendedCharacters = false});

  final int maxCharacters;
  final bool allowExtendedCharacters;
  final bool forceCapitalize;
  late final allowedCharacters = RegExp(allowExtendedCharacters
      ? r'[a-zA-Z0-9\!@#\$%\?&\*\-\_]'
      : r'[a-zA-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > maxCharacters) return oldValue;

    final buffer = StringBuffer();
    var selectionOffset = 0;

    for (var i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i];

      if (allowedCharacters.hasMatch(char)) {
        buffer.write(forceCapitalize ? char.toUpperCase() : char);

        if (i < newValue.selection.extentOffset) {
          selectionOffset++;
        }
      }
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }
}
