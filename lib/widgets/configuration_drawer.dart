import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigurationDrawer extends ConsumerWidget {
  const ConfigurationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      title: const Text('Taille du thème'),
                      onTap: () {
                        _showFontSizePickerDialog(context);
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    ListTile(
                      tileColor: Colors.red,
                      title: const Text('Réinitialiser le thème'),
                      onTap: () {
                        ref.read(schemeProvider).reset();
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
  }
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
        );
      });
    },
  );
}

void _showFontSizePickerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer(builder: (context, ref, child) {
        final currentSize = ref.watch(schemeProvider).textSize;
        late String sizeCategory;
        if (currentSize < 18) {
          sizeCategory = 'Petit';
        } else if (currentSize < 28) {
          sizeCategory = 'Moyen';
        } else if (currentSize < 38) {
          sizeCategory = 'Grand';
        } else {
          sizeCategory = 'Très grand';
        }

        return AlertDialog(
          title: const Text('Choisir la taille du thème'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: currentSize,
                min: 12,
                max: 48,
                divisions: 36,
                label: 'Taille du thème: $sizeCategory',
                onChanged: (value) => ref.read(schemeProvider).textSize = value,
              ),
            ],
          ),
        );
      });
    },
  );
}
