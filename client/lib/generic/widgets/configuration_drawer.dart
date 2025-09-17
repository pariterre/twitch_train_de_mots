import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/parchment_dialog.dart';
import 'package:train_de_mots/generic/widgets/word_train_about_dialog.dart';
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

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;
    final dm = Managers.instance.database;

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
                  style: tm.clientMainTextStyle
                      .copyWith(color: tm.textColor, fontSize: 24)),
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
                      onTap: !gm.hasPlayedAtLeastOnce ||
                              gm.gameStatus == WordsTrainGameStatus.roundStarted
                          ? () async {
                              await gm.requestTerminateRound();
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.extension,
                          color: Color.fromARGB(255, 100, 65, 165)),
                      title: const Text('Extension Twitch'),
                      onTap: () {
                        _connectExtension(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Image.asset(
                        'assets/images/youtube_logo.png',
                        width: 24,
                      ),
                      title: const Text('Tutoriel du Train de mots'),
                      onTap: () {
                        launchUrl(Uri.parse(
                            'https://www.youtube.com/watch?v=UvnS3X_7LAs/'));
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
                          'Descendre du train',
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
                          if (context.mounted) Navigator.pop(context);

                          await dm.logOut();
                          Managers.instance.twitch.disconnect();
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

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = Managers.instance.configuration;
    final tm = ThemeManager.instance;
    final em = Managers.instance.ebs;

    final subtitleStyle = tm.clientMainTextStyle
        .copyWith(color: Colors.black, fontWeight: FontWeight.bold);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Options du jeu', style: subtitleStyle),
                _BooleanInputField(
                    label:
                        'Relancer automatiquement les manches\n(effectif à la prochaine pause)',
                    value: cm.autoplay,
                    onChanged: (value) => cm.autoplay = value),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label: 'Afficher le tableau des cheminot·e·s',
                    value: cm.showLeaderBoard,
                    onChanged: (value) => cm.showLeaderBoard = value),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label:
                        'Activer les mini-jeux\n(nécessite l\'extension Twitch)',
                    enabled: em.isExtensionActive,
                    value: cm.useMinigames,
                    onChanged: (value) => cm.useMinigames = value),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label:
                        'Afficher l\'extension\n(sans effet si l\'extension Twitch overlay n\'est pas activée)',
                    enabled: em.isExtensionActive,
                    value: cm.showExtension,
                    onChanged: (value) => cm.showExtension = value),
                const SizedBox(height: 12),
                if (cm.useDebugOptions)
                  _BooleanInputField(
                      label: 'Montrer les réponses au survol\nde la souris',
                      value: cm.showAnswersTooltip,
                      onChanged: (value) => cm.showAnswersTooltip = value),
                const SizedBox(height: 12),
                Text('Volumes', style: subtitleStyle),
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
                  onChangedEnd: (value) => cm.onSoundVolumeChanged
                      .notifyListeners((callback) => callback()),
                  thumbLabel: '${(cm.soundVolume * 100).toInt()}%',
                ),
                const SizedBox(height: 12),
                Text('Thème visuel', style: subtitleStyle),
                const _ColorPickerInputField(
                    label: 'Choisir la couleur du thème'),
                const SizedBox(height: 24),
                const _FontSizePickerInputField(
                    label: 'Choisir la taille du thème'),
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
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);
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
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);
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

void _connectExtension(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (ctx) => ParchmentDialog(
        title: 'Extension Twitch',
        height: 550,
        width: 500,
        content: const Text(
            'L\'extension Twitch embelli grandement votre Voyage vers le Nord!\n'
            '\n'
            'Premièrement, celle-ci affiche les lettres à trouver directement sur l\'écran '
            'des cheminot·e·s. Cet affichage est synchrone avec le jeu, effaçant '
            'le retard occasionné par la diffusion. De plus, toutes les interactions '
            'des cheminot·e·s, commes les boosts ou les pardons, sont '
            'directement cliquable sur l\'extension.\n'
            '\n'
            'Des options d\'échanges de bits sont également disponibles pour une '
            'expérience encore plus originale pour les cheminot·e·s, '
            'permettant en même temps de monétiser votre chaîne.\n'
            '\n'
            'Pour une expérience optimale, vous êtes invité·e·s à choisir l\'option '
            '\u00ab overlay \u00bb lorsque vous activez l\'extension. Cette option crée une '
            'fenêtre déplaçable et redimensionnable directement sur l\'écran de vos cheminot·e·s.'),
        onAccept: () {
          launchUrl(Uri.parse(
              'https://dashboard.twitch.tv/extensions/539pzk7h6vavyzmklwy6msq6k3068x'));
          Navigator.pop(ctx);
        },
        acceptButtonTitle: 'Aller à l\'extension',
        onCancel: () => Navigator.pop(ctx),
        cancelButtonTitle: 'Fermer'),
  );
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
              content: Text('Attention cheminot·e!\n\n'
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

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = Managers.instance.configuration;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) =>
          cm.finalizeConfigurationChanges(),
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
                Tooltip(
                  message:
                      'Activer cette option empêche l\'envoi de vos résultats au tableau d\'honneur',
                  child: _BooleanInputField(
                      label: 'Utiliser les paramètres avancés',
                      value: cm.useCustomAdvancedOptions,
                      onChanged: (value) =>
                          cm.useCustomAdvancedOptions = value),
                ),
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
                  enabled: cm.useCustomAdvancedOptions && cm.canChangeProblem,
                  disabledTooltip: cm.useCustomAdvancedOptions
                      ? 'Le nombre de mots à trouver ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot'
                      : '',
                ),
                const SizedBox(height: 12),
                _IntegerInputField(
                  label: 'Durée d\'une manche (secondes)',
                  initialValue: cm.roundDuration.inSeconds.toString(),
                  onChanged: (value) =>
                      cm.roundDuration = Duration(seconds: value),
                  enabled: cm.useCustomAdvancedOptions && cm.canChangeDurations,
                  disabledTooltip: cm.useCustomAdvancedOptions
                      ? 'La durée d\'une manche ne peut pas être changée en cours de partie'
                      : '',
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
                  enabled: cm.useCustomAdvancedOptions && cm.canChangeDurations,
                  disabledTooltip: cm.useCustomAdvancedOptions
                      ? 'La durée d\'une manche ne peut pas être changée en cours de partie'
                      : '',
                ),
                const SizedBox(height: 12),
                _IntegerInputField(
                  label: 'Temps avant de mélanger les lettres (secondes)',
                  initialValue:
                      cm.timeBeforeScramblingLetters.inSeconds.toString(),
                  onChanged: (value) =>
                      cm.timeBeforeScramblingLetters = Duration(seconds: value),
                  enabled: cm.useCustomAdvancedOptions,
                ),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label: 'Voler un mot est permis',
                    value: cm.canSteal,
                    onChanged: (value) => cm.canSteal = value,
                    enabled: cm.useCustomAdvancedOptions),
                const SizedBox(height: 12),
                _BooleanInputField(
                    label: 'Utiliser les aides du contrôleur',
                    value: cm.canUseControllerHelper,
                    onChanged: (value) => cm.canUseControllerHelper = value,
                    enabled: cm.useCustomAdvancedOptions),
                const SizedBox(height: 12),
                _DoubleIntegerInputField(
                  label: 'Période de récupération (secondes)',
                  firstLabel: 'Normale',
                  firstInitialValue: cm.cooldownPeriod.inSeconds.toString(),
                  secondLabel: 'Pénalité voleur',
                  secondInitialValue:
                      cm.cooldownPenaltyAfterSteal.inSeconds.toString(),
                  enableSecond: cm.useCustomAdvancedOptions && cm.canSteal,
                  onChanged: (normal, stealer) {
                    cm.cooldownPeriod = Duration(seconds: normal);
                    cm.cooldownPenaltyAfterSteal = Duration(seconds: stealer);
                  },
                  enabled: cm.useCustomAdvancedOptions && cm.canChangeDurations,
                  disabledTooltip:
                      'Les périodes de récupération ne peuvent pas être\n'
                      'changées en cours de partie',
                ),
                const SizedBox(height: 12),
                _BooleanInputField(
                  label: 'Une seule station par manche',
                  value: cm.oneStationMaxPerRound,
                  onChanged: (value) => cm.oneStationMaxPerRound = value,
                  enabled: cm.useCustomAdvancedOptions,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        acceptButtonTitle: 'Fermer',
        onAccept: () => Navigator.pop(context),
        cancelButtonTitle: 'Réinitialiser la configuration',
        cancelButtonDisabledTooltip:
            'La configuration avancée ne peut pas être réinitialisée\n'
            'en cours de partie',
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
  const _BooleanInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final bool value;
  final Function(bool) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black : Colors.black54)),
            Checkbox(
              value: value,
              onChanged: enabled ? (_) => onChanged(!value) : null,
              fillColor: WidgetStateProperty.resolveWith((state) {
                if (state.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                if (state.contains(WidgetState.selected)) {
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
    this.onChangedEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String thumbLabel;
  final Function(double)? onChanged;
  final Function(double)? onChangedEnd;

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
            onChangeEnd: onChangedEnd,
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
