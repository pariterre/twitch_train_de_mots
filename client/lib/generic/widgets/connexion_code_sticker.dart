import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                width: 500,
                height: 120,
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
                    ],
                  ),
                  QrImageView(
                    data: 'https://traindemots.pariterre.net/cheminots/$code',
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
