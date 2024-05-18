import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/widgets/parchment_dialog.dart';
import 'package:train_de_mots/widgets/word_train_about_dialog.dart';
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
                      leading: const Icon(Icons.settings),
                      iconColor: tm.backgroundColorDark,
                      title: const Text('Configuration du jeu'),
                      onTap: () => _showGameConfiguration(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: gm.hasPlayedAtLeastOnce
                          ? const Icon(Icons.cancel,
                              color: Color.fromARGB(255, 138, 9, 0))
                          : const Icon(Icons.star,
                              color: Color.fromARGB(255, 143, 107, 1)),
                      title: Text(gm.hasPlayedAtLeastOnce
                          ? 'Terminer la rounde actuelle'
                          : 'Afficher le tableau des cheminot·e·s'),
                      enabled: true,
                      onTap: () async {
                        await gm.requestTerminateRound();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings_applications_sharp),
                      title: const Text('Configuration avancée'),
                      onTap: () {
                        _showGameDevConfiguration(context);
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      iconColor: Colors.blueGrey,
                      title: const Text('À propos'),
                      onTap: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const WordTrainAboutDialog();
                        },
                      ),
                    ),
                    const ListTile(
                      tileColor: Color.fromARGB(255, 221, 134, 102),
                      leading: Icon(Icons.coffee),
                      title: Text('Pause café'),
                      onTap: _buyMeACoffee,
                    ),
                    ListTile(
                        tileColor: Colors.black,
                        leading: const Icon(Icons.logout),
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

void _showGameConfiguration(context) {
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

    return ParchmentDialog(
        title: 'Configuration du jeu',
        width: 800,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.only(left: 80.0, right: 50),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ColorPickerInputField(
                    label: 'Choisir la couleur du thème'),
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
                        onChanged: (value) => cm.musicVolume = value,
                        thumbLabel: '${(cm.musicVolume * 100).toInt()}%',
                      ),
                      const SizedBox(height: 12),
                      _SliderInputField(
                        label: 'Volume des sons',
                        value: cm.soundVolume,
                        onChanged: (value) => cm.soundVolume = value,
                        thumbLabel: '${(cm.soundVolume * 100).toInt()}%',
                      ),
                      const SizedBox(height: 12),
                      _BooleanInputField(
                          label:
                              'Afficher le tableau des cheminot\u00b7e\u00b7s',
                          value: cm.showLeaderBoard,
                          onChanged: (value) => cm.showLeaderBoard = value),
                      const SizedBox(height: 12),
                      _BooleanInputField(
                          label:
                              'Relancer automatiquement\n(effectif à la prochaine pause)',
                          value: cm.autoplay,
                          onChanged: (value) => cm.autoplay = value),
                      const SizedBox(height: 12),
                      if (cm.useDebugOptions)
                        _BooleanInputField(
                            label:
                                'Montrer les réponses au survol\nde la souris',
                            value: cm.showAnswersTooltip,
                            onChanged: (value) =>
                                cm.showAnswersTooltip = value),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        acceptButtonTitle: 'Fermer',
        onAccept: () => Navigator.pop(context),
        cancelButtonTitle: 'Réinitialiser la configuration',
        onCancel: () async {
          final result = await showDialog<bool?>(
              context: context,
              builder: (context) => const _AreYouSureDialog(
                    title: 'Réinitialiser la configuration',
                    message:
                        'Êtes-vous sûr de vouloir réinitialiser la configuration?',
                    yesTitle: 'Réinitialiser',
                  ));
          if (result == null || !result) return;

          cm.resetConfiguration(advancedOptions: false, userOptions: true);
        });
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
              style: const TextStyle(fontWeight: FontWeight.bold)),
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

void _showGameDevConfiguration(BuildContext context) async {
  final pref = await SharedPreferences.getInstance();
  if (pref.getBool('wasAdvanceSettingWarningShown') != true) {
    if (!context.mounted) return;
    await showDialog(
        context: context,
        builder: (ctx) => const ParchmentDialog(
              title: 'Mise en garde',
              height: 400,
              width: 500,
              content: Text('Attention cheminot\u00b7e!\n\n'
                  'Les options avancées peuvent être amusantes, mais elles peuvent aussi'
                  's\'avérer dangereuses! Pour cette raison, votre cheminement '
                  'ne sera pas sauvegardé si vous avez modifié ces options.\n\n'
                  'Pour revenir aux options de base, vous pouvez cliquer sur '
                  'le bouton "Réinitialiser la configuration" dans le parchemin de configuration.\n\n'
                  'Attention : Il est possible que le jeu devienne instable et très lent.'
                  'Si cela se produit, utilisez la fonction de réinitialisation.'),
            ));
    pref.setBool('wasAdvanceSettingWarningShown', true);
  }

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return const _GameDevConfiguration();
    },
  );
}

class _GameDevConfiguration extends StatefulWidget {
  const _GameDevConfiguration();

  @override
  State<_GameDevConfiguration> createState() => _GameDevConfigurationState();
}

class _GameDevConfigurationState extends State<_GameDevConfiguration> {
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

    return PopScope(
      onPopInvoked: (didPop) => cm.finalizeConfigurationChanges(),
      child: ParchmentDialog(
        title: 'Configuration avancée',
        width: 500,
        height: MediaQuery.of(context).size.height * 0.9,
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                _DoubleIntegerInputField(
                  label: 'Durée post-ronde (secondes)',
                  firstLabel: 'Période de grâce',
                  secondLabel: 'Vitrine',
                  firstInitialValue:
                      cm.postRoundGracePeriodDuration.inSeconds.toString(),
                  secondInitialValue:
                      cm.postRoundShowCaseDuration.inSeconds.toString(),
                  onChanged: (first, second) {
                    cm.postRoundGracePeriodDuration = Duration(seconds: first);
                    cm.postRoundShowCaseDuration = Duration(seconds: second);
                  },
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
                  secondLabel: 'Pénalité voleur',
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
                const SizedBox(height: 12),
                _BooleanInputField(
                  label: 'Une seule station par manche',
                  value: cm.oneStationMaxPerRound,
                  onChanged: (value) => cm.oneStationMaxPerRound = value,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        acceptButtonTitle: 'Fermer',
        onAccept: () => Navigator.pop(context),
        cancelButtonTitle: 'Réinitialiser la configuration',
        onCancel: cm.canChangeProblem
            ? () async {
                final result = await showDialog<bool?>(
                    context: context,
                    builder: (context) => const _AreYouSureDialog(
                          title: 'Réinitialiser la configuration',
                          message:
                              'Êtes-vous sûr de vouloir réinitialiser la configuration?',
                          yesTitle: 'Réinitialiser',
                        ));
                if (result == null || !result) return;

                cm.resetConfiguration(
                    advancedOptions: true, userOptions: false);

                if (context.mounted) Navigator.pop(context);
              }
            : null,
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
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(widget.label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Checkbox(
              value: value,
              onChanged: (_) => onChanged(!value),
              fillColor: MaterialStateProperty.resolveWith((state) {
                if (state.contains(MaterialState.selected)) {
                  return tm.backgroundColorDark;
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            label: thumbLabel,
            activeColor: tm.backgroundColorDark,
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
    return ParchmentDialog(
      title: title,
      width: 400,
      height: 200,
      content: Text(message),
      acceptButtonTitle: yesTitle,
      onCancel: () => Navigator.pop(context, false),
      onAccept: () => Navigator.pop(context, true),
    );
  }
}
