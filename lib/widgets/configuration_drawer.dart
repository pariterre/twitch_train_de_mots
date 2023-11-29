import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';

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
                    ListTile(
                      title: const Text('Configuration du jeu'),
                      onTap: () {
                        _showGameConfiguration(context);
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

void _showGameConfiguration(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (context, ref, child) => WillPopScope(
          onWillPop: () async {
            ref.read(gameManagerProvider).finalizeConfigurationChanges();
            return true;
          },
          child: AlertDialog(
            title: const Text('Configuration du jeu'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IntegerInputField(
                    label: 'Nombre de lettres des mots les plus courts',
                    enabled: ref
                        .watch(gameManagerProvider)
                        .canChangeNbLetterInSmallestWord,
                    initialValue: ref
                        .read(gameManagerProvider)
                        .nbLetterInSmallestWord
                        .toString(),
                    disabledTooltip:
                        'Le nombre de lettres des mots les plus courts ne peut pas\n'
                        'être changé en cours de partie ou le jeu chercher actuellement un mot',
                    onChanged: (value) {
                      ref.read(gameManagerProvider).nbLetterInSmallestWord =
                          value;
                    },
                  ),
                  const SizedBox(height: 24),
                  _DoubleIntegerInputField(
                      label: 'Nombre de lettres à piger',
                      firstLabel: 'Minimum',
                      secondLabel: 'Maximum',
                      onChanged: (mininum, maximum) {}),
                  const SizedBox(height: 24),
                  _DoubleIntegerInputField(
                      label: 'Nombre de mots à trouver',
                      firstLabel: 'Minimum',
                      secondLabel: 'Maximum',
                      onChanged: (mininum, maximum) {}),
                  const SizedBox(height: 24),
                  _IntegerInputField(
                    label: 'Durée d\'une manche (secondes)',
                    initialValue: ref
                        .read(gameManagerProvider)
                        .roundDuration
                        .inSeconds
                        .toString(),
                    enabled:
                        ref.watch(gameManagerProvider).canChangeRoundDuration,
                    onChanged: (value) {
                      ref.read(gameManagerProvider).roundDuration =
                          Duration(seconds: value);
                    },
                    disabledTooltip:
                        'La durée d\'une manche ne peut pas être changée en cours de partie',
                  ),
                  const SizedBox(height: 24),
                  _BooleanInputField(
                      label: 'Voler un mot est permis', onChanged: (value) {}),
                  const SizedBox(height: 24),
                  if (true)
                    _DoubleIntegerInputField(
                        label: 'Période de récupération (seconds)',
                        firstLabel: 'Normale',
                        secondLabel: 'Voleur',
                        onChanged: (normal, stealer) {}),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _IntegerInputField extends StatelessWidget {
  const _IntegerInputField({
    required this.label,
    this.enabled = true,
    required this.initialValue,
    required this.onChanged,
    this.disabledTooltip,
  });

  final String label;
  final bool enabled;
  final String initialValue;
  final Function(int) onChanged;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: 150,
          child: TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            initialValue: initialValue,
            enabled: enabled,
            onChanged: (String value) {
              final newValue = int.tryParse(value);
              if (newValue != null) onChanged(newValue);
            },
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
    return disabledTooltip == null || enabled
        ? child
        : Tooltip(
            message: disabledTooltip!,
            child: child,
          );
  }
}

class _DoubleIntegerInputField extends StatelessWidget {
  const _DoubleIntegerInputField({
    required this.label,
    required this.firstLabel,
    required this.secondLabel,
    required this.onChanged,
  });

  final String label;
  final String firstLabel;
  final String secondLabel;
  final Function(int minimum, int maximum) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: firstLabel,
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: secondLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BooleanInputField extends StatelessWidget {
  const _BooleanInputField({required this.label, required this.onChanged});
  final String label;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Checkbox(
            value: false,
            onChanged: (value) => onChanged(true),
          ),
        ],
      ),
    );
  }
}
