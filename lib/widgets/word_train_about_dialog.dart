import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/models/release_notes.dart';
import 'package:url_launcher/url_launcher.dart';

class WordTrainAboutDialog extends StatelessWidget {
  const WordTrainAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('À propos du petit Train du Nord'),
      content: SingleChildScrollView(
        child: _buildReleaseNotes(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  List<Widget> _buildFeatures(List<FeatureNotes> features) {
    return features
        .map((feature) => Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•'),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: RichText(
                        text: TextSpan(children: [
                      TextSpan(text: feature.description),
                      if (feature.userWhoRequested != null)
                        TextSpan(children: [
                          const TextSpan(text: ' (proposé par '),
                          TextSpan(
                              text: feature.userWhoRequested!,
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                              recognizer: feature.urlOfUserWhoRequested == null
                                  ? null
                                  : (TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse(
                                          feature.urlOfUserWhoRequested!));
                                    })),
                          const TextSpan(text: ')'),
                        ]),
                    ])),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildReleaseNotes() {
    final releaseNotes = ConfigurationManager.instance.releaseNotes;

    return Container(
      width: 500,
      constraints: const BoxConstraints(maxHeight: 550),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: releaseNotes.reversed
                .map((release) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Version ${release.version}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (release.codeName != null)
                                Text(
                                  ' - ${release.codeName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          if (release.notes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(release.notes!),
                            ),
                          const SizedBox(height: 8.0),
                          ..._buildFeatures(release.features),
                        ],
                      ),
                    ))
                .toList()),
      ),
    );
  }
}
