import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class ConnexionCodeSticker extends StatelessWidget {
  const ConnexionCodeSticker({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Positioned(
        top: 40,
        left: 10,
        child: Transform.rotate(
          angle: -0.1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 530,
                height: 130,
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
                            onTap: () async {
                              // TODO Do a better showDialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return const AlertDialog(
                                    content: Row(
                                      children: [
                                        Text(
                                            'Connecter le ou la cheminot·e en chef·fe maintenant!'),
                                        CircularProgressIndicator(),
                                        SizedBox(width: 20),
                                        Text('Please wait...'),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                final userId = await Managers.instance.ebs
                                    .waitForGameManagerUserId();
                                Managers.instance.train.gameManagerUserId =
                                    userId ?? '';
                              } finally {
                                // Close dialog when Future completes
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                }
                              }
                            },
                            child: Text('Cliquer ici',
                                style: tm.clientMainTextStyle.copyWith(
                                    fontSize: 16,
                                    color: Colors.black,
                                    decoration: TextDecoration.underline)),
                          ),
                          Text(' pour connecter le cheminot en chef',
                              style: tm.clientMainTextStyle
                                  .copyWith(fontSize: 16, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                  QrImageView(
                    data:
                        'https://traindemots.pariterre.net/cheminots/?code=$code',
                    version: QrVersions.auto,
                    size: 100,
                    gapless: false,
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
