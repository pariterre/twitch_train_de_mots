import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/widgets/themed_elevated_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfigurationDrawer extends StatefulWidget {
  const ConfigurationDrawer({super.key});

  @override
  State<ConfigurationDrawer> createState() => _ConfigurationDrawerState();
}

class _ConfigurationDrawerState extends State<ConfigurationDrawer> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;
    final dm = DatabaseManager.instance;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: tm.mainColor,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text('Configuration de\nTrain de mots',
                  style: TextStyle(color: tm.textColor, fontSize: 24)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    ListTile(
                      title: const Text('Configuration du thème'),
                      onTap: () => _showThemeConfiguration(context),
                    ),
                    if (cm.useDebugOptions)
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
                    const ListTile(
                        title: Text('Pause café'), onTap: _buyMeACoffee),
                    const Divider(),
                    if (cm.useDebugOptions)
                      Column(
                        children: [
                          ListTile(
                            title: const Text('Terminer la rounde actuelle'),
                            enabled: gm.gameStatus == GameStatus.roundStarted,
                            onTap: () async {
                              await gm.requestTerminateRound();
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                    ListTile(
                        tileColor: Colors.black,
                        title: const Text(
                          'Sortir du train (Déconnexion)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          final result = await showDialog<bool?>(
                              context: context,
                              builder: (context) => const _AreYouSureDialog(
                                    title: 'Quitter le train',
                                    message:
                                        'Êtes-vous sûr de vouloir abandonner votre poste?',
                                    yesTitle: 'Quitter',
                                  ));
                          if (result == null || !result) return;

                          await dm.logOut();
                          if (context.mounted) Navigator.pop(context);
                        }),
                    if (cm.useDebugOptions)
                      ListTile(
                        tileColor: Colors.red,
                        title: const Text('Réinitialiser la configuration'),
                        enabled: cm.canChangeProblem,
                        onTap: () async {
                          final result = await showDialog<bool?>(
                              context: context,
                              builder: (context) => const _AreYouSureDialog(
                                    title: 'Réinitialiser la configuration',
                                    message:
                                        'Êtes-vous sûr de vouloir réinitialiser la configuration?',
                                    yesTitle: 'Réinitialiser',
                                  ));
                          if (result == null || !result) return;

                          cm.resetConfiguration();
                          tm.reset();

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

void _buyMeACoffee() async {
  await launchUrl(Uri.parse('https://www.buymeacoffee.com/pariterre?l=fr'));
}

void _showThemeConfiguration(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const _ThemeConfiguration();
    },
  );
}

class _ThemeConfiguration extends StatefulWidget {
  const _ThemeConfiguration();

  @override
  State<_ThemeConfiguration> createState() => _ThemeConfigurationState();
}

class _ThemeConfigurationState extends State<_ThemeConfiguration> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    return AlertDialog(
      title: Text(
        'Configuration du thème',
        style: TextStyle(color: tm.mainColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ColorPickerInputField(label: 'Choisir la couleur du temps'),
          const SizedBox(height: 24),
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _FontSizePickerInputField(
                    label: 'Choisir la taille du thème'),
                const SizedBox(height: 12),
                _SliderInputField(
                  label: 'Volume de la musique',
                  value: cm.musicVolume,
                  onChanged: (value) {
                    cm.musicVolume = value;
                  },
                  thumbLabel: '${(cm.musicVolume * 100).toInt()}%',
                ),
                const SizedBox(height: 12),
                _SliderInputField(
                  label: 'Volume des sons',
                  value: cm.soundVolume,
                  onChanged: (value) {
                    cm.soundVolume = value;
                  },
                  thumbLabel: '${(cm.soundVolume * 100).toInt()}%',
                ),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label: 'Afficher le tableau des cheminot\u2022e\u2022s',
                    value: cm.showLeaderBoard,
                    onChanged: (value) {
                      cm.showLeaderBoard = value;
                    }),
                const SizedBox(height: 12),
                if (cm.useDebugOptions)
                  _BooleanInputField(
                      label: 'Montrer les réponses au survol\nde la souris',
                      value: cm.showAnswersTooltip,
                      onChanged: (value) {
                        cm.showAnswersTooltip = value;
                      }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ColorPickerInputField extends StatefulWidget {
  const _ColorPickerInputField({required this.label});

  final String label;

  @override
  State<_ColorPickerInputField> createState() => _ColorPickerInputFieldState();
}

class _ColorPickerInputFieldState extends State<_ColorPickerInputField> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(widget.label,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: tm.mainColor)),
        ),
        ColorPicker(
          pickerColor: tm.mainColor,
          onColorChanged: (Color color) => tm.mainColor = color,
        ),
      ],
    );
  }
}

class _FontSizePickerInputField extends StatefulWidget {
  const _FontSizePickerInputField({required this.label});

  final String label;

  @override
  State<_FontSizePickerInputField> createState() =>
      _FontSizePickerInputFieldState();
}

class _FontSizePickerInputFieldState extends State<_FontSizePickerInputField> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    late String sizeCategory;
    if (tm.textSize < 18) {
      sizeCategory = 'Petit';
    } else if (tm.textSize < 28) {
      sizeCategory = 'Moyen';
    } else if (tm.textSize < 38) {
      sizeCategory = 'Grand';
    } else {
      sizeCategory = 'Très grand';
    }
    return _SliderInputField(
      label: widget.label,
      value: tm.textSize,
      min: 12,
      max: 48,
      divisions: 36,
      thumbLabel: 'Taille du thème: $sizeCategory',
      onChanged: (value) => tm.textSize = value,
    );
  }
}

void _showGameConfiguration(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const _GameConfiguration();
    },
  );
}

class _GameConfiguration extends StatefulWidget {
  const _GameConfiguration();

  @override
  State<_GameConfiguration> createState() => _GameConfigurationState();
}

class _GameConfigurationState extends State<_GameConfiguration> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    return PopScope(
      onPopInvoked: (didPop) => cm.finalizeConfigurationChanges(),
      child: AlertDialog(
        title: Text(
          'Configuration du jeu',
          style: TextStyle(color: tm.mainColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IntegerInputField(
                label: 'Nombre de lettres des mots les plus courts',
                initialValue: cm.nbLetterInSmallestWord.toString(),
                onChanged: (value) => cm.nbLetterInSmallestWord = value,
                enabled: cm.canChangeProblem,
                disabledTooltip:
                    'Le nombre de lettres des mots les plus courts ne peut pas\n'
                    'être changé en cours de partie ou lorsque le jeu cherche un mot',
              ),
              const SizedBox(height: 12),
              _DoubleIntegerInputField(
                label: 'Nombre de lettres à piger',
                firstLabel: 'Minimum',
                firstInitialValue: cm.minimumWordLetter.toString(),
                secondLabel: 'Maximum',
                secondInitialValue: cm.maximumWordLetter.toString(),
                onChanged: (mininum, maximum) {
                  cm.minimumWordLetter = mininum;
                  cm.maximumWordLetter = maximum;
                },
                enabled: cm.canChangeProblem,
                disabledTooltip: 'Le nombre de lettres à piger ne peut pas\n'
                    'être changé en cours de partie ou lorsque le jeu cherche un mot',
              ),
              const SizedBox(height: 12),
              _DoubleIntegerInputField(
                label: 'Nombre de mots à trouver',
                firstLabel: 'Minimum',
                firstInitialValue: cm.minimumWordsNumber.toString(),
                secondLabel: 'Maximum',
                secondInitialValue: cm.maximumWordsNumber.toString(),
                onChanged: (mininum, maximum) {
                  cm.minimumWordsNumber = mininum;
                  cm.maximumWordsNumber = maximum;
                },
                enabled: cm.canChangeProblem,
                disabledTooltip: 'Le nombre de mots à trouver ne peut pas\n'
                    'être changé en cours de partie ou lorsque le jeu cherche un mot',
              ),
              const SizedBox(height: 12),
              _IntegerInputField(
                label: 'Durée d\'une manche (secondes)',
                initialValue: cm.roundDuration.inSeconds.toString(),
                onChanged: (value) =>
                    cm.roundDuration = Duration(seconds: value),
                enabled: cm.canChangeDurations,
                disabledTooltip:
                    'La durée d\'une manche ne peut pas être changée en cours de partie',
              ),
              const SizedBox(height: 12),
              _IntegerInputField(
                label: 'Temps avant de mélanger les lettres (secondes)',
                initialValue:
                    cm.timeBeforeScramblingLetters.inSeconds.toString(),
                onChanged: (value) =>
                    cm.timeBeforeScramblingLetters = Duration(seconds: value),
              ),
              const SizedBox(height: 12),
              _BooleanInputField(
                label: 'Voler un mot est permis',
                value: cm.canSteal,
                onChanged: (value) => cm.canSteal = value,
              ),
              const SizedBox(height: 12),
              _DoubleIntegerInputField(
                label: 'Période de récupération (secondes)',
                firstLabel: 'Normale',
                firstInitialValue: cm.cooldownPeriod.inSeconds.toString(),
                secondLabel: 'Voleur',
                secondInitialValue:
                    cm.cooldownPenaltyAfterSteal.inSeconds.toString(),
                enableSecond: cm.canSteal,
                onChanged: (normal, stealer) {
                  cm.cooldownPeriod = Duration(seconds: normal);
                  cm.cooldownPenaltyAfterSteal = Duration(seconds: stealer);
                },
                enabled: cm.canChangeDurations,
                disabledTooltip:
                    'Les périodes de récupération ne peuvent pas être\n'
                    'changées en cours de partie',
              ),
              const SizedBox(height: 24),
              ThemedElevatedButton(
                onPressed: () => Navigator.pop(context),
                reversedStyle: true,
                buttonText: 'Terminer',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
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
    final tm = ThemeManager.instance;

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: tm.mainColor)),
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
    final tm = ThemeManager.instance;

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(widget.label,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: tm.mainColor)),
        ),
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
    final tm = ThemeManager.instance;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: tm.mainColor)),
            Checkbox(
              value: value,
              onChanged: (_) => onChanged(!value),
              fillColor: MaterialStateProperty.resolveWith((state) {
                if (state.contains(MaterialState.selected)) {
                  return tm.mainColor;
                }
                return Colors.white;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderInputField extends StatelessWidget {
  const _SliderInputField({
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 100,
    required this.thumbLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String thumbLabel;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tm.mainColor,
            ),
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            label: thumbLabel,
            activeColor: tm.mainColor,
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _AreYouSureDialog extends StatelessWidget {
  const _AreYouSureDialog(
      {required this.title, required this.message, this.yesTitle = 'Oui'});

  final String title;
  final String message;
  final String yesTitle;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return AlertDialog(
      title: Text(title, style: TextStyle(color: tm.mainColor)),
      content: Text(message, style: TextStyle(color: tm.mainColor)),
      actions: [
        TextButton(
          child: Text('Annuler',
              style: TextStyle(
                  color: tm.mainColor, fontSize: tm.buttonTextStyle.fontSize)),
          onPressed: () => Navigator.pop(context, false),
        ),
        ThemedElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          reversedStyle: true,
          buttonText: yesTitle,
        ),
      ],
    );
  }
}
