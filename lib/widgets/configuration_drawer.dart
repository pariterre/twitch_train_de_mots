import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/models/game_configuration.dart';

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
                      title: const Text('Réinitialiser la configuration'),
                      enabled:
                          ref.watch(gameConfigurationProvider).canChangeProblem,
                      onTap: () async {
                        final result = await showDialog<bool?>(
                            context: context,
                            builder: (context) => const _AreYouSureDialog());
                        if (result == null || !result) return;

                        ref
                            .read(gameConfigurationProvider)
                            .resetConfiguration();
                        ref.read(schemeProvider).reset();

                        if (context.mounted) Navigator.pop(context);
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

class _AreYouSureDialog extends StatelessWidget {
  const _AreYouSureDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return AlertDialog(
        title: Text('Réinitialiser la configuration',
            style: TextStyle(color: scheme.mainColor)),
        content: Text(
            'Êtes-vous sûr de vouloir réinitialiser la configuration?',
            style: TextStyle(color: scheme.mainColor)),
        actions: [
          TextButton(
            child: Text('Annuler', style: TextStyle(color: scheme.mainColor)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: scheme.mainColor,
                foregroundColor: scheme.textColor),
            child: const Text('Réinitialiser'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    });
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: scheme.mainColor,
                onColorChanged: (Color color) {
                  ref.read(schemeProvider).mainColor = color;
                },
              ),
            ],
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
        final scheme = ref.watch(schemeProvider);
        final currentSize = scheme.textSize;

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

        return Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);

          return AlertDialog(
            title: Text(
              'Choisir la taille du thème',
              style: TextStyle(color: scheme.mainColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: currentSize,
                  activeColor: scheme.mainColor,
                  min: 12,
                  max: 48,
                  divisions: 36,
                  label: 'Taille du thème: $sizeCategory',
                  onChanged: (value) =>
                      ref.read(schemeProvider).textSize = value,
                ),
              ],
            ),
          );
        });
      });
    },
  );
}

void _showGameConfiguration(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);
          final config = ref.watch(gameConfigurationProvider);

          return WillPopScope(
            onWillPop: () async {
              ref
                  .read(gameConfigurationProvider)
                  .finalizeConfigurationChanges();
              return true;
            },
            child: AlertDialog(
              title: Text(
                'Configuration du jeu',
                style: TextStyle(color: scheme.mainColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BooleanInputField(
                        label: 'Montrer les réponses au survol\nde la souris',
                        value: config.showAnswersTooltip,
                        onChanged: (value) {
                          ref
                              .read(gameConfigurationProvider)
                              .showAnswersTooltip = value;
                        }),
                    const SizedBox(height: 12),
                    _IntegerInputField(
                      label: 'Nombre de lettres des mots les plus courts',
                      initialValue: ref
                          .read(gameConfigurationProvider)
                          .nbLetterInSmallestWord
                          .toString(),
                      onChanged: (value) {
                        ref
                            .read(gameConfigurationProvider)
                            .nbLetterInSmallestWord = value;
                      },
                      enabled: config.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de lettres des mots les plus courts ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Nombre de lettres à piger',
                      firstLabel: 'Minimum',
                      firstInitialValue: ref
                          .read(gameConfigurationProvider)
                          .minimumWordLetter
                          .toString(),
                      secondLabel: 'Maximum',
                      secondInitialValue: ref
                          .read(gameConfigurationProvider)
                          .maximumWordLetter
                          .toString(),
                      onChanged: (mininum, maximum) {
                        ref.read(gameConfigurationProvider).minimumWordLetter =
                            mininum;
                        ref.read(gameConfigurationProvider).maximumWordLetter =
                            maximum;
                      },
                      enabled: config.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de lettres à piger ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Nombre de mots à trouver',
                      firstLabel: 'Minimum',
                      firstInitialValue: ref
                          .read(gameConfigurationProvider)
                          .minimumWordsNumber
                          .toString(),
                      secondLabel: 'Maximum',
                      secondInitialValue: ref
                          .read(gameConfigurationProvider)
                          .maximumWordsNumber
                          .toString(),
                      onChanged: (mininum, maximum) {
                        ref.read(gameConfigurationProvider).minimumWordsNumber =
                            mininum;
                        ref.read(gameConfigurationProvider).maximumWordsNumber =
                            maximum;
                      },
                      enabled: config.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de mots à trouver ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _IntegerInputField(
                      label: 'Durée d\'une manche (secondes)',
                      initialValue: ref
                          .read(gameConfigurationProvider)
                          .roundDuration
                          .inSeconds
                          .toString(),
                      onChanged: (value) {
                        ref.read(gameConfigurationProvider).roundDuration =
                            Duration(seconds: value);
                      },
                      enabled: config.canChangeDurations,
                      disabledTooltip:
                          'La durée d\'une manche ne peut pas être changée en cours de partie',
                    ),
                    const SizedBox(height: 12),
                    _IntegerInputField(
                      label: 'Temps avant de mélanger les lettres (secondes)',
                      initialValue: ref
                          .read(gameConfigurationProvider)
                          .timeBeforeScramblingLetters
                          .inSeconds
                          .toString(),
                      onChanged: (value) {
                        ref
                                .read(gameConfigurationProvider)
                                .timeBeforeScramblingLetters =
                            Duration(seconds: value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _BooleanInputField(
                      label: 'Voler un mot est permis',
                      value: ref.watch(gameConfigurationProvider).canSteal,
                      onChanged: (value) {
                        ref.read(gameConfigurationProvider).canSteal = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Période de récupération (secondes)',
                      firstLabel: 'Normale',
                      firstInitialValue: ref
                          .read(gameConfigurationProvider)
                          .cooldownPeriod
                          .inSeconds
                          .toString(),
                      secondLabel: 'Voleur',
                      secondInitialValue: ref
                          .read(gameConfigurationProvider)
                          .cooldownPeriodAfterSteal
                          .inSeconds
                          .toString(),
                      enableSecond:
                          ref.watch(gameConfigurationProvider).canSteal,
                      onChanged: (normal, stealer) {
                        ref.read(gameConfigurationProvider).cooldownPeriod =
                            Duration(seconds: normal);
                        ref
                                .read(gameConfigurationProvider)
                                .cooldownPeriodAfterSteal =
                            Duration(seconds: stealer);
                      },
                      enabled: config.canChangeDurations,
                      disabledTooltip:
                          'Les périodes de récupération ne peuvent pas être\n'
                          'changées en cours de partie',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.mainColor,
                          foregroundColor: scheme.textColor),
                      child: const Text('Terminer'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _IntegerInputField extends StatelessWidget {
  const _IntegerInputField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String initialValue;
  final Function(int) onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.mainColor)),
          );
        }),
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

class _DoubleIntegerInputField extends StatefulWidget {
  const _DoubleIntegerInputField({
    required this.label,
    required this.firstLabel,
    required this.firstInitialValue,
    this.enableSecond = true,
    required this.secondLabel,
    required this.secondInitialValue,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String firstLabel;
  final String firstInitialValue;
  final bool enableSecond;
  final String secondLabel;
  final String secondInitialValue;
  final Function(int minimum, int maximum) onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  State<_DoubleIntegerInputField> createState() =>
      _DoubleIntegerInputFieldState();
}

class _DoubleIntegerInputFieldState extends State<_DoubleIntegerInputField> {
  late int _first = int.parse(widget.firstInitialValue);
  late int _second = int.parse(widget.secondInitialValue);

  void _callOnChanged() => widget.onChanged(_first, _second);

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.mainColor)),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 150,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: widget.firstInitialValue,
                decoration: InputDecoration(
                  labelText: widget.firstLabel,
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final first = int.tryParse(value);
                  if (first == null) return;
                  _first = first;
                  _callOnChanged();
                },
                enabled: widget.enabled,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: widget.secondInitialValue,
                decoration: InputDecoration(
                  labelText: widget.secondLabel,
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final second = int.tryParse(value);
                  if (second == null) return;
                  _second = second;
                  _callOnChanged();
                },
                enabled: widget.enabled && widget.enableSecond,
              ),
            ),
          ],
        ),
      ],
    );
    return widget.disabledTooltip == null || widget.enabled
        ? child
        : Tooltip(
            message: widget.disabledTooltip!,
            child: child,
          );
  }
}

class _BooleanInputField extends StatelessWidget {
  const _BooleanInputField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: scheme.mainColor)),
              Checkbox(
                value: value,
                onChanged: (_) => onChanged(!value),
                fillColor: MaterialStateProperty.resolveWith((state) {
                  if (state.contains(MaterialState.selected)) {
                    return scheme.mainColor;
                  }
                  return Colors.white;
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}
