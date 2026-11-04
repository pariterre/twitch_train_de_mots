import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/parchment_dialog.dart';

class ConnexionCodeSticker extends StatelessWidget {
  const ConnexionCodeSticker({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    final qrMessage = 'https://traindemots.pariterre.net/cheminots/?code=$code';

    return Positioned(
        top: 40,
        left: 10,
        child: Transform.rotate(
          angle: -0.1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 540,
                height: 150,
                child: Image.asset(
                    'packages/common/assets/images/parchment.png',
                    fit: BoxFit.fill),
              ),
              Row(
                children: [
                  Column(
                    children: [
                      Text(
                        'Pour joindre, naviguez jusqu\'à ',
                        style: tm.clientMainTextStyle
                            .copyWith(color: Colors.black),
                      ),
                      Text(
                        'traindesmots.pariterre.net/cheminots',
                        style: tm.clientMainTextStyle.copyWith(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            'Puis entrez le code : ',
                            style: tm.clientMainTextStyle
                                .copyWith(color: Colors.black),
                          ),
                          Text(code,
                              style: tm.clientMainTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showAdminDialog(context),
                            child: Text('Cliquer ici',
                                style: tm.clientMainTextStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    decoration: TextDecoration.underline)),
                          ),
                          Text(' pour gérer vos chef·fe·s',
                              style: tm.clientMainTextStyle
                                  .copyWith(fontSize: 16, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => ParchmentDialog(
                                width: 450,
                                height: 450,
                                content: Center(
                                  child: QrImageView(
                                    data: qrMessage,
                                    version: QrVersions.auto,
                                    gapless: false,
                                  ),
                                ),
                              ));
                    },
                    child: QrImageView(
                      data: qrMessage,
                      version: QrVersions.auto,
                      size: 140,
                      gapless: false,
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}

void _showAdminDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      return ParchmentDialog(
        title: 'Choisir les cheminot·te·s en chef·fe·s',
        width: 500,
        height: 700,
        acceptButtonTitle: 'Terminer',
        onAccept: () {
          Navigator.of(context).pop();
        },
        content: SizedBox(
          height: 450,
          child: const _AdminCheckboxes(),
        ),
      );
    },
  );
}

class _AdminCheckboxes extends StatefulWidget {
  const _AdminCheckboxes();

  @override
  State<_AdminCheckboxes> createState() => _AdminCheckboxesState();
}

class _AdminCheckboxesState extends State<_AdminCheckboxes> {
  final tm = ThemeManager.instance;

  @override
  void initState() {
    super.initState();

    Managers.instance.train.onConfigurationUpdated.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();
    Managers.instance.train.onConfigurationUpdated.cancel(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (Managers.instance.ebs.connectedPlayers.isEmpty)
            Center(
                child: Text('Aucun cheminot·e n\'est encore connecté·e',
                    style:
                        tm.clientMainTextStyle.copyWith(color: Colors.black)))
          else
            ...Managers.instance.ebs.connectedPlayers.entries.map((entry) {
              final player = entry.key;
              final userId = entry.value;

              return CheckboxListTile(
                  fillColor: WidgetStateProperty.resolveWith((state) {
                    return state.contains(WidgetState.selected)
                        ? tm.mainColor
                        : Colors.transparent;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    player.displayName,
                    style: tm.clientMainTextStyle.copyWith(color: Colors.black),
                  ),
                  value: Managers.instance.train.adminIds.contains(userId),
                  onChanged: (value) {
                    if (value!) {
                      Managers.instance.train.addAdmin(userId);
                    } else {
                      Managers.instance.train.removeAdmin(userId);
                    }
                    setState(() {});
                  });
            })
        ],
      ),
    );
  }
}
