import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/database_result.dart';

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
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'DatabaseManager should not be initialized twice');
    }
    _instance = DatabaseManager._internal();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
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
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthenticationException(
            message: 'Ce courriel est déjà enregistré');
      } else {
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }

    _finalizeLoggingIn();
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
    // Make sure it is not already taken
    final teamNames = await _teamNamesCollection.get();
    if (teamNames.docs
        .any((element) => element.id.toLowerCase() == name.toLowerCase())) {
      throw AuthenticationException(message: 'Ce nom d\'équipe existe déjà...');
    }

    // Adds it to the database
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    await _teamNamesCollection.doc(name).set({});

    // Notify the listeners
    onTeamNameSet.notifyListeners();
    _notifyIfFullyLoggedIn();
  }

  ///
  /// Log in with the given email and password
  Future<void> logIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw AuthenticationException(
            message: 'Adresse courriel ou mot de passe incorrect');
      } else {
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }

    _finalizeLoggingIn();
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    onLoggedOut.notifyListeners();
  }

  void _finalizeLoggingIn() {
    // Launch the waiting for email verification, do not wait for it to finish
    // because the UI need to update
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
        throw AuthenticationException(
            message: 'L\'utilisateur s\'est déconnecté');
      }
    }

    onEmailVerified.notifyListeners();
    _notifyIfFullyLoggedIn();
  }

  /////////////////////////////////////////
  //// COMMUNICATION RELATED FUNCTIONS ////
  /////////////////////////////////////////

  ///
  /// Returns the collection of results
  CollectionReference<Map<String, dynamic>> get _teamResultsCollection =>
      FirebaseFirestore.instance
          .collection('results')
          .doc('v1.0.0')
          .collection('teams');

  CollectionReference<Map<String, dynamic>> get _teamNamesCollection =>
      FirebaseFirestore.instance.collection('teams');

  static const String bestStationKey = 'bestStation';
  static const String bestPlayersKey = 'bestPlayers';
  static const String bestPlayersNameKey = 'names';
  static const String bestPlayersScoreKey = 'score';

  ///
  /// Returns the name of the current team
  String get teamName => FirebaseAuth.instance.currentUser!.displayName!;

  ///
  /// Returns all the stations for all the teams
  List<TeamResult>? _teamResultsCache;
  Future<List<TeamResult>> _getTeamsResults() async {
    _teamResultsCache ??= (await _teamResultsCollection
            .orderBy(bestStationKey, descending: true)
            .get())
        .docs
        .map((e) => TeamResult.fromFirebaseQuery(e))
        .toList();
    return [..._teamResultsCache!];
  }

  ///
  /// Returns all the scores for all the best players
  Future<List<PlayerResult>> _getPlayersResult() async {
    final bestPlayers = (await _getTeamsResults())
        .map((e) => e.bestPlayers)
        .expand((e) => e)
        .toList();
    bestPlayers.sort((a, b) => b.value.compareTo(a.value));

    return bestPlayers;
  }

  ///
  /// Returns the best result for a given team
  Future<TeamResult?> _getResultsOf({required String teamName}) async =>
      (await _getTeamsResults())
          .firstWhereOrNull((team) => team.name == teamName);

  ///
  /// Send a new train reached score to the database
  Future<void> _putTeamResults({required TeamResult team}) async {
    await _teamResultsCollection.doc(team.name).set({
      bestStationKey: team.bestStation,
      bestPlayersKey: team.bestPlayers.isEmpty
          ? null
          : {
              bestPlayersNameKey: team.bestPlayers.map((e) => e.name).toList(),
              bestPlayersScoreKey: team.bestPlayers.first.score
            }
    });

    // Update the cache results
    final index = _teamResultsCache!.indexWhere((e) => e.name == team.name);
    if (index >= 0) {
      _teamResultsCache![index] = team;
    } else {
      _teamResultsCache!.add(team);
    }
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
      {required int stationReached, required List<Player> bestPlayers}) async {
    _isSendingData = true;

    // Get the previous result for this team to see if we need to update it
    final previousTeamResult = await _getResultsOf(teamName: teamName);
    final List<PlayerResult> previousBestPlayers =
        previousTeamResult == null ? [] : [...previousTeamResult.bestPlayers];
    final previousBestScore =
        previousBestPlayers.isEmpty ? -1 : previousBestPlayers.first.score;
    final currentBestScore = bestPlayers.isEmpty ? -1 : bestPlayers.first.score;
    previousTeamResult?.bestPlayers.clear();

    // Construct the TeamResult without best players
    final teamResults =
        previousTeamResult == null || stationReached > previousTeamResult.value
            ? TeamResult(name: teamName, bestStation: stationReached)
            : previousTeamResult;

    // Set the best players for the team
    if (currentBestScore >= previousBestScore) {
      teamResults.bestPlayers.addAll(bestPlayers
          .map((e) =>
              PlayerResult(name: e.name, score: e.score, teamName: teamName))
          .toList());
    }
    if (previousBestScore >= currentBestScore) {
      teamResults.bestPlayers.addAll(previousBestPlayers);
    }

    await _putTeamResults(team: teamResults);

    _isSendingData = false;
  }

  Future<TeamResult> getCurrentTeamResults() async {
    return await _getResultsOf(teamName: teamName) ??
        TeamResult(name: teamName, bestStation: -1);
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

    return out;
  }

  ///
  /// Returns the [top] best players accross all the teams. The [bestPlayers]
  /// is added to the list. If the players are not in the top, they are added at
  /// the bottom. If they are in the top, they are added at their rank.
  Future<List<PlayerResult>> getBestPlayers(
      {required int top, required List<Player>? bestPlayers}) async {
    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final out = await _getPlayersResult();

    // Add the current results if necessary (only the best one were fetched)
    if (bestPlayers != null) {
      for (final bestPlayer in bestPlayers) {
        final currentResult = PlayerResult(
            name: bestPlayer.name, score: bestPlayer.score, teamName: teamName);
        _insertResultInList(currentResult, out);
      }
    }

    _computeRanks(out);

    // If our score did not get to the top, add it at the bottom
    if (bestPlayers == null) {
      return out.sublist(0, min(top, out.length));
    } else {
      for (final bestPlayer in bestPlayers) {
        _limitNumberOfResults(
            top,
            PlayerResult(
                name: bestPlayer.name,
                score: bestPlayer.score,
                teamName: teamName),
            out);
      }
    }

    return out;
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

    final players = await _getPlayersResult();
    for (final team in out) {
      team.bestPlayers.addAll(players.where((e) => e.teamName == team.name));
    }

    return out;
  }

  @override
  Future<List<PlayerResult>> _getPlayersResult() async {
    final out = _dummyBestPlayersResults.entries.map((e) {
      return PlayerResult(name: e.key, score: e.value.$1, teamName: e.value.$2);
    }).toList();
    out.sort((a, b) => b.score.compareTo(a.score));

    return out;
  }

  @override
  Future<TeamResult> _getResultsOf({required String teamName}) async {
    final station = _dummyBestStationsResults[teamName] ?? 0;
    final bestPlayersOfTeam = _dummyBestPlayersResults.entries
        .where((e) => e.value.$2 == teamName)
        .map((e) =>
            PlayerResult(name: e.key, score: e.value.$1, teamName: teamName))
        .toList();

    return TeamResult(
        name: teamName, bestStation: station, bestPlayers: bestPlayersOfTeam);
  }

  @override
  Future<void> _putTeamResults({required TeamResult team}) async {
    _dummyBestStationsResults[team.name] = team.bestStation;
    _dummyBestPlayersResults.removeWhere((key, value) => value.$2 == team.name);
    _dummyBestPlayersResults.addAll({
      for (final player in team.bestPlayers)
        player.name: (player.score, team.name)
    });
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
