import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/difficulty.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/release_notes.dart';

const String _lastReleaseNotesShownDefault = '';

const _useCustomAdvancedOptionsDefault = false;

const _autoplayDefault = true;
const _shouldShowAutoplayDialogDefault = false;
const _autoplayDurationDefault = 25;

const _showAnswersTooltipDefault = false;
const _showLeaderBoardDefault = false;

const _roundDurationDefault = 120;
const _postRoundGracePeriodDurationDefault = 6;
const _postRoundShowCaseDurationDefault = 9;
const _cooldownPeriodDefault = 12;
const _cooldownPenaltyAfterStealDefault = 5;
const _timeBeforeScramblingLettersDefault = 15;

const _minimumWordsNumberDefault = 20;
const _maximumWordsNumberDefault = 40;

const _canStealDefault = true;
const _oneStationMaxPerRoundDefault = false;

const _numberOfPardonsDefault = 3;
const _boostTimeDefault = 30;
const _numberOfBoostsDefault = 1;
const _numberOfBoostRequestsNeededDefault = 3;

const _musicVolumeDefault = 0.3;
const _soundVolumeDefault = 1.0;

class ConfigurationManager {
  final List<ReleaseNotes> releaseNotes = const [
    ReleaseNotes(
      version: '0.1.0',
      codeName: 'Petit train va loin',
      notes: 'Le jeu est maintenant fonctionnel! On peut jouer en équipe sur '
          'Twitch pour faire avancer le petit Train du Nord',
    ),
    ReleaseNotes(version: '0.2.0', codeName: 'Travail d\'équipe', features: [
      FeatureNotes(
        description: 'Il est maintenant possible d\'enregistrer les scores '
            'des équipes pour les comparer au monde entier! Qui sera la '
            'meilleure équipe de cheminot\u00b7e\u00b7s?',
      ),
      FeatureNotes(
        description:
            'Travail sur la rapidité de l\'algorithme de génération des '
            'problèmes, ce qui permet d\'avoir des mots plus longs',
      ),
      FeatureNotes(
        description: 'Ajusté la difficulté des niveaux en ajoutant les '
            'lettres inutiles et cachées',
        userWhoRequested: 'Helene_Ducrocq',
        urlOfUserWhoRequested: 'https://twitch.tv/helene_ducrocq',
      ),
    ]),
    ReleaseNotes(
        version: '0.2.1',
        codeName: 'Ouverture sur le monde',
        notes: 'Le petit Train du Nord a pris les rails du monde entier! Et '
            'avec cela vient de nouvelles fonctionnalités!',
        features: [
          FeatureNotes(
            description:
                'Un mode autonome a été ajouté pour permettre au jeu de se '
                'lancer par lui-même',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description: 'Il est maintenant possible de voler des mots à ses '
                'cocheminot\u00b7e\u00b7s plus d\'une fois par ronde',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description:
                'Les réponses sont maintenant affichées quelques secondes à la '
                'fin de la ronde',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description:
                'Ajouté une boite d\'affichage pour les notes de versions, que '
                'vous êtes en train de lire!',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
        ]),
    ReleaseNotes(
      version: '0.3.0',
      codeName: 'Connais-toi toi-même',
      notes: 'La connaissance de soi est d\'une importance capitale. C\'est '
          'une meilleure représentation de vous-mêmes vous est proposée',
      features: [
        FeatureNotes(
          description:
              'Le petit train avance maintenant visuellement sur la carte, '
              'ce qui permet de voir les stations futures',
        ),
        FeatureNotes(
          description: 'Le score du ou de la meilleur\u00b7e cheminot\u00b7e '
              'est maintenant affiché dans le tableau final. Qui sera le ou la '
              'meilleur\u00b7e?',
          userWhoRequested: 'Kyaroline',
          urlOfUserWhoRequested: 'https://twitch.tv/kyaroline',
        ),
      ],
    ),
    ReleaseNotes(
      version: '0.3.1',
      codeName: 'Tous pour un et un pour un',
      notes:
          'Oui, la citation est bien "un pour tous", mais maintenant que l\'unique score '
          'du ou de la meilleure cheminot\u00b7e de l\'équipe est enregistré au '
          'tableau d\'honneur, nous aurons probablement droits à des élans '
          'd\'individualisme! Mais qui saura résister à l\'appel de la gloire '
          'pour faire avancer le train?',
      features: [
        FeatureNotes(
            description:
                'Le score du ou de la meilleure cheminot\u00b7e de l\'équipe est '
                'enregistré au tableau d\'honneur'),
        FeatureNotes(
            description:
                'Quelques ajustements pour améliorer le visuel des bulles de '
                'notification'),
        FeatureNotes(
            description:
                'Les feux d\'artifices ont maintenant leurs palettes de '
                'couleur individualisées'),
      ],
    ),
    ReleaseNotes(
      version: '0.3.2',
      codeName: 'Mes ami\u00b7e\u00b7s sont mes ennemi\u00b7e\u00b7s',
      notes:
          'Le Train de Mots est un jeu d\'équipe, jusqu\'à ce que ce ne le soit plus! '
          'Le jeu montre maintenant le joueur MVP de votre équipe de façon plus '
          'précise. Vous savez maintenant qui cibler pour devenir le ou la '
          'meilleur\u00b7e cheminot\u00b7e!',
      features: [
        FeatureNotes(
            description:
                'Le ou la joueuse MVP de votre équipe est maintenant affiché en or '
                'dans la page de fin de ronde. De plus, sa tuile est elle aussi '
                'affichée avec sa propre couleur lorsqu\'il ou elle trouve une solution'),
      ],
    ),
    ReleaseNotes(
      version: '0.3.3',
      codeName: 'Plus vites, plus fort, plus loin',
      notes:
          'Bien que le Train de mots est un jeu d\'équipe, une petite équipe '
          'ne devrait pas être pénalisée! Tout le monde peut maintenant partir '
          'vers le Nord!',
      features: [
        FeatureNotes(
            description:
                'La période de repos après avoir trouvé un mot est maintenant '
                'ajustée en fonction du nombre de joueurs présents.'),
        FeatureNotes(
            description:
                'Le jeu est maintenant garanti de trouver un mot avant la fin de '
                'la ronde, pour plus de plaisir sans attendre!'),
      ],
    ),
    ReleaseNotes(
      version: '0.3.4',
      codeName: 'Je vAzalée encore plus loin',
      notes:
          'Certain\u00b7e\u00b7s cheminot\u00b7e\u00b7s ont vu le Petit Train'
          'du Nord les priver de leurs prouesses. On aurait pu accepter cet état '
          'de fait... mais non! Et rendons à César ce qui est Azalee et réparons '
          'ce problème...',
      features: [
        FeatureNotes(
            description:
                'Réparation du bogue qui supprimait le score du ou de la meilleur\u00b7e '
                'cheminot\u00b7e de l\'équipe à la fin de la ronde si ce même joueur '
                'est le ou la MVP de la ronde courante',
            userWhoRequested: 'LaLoutreBurlesques',
            urlOfUserWhoRequested: 'https://twitch.tv/laloutreburlesques'),
      ],
    ),
    ReleaseNotes(
      version: '0.3.5',
      codeName: 'Le tintamare',
      notes:
          'Petit update pour indiquer aux joueurs et joueuses que le train a '
          'reculé derrière la station!',
      features: [
        FeatureNotes(
            description:
                'L\'animation des explosions a été réécrites pour permettre de '
                'l\'inverser. Cette inversion est utilisée pour indiquer que le '
                'train a reculé derrière la station'),
      ],
    ),
    ReleaseNotes(
      version: '0.3.6',
      codeName: 'Scintillement',
      notes:
          'Un petit ajustement pour rendre le jeu plus agréable pour les yeux!',
      features: [
        FeatureNotes(
            description:
                'Les étoiles scintillent maintenant dans le ciel de nuit!'),
      ],
    ),
    ReleaseNotes(
      version: '0.4.0',
      codeName: 'Liberté',
      notes:
          'Certains ont demandé de pouvoir modifier les règles du jeu, et bien soit! Modifions!',
      features: [
        FeatureNotes(
            description:
                'Les options de débogue sont rendues disponible pour le bonheur et le plaisir de tous!',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/NghtmrTV'),
        FeatureNotes(
            description:
                'Il est également possible de ne pas avancer de plus d\'une station par ronde',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/NghtmrTV'),
      ],
    ),
    ReleaseNotes(
      version: '1.0.0',
      codeName: 'Un peu plus haut, un peu plus loin',
      notes:
          'Le Petit train du Nord se sent mature et désire est enfin considéré comme '
          'quelque chose comme un grand train!',
      features: [
        FeatureNotes(
          description:
              'Plusieurs options débogueurs sont maintenant incluses dans la '
              'progression de difficulté du jeu.',
        ),
      ],
    ),
    ReleaseNotes(
      version: '1.0.1',
      codeName: 'Pardonnez-nous nos offenses',
      notes: 'Il est naturel de faire des erreurs et de demander le pardon.'
          'Jusqu\'à maintenant le Petit Train du Nord était sans pitié... '
          'Cette époque est révolue! Il est maintenant possible de pardonner '
          'un vol, mais choississez bien, vous n\'avez pas beaucoup de pardons '
          'en banque!',
      features: [
        FeatureNotes(
          description:
              'Il est maintenant possible de pardonner avec la commande: !pardon',
        ),
        FeatureNotes(
            description:
                'Il est maintenant possible de revoir les réponses après qu\'elles'
                'aient disparues',
            userWhoRequested: 'AlchimisteDesMots',
            urlOfUserWhoRequested: 'https://twitch.tv/alchimistedesmots'),
        FeatureNotes(
            description:
                'Il est également possible de booster le train avec la commande !boost'),
      ],
    ),
  ];

  bool get useDebugOptions => MocksConfiguration.showDebugOptions;

  ///
  /// Declare the singleton
  static ConfigurationManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'ConfigurationManager must be initialized before being used');
    }
    return _instance!;
  }

  static ConfigurationManager? _instance;
  ConfigurationManager._internal();

  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'ConfigurationManager should not be initialized twice');
    }
    _instance = ConfigurationManager._internal();

    instance._loadConfiguration();
    // We must wait for the GameManager to be initialized before listening to
    Future.delayed(Duration.zero, () => instance._listenToGameManagerEvents());
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = CustomCallback();
  final onMusicChanged = CustomCallback();
  final onSoundChanged = CustomCallback();

  ///
  /// The current algorithm used to generate the problems
  final Future<LetterProblem?> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) _problemGenerator = ProblemGenerator.generateFromRandomWord;
  Future<LetterProblem?> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) get problemGenerator => _problemGenerator;

  String _lastReleaseNotesShown = _lastReleaseNotesShownDefault;
  String get lastReleaseNotesShown => _lastReleaseNotesShown;
  set lastReleaseNotesShown(String value) {
    _lastReleaseNotesShown = value;
    _saveConfiguration();
  }

  bool _useCustomAdvancedOptions = _useCustomAdvancedOptionsDefault;
  bool get useCustomAdvancedOptions => _useCustomAdvancedOptions;
  set useCustomAdvancedOptions(bool value) {
    _useCustomAdvancedOptions = value;

    _saveConfiguration();
  }

  bool _autoplay = _autoplayDefault;
  bool get autoplay => _autoplay;
  set autoplay(bool value) {
    _autoplay = value;
    _saveConfiguration();
  }

  bool _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
  bool get shouldShowAutoplayDialog => _shouldShowAutoplayDialog;
  set shouldShowAutoplayDialog(bool value) {
    _shouldShowAutoplayDialog = value;
    _saveConfiguration();
  }

  Duration _autoplayDuration =
      const Duration(seconds: _autoplayDurationDefault);
  Duration get autoplayDuration => _autoplayDuration;
  set autoplayDuration(Duration value) {
    _autoplayDuration = value;
    _saveConfiguration();
  }

  bool _showAnswersTooltip = _showAnswersTooltipDefault;
  bool get showAnswersTooltip => _showAnswersTooltip;
  set showAnswersTooltip(bool value) {
    _showAnswersTooltip = value;
    _saveConfiguration();
  }

  bool _showLeaderBoard = _showLeaderBoardDefault;
  bool get showLeaderBoard => _showLeaderBoard;
  set showLeaderBoard(bool value) {
    _showLeaderBoard = value;
    _saveConfiguration();
  }

  Duration _roundDuration = const Duration(seconds: _roundDurationDefault);
  Duration get roundDuration => useCustomAdvancedOptions
      ? _roundDuration
      : const Duration(seconds: _roundDurationDefault);
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundGracePeriodDuration =
      const Duration(seconds: _postRoundGracePeriodDurationDefault);
  Duration get postRoundGracePeriodDuration => useCustomAdvancedOptions
      ? _postRoundGracePeriodDuration
      : const Duration(seconds: _postRoundGracePeriodDurationDefault);
  set postRoundGracePeriodDuration(Duration value) {
    _postRoundGracePeriodDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundShowCaseDuration =
      const Duration(seconds: _postRoundShowCaseDurationDefault);
  Duration get postRoundShowCaseDuration => useCustomAdvancedOptions
      ? _postRoundShowCaseDuration
      : const Duration(seconds: _postRoundShowCaseDurationDefault);
  set postRoundShowCaseDuration(Duration value) {
    _postRoundShowCaseDuration = value;
    _saveConfiguration();
  }

  Duration _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
  Duration get cooldownPeriod => useCustomAdvancedOptions
      ? _cooldownPeriod
      : const Duration(seconds: _cooldownPeriodDefault);
  set cooldownPeriod(Duration value) {
    _cooldownPeriod = value;
    _saveConfiguration();
  }

  Duration _cooldownPenaltyAfterSteal =
      const Duration(seconds: _cooldownPenaltyAfterStealDefault);
  Duration get cooldownPenaltyAfterSteal => useCustomAdvancedOptions
      ? _cooldownPenaltyAfterSteal
      : const Duration(seconds: _cooldownPenaltyAfterStealDefault);
  set cooldownPenaltyAfterSteal(Duration value) {
    _cooldownPenaltyAfterSteal = value;
    _saveConfiguration();
  }

  Duration _timeBeforeScramblingLetters =
      const Duration(seconds: _timeBeforeScramblingLettersDefault);
  Duration get timeBeforeScramblingLetters => useCustomAdvancedOptions
      ? _timeBeforeScramblingLetters
      : const Duration(seconds: _timeBeforeScramblingLettersDefault);
  set timeBeforeScramblingLetters(Duration value) {
    _timeBeforeScramblingLetters = value;
    _saveConfiguration();
  }

  int _minimumWordsNumber = _minimumWordsNumberDefault;
  int get minimumWordsNumber => useCustomAdvancedOptions
      ? _minimumWordsNumber
      : _minimumWordsNumberDefault;
  set minimumWordsNumber(int value) {
    if (_minimumWordsNumber == value) return;
    if (value > maximumWordsNumber) return;
    _minimumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordsNumber = _maximumWordsNumberDefault;
  int get maximumWordsNumber => useCustomAdvancedOptions
      ? _maximumWordsNumber
      : _maximumWordsNumberDefault;
  set maximumWordsNumber(int value) {
    if (_maximumWordsNumber == value) return;
    if (value < minimumWordsNumber) return;
    _maximumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  bool _canSteal = _canStealDefault;
  bool get canSteal => useCustomAdvancedOptions ? _canSteal : _canStealDefault;
  set canSteal(bool value) {
    _canSteal = value;
    _saveConfiguration();
  }

  bool _oneStationMaxPerRound = _oneStationMaxPerRoundDefault;
  bool get oneStationMaxPerRound => useCustomAdvancedOptions
      ? _oneStationMaxPerRound
      : _oneStationMaxPerRoundDefault;
  set oneStationMaxPerRound(bool value) {
    _oneStationMaxPerRound = value;
    _saveConfiguration();
  }

  int _numberOfPardons = _numberOfPardonsDefault;
  int get numberOfPardons => _numberOfPardons;
  set numberOfPardons(int value) {
    _numberOfPardons = value;
    _saveConfiguration();
  }

  Duration _boostTime = const Duration(seconds: _boostTimeDefault);
  Duration get boostTime => _boostTime;
  set boostTime(Duration value) {
    _boostTime = value;
    _saveConfiguration();
  }

  int _numberOfBoosts = _numberOfBoostsDefault;
  int get numberOfBoosts => _numberOfBoosts;
  set numberOfBoosts(int value) {
    _numberOfBoosts = value;
    _saveConfiguration();
  }

  int _numberOfBoostRequestsNeeded = _numberOfBoostRequestsNeededDefault;
  int get numberOfBoostRequestsNeeded => _numberOfBoostRequestsNeeded;
  set numberOfBoostRequestsNeeded(int value) {
    _numberOfBoostRequestsNeeded = value;
    _saveConfiguration();
  }

  double _musicVolume = _musicVolumeDefault;
  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value;
    onMusicChanged.notifyListeners();
    _saveConfiguration();
  }

  double _soundVolume = _soundVolumeDefault;
  double get soundVolume => _soundVolume;
  set soundVolume(double value) {
    _soundVolume = value;
    _saveConfiguration();
  }

  //// LISTEN TO GAME MANAGER ////
  void _listenToGameManagerEvents() {
    final gm = GameManager.instance;
    gm.onRoundIsPreparing.addListener(_reactToGameManagerEvent);
    gm.onNextProblemReady.addListener(_reactToGameManagerEvent);
    gm.onRoundStarted.addListener(_reactToGameManagerEvent);
    gm.onRoundIsOver.addListener(_reactToGameManagerEventWithParameter);
  }

  void _reactToGameManagerEvent() => onChanged.notifyListeners();
  void _reactToGameManagerEventWithParameter(_) => onChanged.notifyListeners();

  //// LOAD AND SAVE ////

  ///
  /// Serialize the configuration to a map
  Map<String, dynamic> serialize() {
    return {
      'lastReleaseNotesShown': lastReleaseNotesShown,
      'useDefaultAdvancedOptions': _useCustomAdvancedOptions,
      'autoplay': autoplay,
      'shouldShowAutoplayDialog': shouldShowAutoplayDialog,
      'autoplayDuration': autoplayDuration.inSeconds,
      'showAnswersTooltip': showAnswersTooltip,
      'showLeaderBoard': showLeaderBoard,
      'roundDuration': roundDuration.inSeconds,
      'postRoundGracePeriodDuration': postRoundGracePeriodDuration.inSeconds,
      'postRoundShowCaseDuration': postRoundShowCaseDuration.inSeconds,
      'cooldownPeriod': cooldownPeriod.inSeconds,
      'cooldownPenaltyAfterSteal': cooldownPenaltyAfterSteal.inSeconds,
      'timeBeforeScramblingLetters': timeBeforeScramblingLetters.inSeconds,
      'minimumWordsNumber': minimumWordsNumber,
      'maximumWordsNumber': maximumWordsNumber,
      'canSteal': canSteal,
      'oneStationMaxPerRound': oneStationMaxPerRound,
      'numberOfPardons': numberOfPardons,
      'boostTime': boostTime.inSeconds,
      'numberOfBoosts': numberOfBoosts,
      'numberOfBoostRequestsNeeded': numberOfBoostRequestsNeeded,
      'musicVolume': musicVolume,
      'soundVolume': soundVolume,
    };
  }

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
    onChanged.notifyListeners();
  }

  ///
  /// Load the configuration from the device
  void _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);

      _useCustomAdvancedOptions =
          map['useDefaultAdvancedOptions'] ?? _useCustomAdvancedOptionsDefault;

      _lastReleaseNotesShown =
          map['lastReleaseNotesShown'] ?? _lastReleaseNotesShownDefault;

      _autoplay = map['autoplay'] ?? _autoplayDefault;
      _shouldShowAutoplayDialog =
          map['shouldShowAutoplayDialog'] ?? _shouldShowAutoplayDialogDefault;
      _autoplayDuration = Duration(
          seconds: map['autoplayDuration'] ?? _autoplayDurationDefault);

      _showAnswersTooltip = false;
      _showLeaderBoard = map['showLeaderBoard'] ?? _showLeaderBoardDefault;

      _roundDuration =
          Duration(seconds: map['roundDuration'] ?? _roundDurationDefault);
      _postRoundGracePeriodDuration = Duration(
          seconds: map['postRoundGracePeriodDuration'] ??
              _postRoundGracePeriodDurationDefault);
      _postRoundShowCaseDuration = Duration(
          seconds: map['postRoundShowCaseDuration'] ??
              _postRoundShowCaseDurationDefault);
      _cooldownPeriod =
          Duration(seconds: map['cooldownPeriod'] ?? _cooldownPeriodDefault);
      _cooldownPenaltyAfterSteal = Duration(
          seconds: map['cooldownPenaltyAfterSteal'] ??
              _cooldownPenaltyAfterStealDefault);
      _timeBeforeScramblingLetters = Duration(
          seconds: map['timeBeforeScramblingLetters'] ??
              _timeBeforeScramblingLettersDefault);

      _minimumWordsNumber =
          map['minimumWordsNumber'] ?? _minimumWordsNumberDefault;
      _maximumWordsNumber =
          map['maximumWordsNumber'] ?? _maximumWordsNumberDefault;

      _canSteal = map['canSteal'] ?? _canStealDefault;
      _oneStationMaxPerRound =
          map['oneStationMaxPerRound'] ?? _oneStationMaxPerRoundDefault;

      _numberOfPardons = map['numberOfPardon'] ?? _numberOfPardonsDefault;
      _boostTime = Duration(seconds: map['boostTime'] ?? _boostTimeDefault);
      _numberOfBoosts = map['numberOfBoost'] ?? _numberOfBoostsDefault;
      _numberOfBoostRequestsNeeded = map['numberOfBoostRequestNeeded'] ??
          _numberOfBoostRequestsNeededDefault;

      _musicVolume = map['musicVolume'] ?? _musicVolumeDefault;
      _soundVolume = map['soundVolume'] ?? _soundVolumeDefault;

      _tellGameManagerToRepickProblem();
    }
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration(
      {required bool advancedOptions, required bool userOptions}) {
    if (userOptions) {
      _lastReleaseNotesShown = _lastReleaseNotesShownDefault;

      _autoplay = _autoplayDefault;
      _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
      _autoplayDuration = const Duration(seconds: _autoplayDurationDefault);

      _showAnswersTooltip = _showAnswersTooltipDefault;
      _showLeaderBoard = _showLeaderBoardDefault;

      _musicVolume = _musicVolumeDefault;
      _soundVolume = _soundVolumeDefault;

      ThemeManager.instance.reset();
    }

    if (advancedOptions) {
      _useCustomAdvancedOptions = _useCustomAdvancedOptionsDefault;

      _minimumWordsNumber = _minimumWordsNumberDefault;
      _maximumWordsNumber = _maximumWordsNumberDefault;

      _roundDuration = const Duration(seconds: _roundDurationDefault);
      _postRoundGracePeriodDuration =
          const Duration(seconds: _postRoundGracePeriodDurationDefault);
      _postRoundShowCaseDuration =
          const Duration(seconds: _postRoundShowCaseDurationDefault);
      _timeBeforeScramblingLetters =
          const Duration(seconds: _timeBeforeScramblingLettersDefault);
      _canSteal = _canStealDefault;
      _oneStationMaxPerRound = _oneStationMaxPerRoundDefault;
      _numberOfPardons = _numberOfPardonsDefault;
      _boostTime = const Duration(seconds: _boostTimeDefault);
      _numberOfBoosts = _numberOfBoostsDefault;
      _numberOfBoostRequestsNeeded = _numberOfBoostRequestsNeededDefault;
      _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
      _cooldownPenaltyAfterSteal =
          const Duration(seconds: _cooldownPenaltyAfterStealDefault);

      _tellGameManagerToRepickProblem();
      finalizeConfigurationChanges();
    }

    _saveConfiguration();
  }

  ///
  /// Get the difficulty for a given level
  final int lastLevelWithRules = 30;
  Difficulty difficulty(int level) {
    if (level < 3) {
      // Levels 1, 2 and 3
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 7,
        thresholdFactorOneStar: 0.35,
        thresholdFactorTwoStars: 0.5,
        thresholdFactorThreeStars: 0.75,
        hasUselessLetter: false,
        hasHiddenLetter: false,
      );
    } else if (level < 6) {
      // Levels 4, 5 and 6
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 10,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Vous vous enfoncez de plus en plus au Nord et les stations '
            's\'éloignent les unes des autres...\n'
            'Le travail d\'équipe de vos cheminot\u00b7e\u00b7s sera de la plus '
            'haute importance!',
        hasUselessLetter: false,
        hasHiddenLetter: false,
      );
    } else if (level < 9) {
      // Levels 7, 8 and 9
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 10,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Faites attention, cheminot\u00b7e\u00b7s, vous arrivez dans '
            'terres non défrichées!\n'
            'Malgré tous nos efforts, nous ne pouvons vous '
            'assurer que les lettres que vous recevrez vous seront toutes utiles!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: false,
      );
    } else if (level < 12) {
      // Levels 10, 11 and 12
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message:
            'Votre chemin est tout bonnement incroyable, cheminot\u00b7e\u00b7s! '
            'Vous avez réussi à vous frayer un chemin dans des terres inconnues!\n'
            'Mais les rails sont de plus en plus difficiles à entretenir... '
            'ne vous surprenez pas s\'il en manque des bouts',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 15) {
      // Levels 13, 14 and 15
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.65,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.9,
        message:
            'Encore une fois, toutes mes félicitations, cheminot\u00b7e\u00b7s! '
            'Vous avez emmené le Petit Train du Nord où nul autre n\'a osé aller, enfin depuis longtemps!\n'
            'Il sera de plus en plus difficile de vous aidez, mais nous faisons '
            'au mieux pour encore révéler les lettres qui vous seront utiles!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 15,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 18) {
      // Levels 16, 17 and 18
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.35,
        thresholdFactorTwoStars: 0.5,
        thresholdFactorThreeStars: 0.75,
        message:
            'Ô malheur cheminot\u00b7e\u00b7s! Le carburant se raréfie et les '
            'et les réserves s\'épuisent... Nous ne pouvons plus nous permettre '
            'des petites avancées! Il faudra donc trouver des mots plus longs '
            'pour avancer!\n'
            'Bonne chance pour la suite!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 15,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 21) {
      // Levels 19, 20 and 21
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Nous commençons à ne plus pouvoir suivre votre rythme, '
            'cheminot\u00b7e\u00b7s, et les communications deviennent difficiles...\n'
            'Notre équipe continue de faire de son mieux pour vous aider, mais '
            'ne comptez plus trop sur nous!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 24) {
      // Levels 22, 23 and 24
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.65,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.9,
        message:
            'Cheminot\u00b7e\u00b7s, vou... atteignez maintenant la limit... '
            'de nos communicat... À partir d\'ici, vo... êtes seul\u00b7e\u00b7s '
            'dans cette aventu..!\n'
            'Nous vous souh...ons bonne chance dans votre quête du Nord!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 15,
      );
    } else if (level < 27) {
      // Levels 25, 26 and 27
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.7,
        thresholdFactorTwoStars: 0.85,
        thresholdFactorThreeStars: 0.95,
        message: '... .., ... ..\n..... ... ..!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 15,
      );
    } else {
      // Levels 28 and above
      return const Difficulty(
        nbLettersOfShortestWord: 6,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.75,
        thresholdFactorTwoStars: 0.90,
        thresholdFactorThreeStars: 1.0,
        message: 'OH! OH! OH!\n'
            'Bonjour cheminot\u00b7e\u00b7s! Que faites vous ici? Mon rennes '
            'vous a vu passer il y a quelques instants! OH! OH! OH!\n'
            'Vous entrez dans les terres du Pôle Nord! Le chemin est arride et '
            'difficile ici... Je vous souhaite bonne chance! OH! OH! OH!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: -1,
      );
    }
  }

  //// MODIFYING THE CONFIGURATION ////

  ///
  /// If it is currently possible to change the duration of the round
  bool get canChangeDurations =>
      GameManager.instance.gameStatus != GameStatus.roundStarted;

  ///
  /// If it is currently possible to change the problem picker rules
  bool get canChangeProblem =>
      GameManager.instance.gameStatus == GameStatus.initializing ||
      GameManager.instance.gameStatus == GameStatus.roundReady;

  void _tellGameManagerToRepickProblem() =>
      GameManager.instance.rulesHasChanged(shouldRepickProblem: true);

  void finalizeConfigurationChanges() {
    GameManager.instance.rulesHasChanged(repickNow: true);
  }
}
