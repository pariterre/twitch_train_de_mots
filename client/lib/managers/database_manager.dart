import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:common/models/custom_callback.dart';
import 'package:common/models/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/managers/mocks_configuration.dart';
import 'package:train_de_mots/models/database_result.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/player.dart';

final _logger = Logger('DatabaseManager');

class DatabaseManager {
  /// Declare the singleton
  static DatabaseManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'DatabaseManager must be initialized before being used');
    }
    return _instance!;
  }

  static DatabaseManager? _instance;
  DatabaseManager._internal();

  static Future<void> initialize() async {
    _logger.config('Initializing DatabaseManager...');
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'DatabaseManager should not be initialized twice');
    }
    _instance = DatabaseManager._internal();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    if (MocksConfiguration.useDatabaseEmulators) {
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }
    _logger.config('DatabaseManager initialized');
  }

  ////////////////////////////////
  //// AUTH RELATED FUNCTIONS ////
  ////////////////////////////////

  final onEmailVerified = CustomCallback();
  final onTeamNameSet = CustomCallback();
  final onLoggedIn = CustomCallback();
  final onFullyLoggedIn = CustomCallback();
  final onLoggedOut = CustomCallback();

  ///
  /// Create a new user with the given email and password
  Future<void> signIn({required String email, required String password}) async {
    _logger.info('Creating a new user with email $email...');
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthenticationException(
            message: 'Ce courriel est déjà enregistré');
      } else {
        _logger.severe('Error while creating a new user: $e');
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }

    _finalizeLoggingIn();
    _logger.info('User created');
  }

  ///
  /// Return true if the user is logged in
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get isLoggedIn => isSignedIn && isEmailVerified && hasTeamName;
  bool get isLoggedOut => !isLoggedIn;
  bool get isEmailVerified =>
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  bool get hasTeamName =>
      FirebaseAuth.instance.currentUser?.displayName != null;

  ///
  /// Set the team name for the current user
  Future<void> setTeamName(String name) async {
    _logger.info('Setting team name to $name...');

    // Make sure it is not already taken
    final teamNames = await _teamNamesCollection.get();
    if (teamNames.docs.any((element) =>
        element.data()[teamNameKey].toLowerCase() == name.toLowerCase())) {
      _logger.warning('Team name $name already exists');
      throw AuthenticationException(message: 'Ce nom d\'équipe existe déjà...');
    }

    // Adds it to the database
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    await _teamNamesCollection
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .set({teamNameKey: FirebaseAuth.instance.currentUser!.displayName!});

    // Notify the listeners
    onTeamNameSet.notifyListeners();
    _notifyIfFullyLoggedIn();
    _logger.config('Team name set');
  }

  ///
  /// Log in with the given email and password
  Future<void> logIn({required String email, required String password}) async {
    _logger.info('Logging in with email $email...');
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw AuthenticationException(
            message: 'Adresse courriel ou mot de passe incorrect');
      } else {
        _logger.severe('Error while logging in: $e');
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }

    _finalizeLoggingIn();
    _logger.info('Logged in');
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    _logger.info('Logging out...');
    await FirebaseAuth.instance.signOut();
    onLoggedOut.notifyListeners();
    _logger.info('Logged out');
  }

  void _finalizeLoggingIn() {
    // Launch the waiting for email verification, do not wait for it to finish
    // because the UI needs to update
    _checkForEmailVerification();

    onLoggedIn.notifyListeners();
    _notifyIfFullyLoggedIn();
  }

  void _notifyIfFullyLoggedIn() {
    if (isEmailVerified && hasTeamName) {
      onFullyLoggedIn.notifyListeners();
    }
  }

  ///
  /// Send a password reset email to the given email
  void resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  ///
  /// Wait for the email to be verified by the user
  Future<void> _checkForEmailVerification() async {
    _logger.info('Checking for email verification...');
    if (!isEmailVerified) {
      FirebaseAuth.instance.currentUser!.sendEmailVerification();

      while (FirebaseAuth.instance.currentUser != null && !isEmailVerified) {
        try {
          await FirebaseAuth.instance.currentUser!.reload();
        } catch (_) {
          // pass
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (FirebaseAuth.instance.currentUser == null) {
        _logger
            .warning('User disconnected while waiting for email verification');
        throw AuthenticationException(
            message: 'L\'utilisateur s\'est déconnecté');
      }
    }

    onEmailVerified.notifyListeners();
    _notifyIfFullyLoggedIn();
    _logger.info('Email verified');
  }

  /////////////////////////////////////////
  //// COMMUNICATION RELATED FUNCTIONS ////
  /////////////////////////////////////////

  ///
  /// Returns the collection of results
  CollectionReference<Map<String, dynamic>> get _teamResultsCollection =>
      FirebaseFirestore.instance
          .collection('results')
          .doc('v1.0.1')
          .collection('teams');

  CollectionReference<Map<String, dynamic>> get _teamNamesCollection =>
      FirebaseFirestore.instance.collection('teams');

  CollectionReference<Map<String, dynamic>> get _wordProblemCollection =>
      FirebaseFirestore.instance
          .collection('results')
          .doc('v1.0.1')
          .collection('letterProblems');

  static const String bestStationKey = 'bestStation';
  static const String teamNameKey = 'teamName';
  static const String mvpPlayersKey = 'bestPlayers';
  static const String mvpPlayersNameKey = 'names';
  static const String mvpPlayersScoreKey = 'score';

  ///
  /// Returns the name of the current team
  String get teamName => FirebaseAuth.instance.currentUser!.displayName!;

  ///
  /// Returns all the stations for all the teams
  List<TeamResult>? _teamResultsCache;
  Future<List<TeamResult>> _getTeamsResults() async {
    _logger.info('Fetching all the teams results...');
    _teamResultsCache ??= (await _teamResultsCollection
            .orderBy(bestStationKey, descending: true)
            .get())
        .docs
        .map((e) => TeamResult.fromFirebaseQuery(e))
        .toList();
    _logger.info('Fetched all the teams results');
    return [..._teamResultsCache!];
  }

  ///
  /// Returns all the scores for all the mvp players
  Future<List<PlayerResult>> _getAllMvpPlayersResult() async {
    _logger.info('Fetching all the mvp players results...');
    final mvpPlayers = (await _getTeamsResults())
        .map((e) => e.mvpPlayers)
        .expand((e) => e)
        .toList();
    mvpPlayers.sort((a, b) => b.value.compareTo(a.value));

    _logger.info('Fetched all the mvp players results');
    return mvpPlayers;
  }

  ///
  /// Returns the best result for a given team
  Future<TeamResult?> _getResultsOf({required String teamName}) async {
    _logger.info('Fetching the results of team $teamName...');
    final results = (await _getTeamsResults())
        .firstWhereOrNull((team) => team.name == teamName);
    _logger.info('Fetched the results of team $teamName');
    return results;
  }

  ///
  /// Send a new train reached score to the database
  Future<void> _putTeamResults({required TeamResult team}) async {
    _logger.info('Sending the results of team ${team.name}...');
    await _teamResultsCollection
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      teamNameKey: team.name,
      bestStationKey: team.bestStation,
      mvpPlayersKey: team.mvpPlayers.isEmpty
          ? null
          : {
              mvpPlayersNameKey: team.mvpPlayers.map((e) => e.name).toList(),
              mvpPlayersScoreKey: team.mvpPlayers.first.score
            }
    });

    // Update the cache results
    // TODO: Do we need to sort the cache after updating it?
    final index = _teamResultsCache!.indexWhere((e) => e.name == team.name);
    if (index >= 0) {
      _teamResultsCache![index] = team;
    } else {
      _teamResultsCache!.add(team);
    }
    _logger.info('Sent the results of team ${team.name}');
  }

  ////////////////////////////////
  //// GAME RELATED FUNCTIONS ////
  ////////////////////////////////

  ///
  /// Simple mutex to wait for data to be sent before fetching
  bool _isSendingData = false;

  ///
  /// Send a new score to the database
  Future<void> sendResults(
      {required int stationReached, required List<Player> mvpPlayers}) async {
    _logger.info('Sending results to the database...');
    _isSendingData = true;

    // Get the previous result for this team to see if we need to update it
    final previousTeamResult = await _getResultsOf(teamName: teamName);
    final List<PlayerResult> previousBestPlayers =
        previousTeamResult == null ? [] : [...previousTeamResult.mvpPlayers];
    final previousBestScore =
        previousBestPlayers.isEmpty ? -1 : previousBestPlayers.first.score;
    final currentBestScore = mvpPlayers.isEmpty ? -1 : mvpPlayers.first.score;

    // Construct the TeamResult without mvp players
    previousTeamResult?.mvpPlayers.clear();
    final teamResults =
        previousTeamResult == null || stationReached > previousTeamResult.value
            ? TeamResult(name: teamName, bestStation: stationReached)
            : previousTeamResult;

    // Set the mvp players for the team
    if (currentBestScore >= previousBestScore) {
      teamResults.mvpPlayers.addAll(mvpPlayers
          .map((e) =>
              PlayerResult(name: e.name, score: e.score, teamName: teamName))
          .toList());
    }
    if (previousBestScore >= currentBestScore) {
      final currentMvpNames = teamResults.mvpPlayers.map((e) => e.name);
      teamResults.mvpPlayers.addAll(
          previousBestPlayers.where((e) => !currentMvpNames.contains(e.name)));
    }

    await _putTeamResults(team: teamResults);

    _isSendingData = false;
    _logger.info('Sent results to the database');
  }

  Future<TeamResult> getCurrentTeamResults() async {
    _logger.info('Fetching the results of team $teamName...');
    final results = await _getResultsOf(teamName: teamName) ??
        TeamResult(name: teamName, bestStation: -1);
    _logger.info('Fetched the results of team $teamName');
    return results;
  }

  ///
  /// Returns all the stations for all the teams up to [top]
  /// The [stationReached] is the station reached by the current team
  /// If the current team is not in the [top], it will be added at the bottom
  /// Otherwise, it will be added at its rank
  Future<List<TeamResult>> getBestTrainStationsReached({
    required int top,
    required int? stationReached,
  }) async {
    _logger.info('Fetching the best train stations reached...');

    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    List<TeamResult> out = await _getTeamsResults();

    // Add the current results if necessary (only the best one were fetched)
    final currentResult = stationReached == null
        ? null
        : TeamResult(name: teamName, bestStation: stationReached);

    if (currentResult != null) _insertResultInList(currentResult, out);

    _computeRanks(out);

    // If our score did not get to the top, add it at the bottom
    if (currentResult == null) {
      out = out.sublist(0, min(top, out.length));
    } else {
      _limitNumberOfResults(top, currentResult, out);
    }

    _logger.info('Fetched the best train stations reached');
    return out;
  }

  ///
  /// Returns the [top] mvp players accross all the teams. The [mvpPlayers]
  /// is added to the list. If the players are not in the top, they are added at
  /// the bottom. If they are in the top, they are added at their rank.
  Future<List<PlayerResult>> getBestPlayers(
      {required int top, required List<Player>? mvpPlayers}) async {
    _logger.info('Fetching the best players...');

    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final out = await _getAllMvpPlayersResult();

    // Add the current results if necessary (only the best one were fetched)
    if (mvpPlayers != null) {
      for (final mvpPlayer in mvpPlayers) {
        final currentResult = PlayerResult(
            name: mvpPlayer.name, score: mvpPlayer.score, teamName: teamName);
        _insertResultInList(currentResult, out);
      }
    }

    _computeRanks(out);

    // If our score did not get to the top, add it at the bottom
    if (mvpPlayers == null) {
      return out.sublist(0, min(top, out.length));
    } else {
      for (final mvpPlayer in mvpPlayers) {
        _limitNumberOfResults(
            top,
            PlayerResult(
                name: mvpPlayer.name,
                score: mvpPlayer.score,
                teamName: teamName),
            out);
      }
    }

    _logger.info('Fetched the best players');
    return out;
  }

  ////////////////////////////
  /// WORD PROBLEM RELATED ///
  ////////////////////////////

  ///
  /// Returns a random letter problem
  Future<String?> fetchLetterProblem({
    required bool withUselessLetter,
    required int minNbLetters,
    required int maxNbLetters,
  }) async {
    _logger.info('Fetching a letter problem...');

    // find a random number of letters to pick from
    final databaseKeys = List.generate(
            maxNbLetters - minNbLetters + 1, (index) => index + minNbLetters)
        .map((index) => '${index}letters')
        .toList();

    final random = Random();

    Map<String, dynamic>? words;
    while (true) {
      if (databaseKeys.isEmpty) {
        _logger.info('No letter problem found');
        return null;
      }

      final key = databaseKeys.removeAt(random.nextInt(databaseKeys.length));
      words = (await _wordProblemCollection.doc(key).get()).data();
      if (words != null) break;
    }

    if (withUselessLetter) {
      words.removeWhere((key, value) => !value['hasUseless']);
    }
    if (words.isEmpty) {
      _logger.info('No letter problem found');
      return null;
    }

    _logger.info('Fetched a letter problem');
    return words.keys.toList()[random.nextInt(words.length)];
  }

  Future<void> sendLetterProblem({required LetterProblem problem}) async {
    _logger.info('Sending a letter problem to the database...');

    final letters = problem.letters;
    if (problem.hasUselessLetter) letters.removeAt(problem.uselessLetterIndex);

    if (!problem.hasUselessLetter) {
      // Do not override the existing problem if it is the same but was already
      // confirmed to have solutions with useless letters when the current one
      // does not have any
      final existing =
          (await _wordProblemCollection.doc('${letters.length}letters').get())
              .data();

      if (existing?.containsKey(letters.join()) ?? false) {
        _logger.info('Letter problem already exists');
        return;
      }
    }

    await _wordProblemCollection.doc('${letters.length}letters').set({
      letters.join(): {
        'nbSolutions': problem.solutions.length,
        'hasUseless': problem.hasUselessLetter
      }
    }, SetOptions(merge: true));

    _logger.info('Sent a letter problem to the database');
  }
}

class DatabaseManagerMock extends DatabaseManager {
  bool _dummyIsSignedIn = false;
  String _dummyEmail = 'train@pariterre.net';
  bool _emailIsVerified = true;
  String _dummyTeamName = 'Les Bleuets';
  String _dummyPassword = '123456';
  Map<String, int> _dummyBestStationsResults = {};
  Map<String, (int, String)> _dummyBestPlayersResults = {};

  DatabaseManagerMock._internal() : super._internal();

  static Future<void> initialize({
    bool? dummyIsSignedIn,
    String? dummyEmail,
    bool? emailIsVerified,
    String? dummyTeamName,
    String? dummyPassword,
    Map<String, int>? dummyBestStationResults,
    Map<String, (int, String)>? dummyBestPlayerResults,
  }) async {
    if (DatabaseManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          'DatabaseManager should not be initialized twice');
    }

    DatabaseManager._instance = DatabaseManagerMock._internal();

    final mock = DatabaseManager._instance as DatabaseManagerMock;
    mock._dummyIsSignedIn = dummyIsSignedIn ?? mock._dummyIsSignedIn;
    mock._dummyEmail = dummyEmail ?? mock._dummyEmail;
    mock._emailIsVerified = emailIsVerified ?? mock._emailIsVerified;
    mock._dummyTeamName = dummyTeamName ?? mock._dummyTeamName;
    mock._dummyPassword = dummyPassword ?? mock._dummyPassword;
    mock._dummyBestStationsResults =
        dummyBestStationResults ?? mock._dummyBestStationsResults;
    mock._dummyBestPlayersResults =
        dummyBestPlayerResults ?? mock._dummyBestPlayersResults;
  }

  ///////////////////////
  //// AUTH MOCKINGS ////
  ///////////////////////

  @override
  String get teamName => _dummyTeamName;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email == _dummyEmail) {
      throw AuthenticationException(message: 'Ce courriel est déjà enregistré');
    }

    _dummyEmail = email;
    _dummyPassword = password;
    _dummyIsSignedIn = true;

    _finalizeLoggingIn();
  }

  @override
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    if (_dummyEmail != email || _dummyPassword != password) {
      throw AuthenticationException(
          message: 'Addresse courriel ou mot de passe incorrect');
    }
    _dummyIsSignedIn = true;

    _finalizeLoggingIn();
  }

  @override
  Future<void> logOut() async {
    _dummyIsSignedIn = false;
    onLoggedOut.notifyListeners();
  }

  @override
  Future<void> _checkForEmailVerification() async {
    if (!isEmailVerified) {
      // Simulate the time it takes to verify the email
      await Future.delayed(const Duration(seconds: 5));
    }

    _emailIsVerified = true;
    onEmailVerified.notifyListeners();
    _notifyIfFullyLoggedIn();
  }

  @override
  void resetPassword(String email) {
    // Do nothing
  }

  @override
  bool get isSignedIn => _dummyIsSignedIn;

  @override
  bool get isEmailVerified => _emailIsVerified;

  @override
  bool get hasTeamName => true;

  @override
  Future<void> setTeamName(String name) async {
    if (_dummyBestStationsResults.containsKey(name)) {
      throw AuthenticationException(message: 'Ce nom d\'équipe existe déjà...');
    }

    _dummyTeamName = name;
    onTeamNameSet.notifyListeners();
    _notifyIfFullyLoggedIn();
  }

  ////////////////////////////////
  //// COMMUNICATION MOCKINGS ////
  ////////////////////////////////

  @override
  Future<List<TeamResult>> _getTeamsResults() async {
    final out = _dummyBestStationsResults.entries
        .map((e) => TeamResult(name: e.key, bestStation: e.value))
        .toList();
    out.sort((a, b) => b.bestStation.compareTo(a.bestStation));

    final players = await _getAllMvpPlayersResult();
    for (final team in out) {
      team.mvpPlayers.addAll(players.where((e) => e.teamName == team.name));
    }

    return out;
  }

  @override
  Future<List<PlayerResult>> _getAllMvpPlayersResult() async {
    final out = _dummyBestPlayersResults.entries.map((e) {
      return PlayerResult(name: e.key, score: e.value.$1, teamName: e.value.$2);
    }).toList();
    out.sort((a, b) => b.score.compareTo(a.score));

    return out;
  }

  @override
  Future<TeamResult> _getResultsOf({required String teamName}) async {
    final station = _dummyBestStationsResults[teamName] ?? 0;
    final mvpPlayersOfTeam = _dummyBestPlayersResults.entries
        .where((e) => e.value.$2 == teamName)
        .map((e) =>
            PlayerResult(name: e.key, score: e.value.$1, teamName: teamName))
        .toList();

    return TeamResult(
        name: teamName, bestStation: station, mvpPlayers: mvpPlayersOfTeam);
  }

  @override
  Future<void> _putTeamResults({required TeamResult team}) async {
    _dummyBestStationsResults[team.name] = team.bestStation;
    _dummyBestPlayersResults.removeWhere((key, value) => value.$2 == team.name);
    _dummyBestPlayersResults.addAll({
      for (final player in team.mvpPlayers)
        player.name: (player.score, team.name)
    });
  }

  ///////////////////////////////////////
  //// WORD PROBLEM RELATED MOCKINGS ////
  ///////////////////////////////////////

  @override
  Future<String?> fetchLetterProblem({
    required bool withUselessLetter,
    required int minNbLetters,
    required int maxNbLetters,
  }) async =>
      null;

  @override
  Future<void> sendLetterProblem({required LetterProblem problem}) async {
    // Do nothing
  }
}

///
/// This function will take a list results and augment them with their rank
/// in the game.
void _computeRanks(List<DatabaseResult> results) {
  for (var i = 0; i < results.length; i++) {
    // Make a copy of the result
    final result = results[i];

    if (i == 0) {
      result.rank = 1;
    } else {
      // If the previous result is the same, we have the same rank, otherwise
      // we are one position ahead
      final previous = results[i - 1];
      result.rank = result.value == previous.value ? previous.rank : i + 1;
    }
  }
}

void _insertResultInList(DatabaseResult current, List<DatabaseResult> out) {
  final currentIndex =
      out.indexWhere((e) => e.name == current.name && e.value == current.value);

  if (currentIndex < 0) {
    final index = out.indexWhere((e) => e.value < current.value);
    if (index < 0) {
      out.add(current);
    } else {
      out.insert(index, current);
    }
  }
}

void _limitNumberOfResults(
    int top, DatabaseResult current, List<DatabaseResult> out) {
  final index =
      out.indexWhere((e) => e.name == current.name && e.value == current.value);

  // Something went wrong if we don't have our result in the list
  if (index < 0) return;

  if (index < top) {
    // If we are in the top, we only need to drop all the elements after top
    if (out.length > top) out.removeRange(top, out.length);

    // We can finally swap out the first index with our result
    final tp = out[index];
    final indexPrevious = out.indexWhere((e) => e.value == current.value);
    out[index] = out[indexPrevious];
    out[indexPrevious] = tp;
  } else {
    // If we are not in the top, we need to drop all the elements after top - 1
    // and append ourselves back
    final tp = out[index];
    if (out.length > top - 1) out.removeRange(top - 1, out.length);
    out.add(tp);
  }
}
