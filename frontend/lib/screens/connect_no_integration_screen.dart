import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
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
  late final _codeController = TextEditingController()
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
                    width: 200,
                    child: TextField(
                      controller: _codeController,
                      enabled: !_isConnecting,
                      decoration: const InputDecoration(
                        labelText: 'Code de connexion',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isConnecting)
                    ElevatedButton(
                        onPressed: _codeController.text.isNotEmpty
                            ? () async {
                                setState(() => _isConnecting = false);
                                await im.disconnectFromStreamer();
                              }
                            : null,
                        child: const Text('Annuler'))
                  else
                    ElevatedButton(
                        onPressed: _codeController.text.isNotEmpty
                            ? () async {
                                setState(() => _isConnecting = true);
                                await im.connectToStreamer(
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
