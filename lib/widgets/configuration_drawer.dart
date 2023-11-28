import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigurationDrawer extends StatelessWidget {
  const ConfigurationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final scheme = ref.watch(schemeProvider);

        return Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: scheme.mainColor,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text('Configuration de\nTrain de mots',
                      style: TextStyle(color: scheme.textColor, fontSize: 24)),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        ListTile(
                          title: const Text('Couleur du thème'),
                          onTap: () => _showColorPickerDialog(context),
                        ),
                        ListTile(
                          title: const Text('Taille des mots'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Taille des mots'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ListTile(
                          title: const Text('Charger un thème'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Exporter le thème'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColorPickerDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);
          return AlertDialog(
            title: Text(
              'Choisir la couleur du temps',
              style: TextStyle(color: scheme.mainColor),
            ),
            content: AlertDialog(
              content: ColorPicker(
                pickerColor: scheme.mainColor,
                onColorChanged: (Color color) {
                  ref.read(schemeProvider).mainColor = color;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child:
                    Text('Cancel', style: TextStyle(color: scheme.mainColor)),
              ),
              TextButton(
                onPressed: () {
                  // You can use the selectedColor value for your drawer theme configuration
                  // For example, save the selectedColor in your app preferences or settings.
                  // Perform actions with selectedColor
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: scheme.mainColor)),
              ),
            ],
          );
        });
      },
    );
  }
}
