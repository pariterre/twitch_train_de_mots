import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/generic/models/exceptions.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/words_train/models/database_result.dart';
import 'package:train_de_mots/words_train/models/player.dart';

final _logger = Logger('DatabaseManager');

enum MvpType { score, stars }

class DatabaseManager {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  DatabaseManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } on UnsupportedError {
      throw 'DatabaseManager is not available on this platform, please use the mock';
    }

    if (MocksConfiguration.useFirebaseEmulators) {
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }

    _isInitialized = true;
    _logger.config('Ready');
  }

  ////////////////////////////////
  //// AUTH RELATED FUNCTIONS ////
  ////////////////////////////////

  final onEmailVerified = GenericListener<Function()>();
  final onTeamNameSet = GenericListener<Function()>();
  final onLoggedIn = GenericListener<Function()>();
  final onFullyLoggedIn = GenericListener<Function()>();
  final onLoggedOut = GenericListener<Function()>();

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
    onTeamNameSet.notifyListeners((callback) => callback());
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
    onLoggedOut.notifyListeners((callback) => callback());
    _logger.info('Logged out');
  }

  void _finalizeLoggingIn() {
    // Launch the waiting for email verification, do not wait for it to finish
    // because the UI needs to update
    _checkForEmailVerification();

    onLoggedIn.notifyListeners((callback) => callback());
    _notifyIfFullyLoggedIn();
  }

  void _notifyIfFullyLoggedIn() {
    if (isEmailVerified && hasTeamName) {
      onFullyLoggedIn.notifyListeners((callback) => callback());
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

    onEmailVerified.notifyListeners((callback) => callback());
    _notifyIfFullyLoggedIn();
    _logger.info('Email verified');
  }

  /////////////////////////////////////////
  //// COMMUNICATION RELATED FUNCTIONS ////
  /////////////////////////////////////////

  final _currentDatabaseVersion = 'v1.0.2';

  ///
  /// Returns the collection of results
  CollectionReference<Map<String, dynamic>> get _teamResultsCollection =>
      FirebaseFirestore.instance
          .collection('results')
          .doc(_currentDatabaseVersion)
          .collection('teams');

  DocumentReference<Map<String, dynamic>> get _teamCommentsDocument =>
      FirebaseFirestore.instance
          .collection('comments')
          .doc(_currentDatabaseVersion);

  CollectionReference<Map<String, dynamic>> get _teamNamesCollection =>
      FirebaseFirestore.instance.collection('teams');

  static const String bestStationKey = 'bestStation';
  static const String teamNameKey = 'teamName';
  static const String mvpScoreKey = 'bestPlayers';
  static const String mvpStarsKey = 'bestStars';
  static const String mvpPlayersNameKey = 'names';
  static const String mvpPlayersValueKey = 'score';

  ///
  /// Returns the name of the current team
  String? get teamName => FirebaseAuth.instance.currentUser?.displayName;

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
  Future<List<PlayerResult>> _getAllMvpPlayersResult(
      {required MvpType mvpType}) async {
    _logger.info('Fetching all the mvp players results...');
    final mvpPlayers = (await _getTeamsResults())
        .map((e) => switch (mvpType) {
              MvpType.score => e.mvpScore,
              MvpType.stars => e.mvpStars
            })
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
    _logger.fine('Fetched the results of team $teamName');
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
      mvpScoreKey: team.mvpScore.isEmpty
          ? null
          : {
              mvpPlayersNameKey: team.mvpScore.map((e) => e.name).toList(),
              mvpPlayersValueKey: team.mvpScore.first.value,
            },
      mvpStarsKey: team.mvpStars.isEmpty
          ? null
          : {
              mvpPlayersNameKey: team.mvpStars.map((e) => e.name).toList(),
              mvpPlayersValueKey: team.mvpStars.first.value,
            },
    });

    // Update the cache results
    final index = _teamResultsCache!.indexWhere((e) => e.name == team.name);
    if (index >= 0) {
      _teamResultsCache![index] = team;
    } else {
      _teamResultsCache!.add(team);
    }
    // Sort the cache in the case current team did better
    _teamResultsCache!.sort((a, b) => b.bestStation.compareTo(a.bestStation));

    _logger.info('Sent the results of team ${team.name}');
  }

  ///
  /// Put a new comment by the current team
  Future<void> putTeamComment({required String comment}) async {
    _logger.info('Sending the comment of team $teamName...');
    await _teamCommentsDocument
        .collection(FirebaseAuth.instance.currentUser!.uid)
        .add(
      {'comment': comment, 'timestamp': FieldValue.serverTimestamp()},
    );
    _logger.info('Sent the comment of team $teamName');
  }

  ////////////////////////////////
  //// GAME RELATED FUNCTIONS ////
  ////////////////////////////////

  ///
  /// Simple mutex to wait for data to be sent before fetching
  bool _isSendingData = false;

  void _updateTeamResultsMvp({
    required TeamResult teamResults,
    required List<Player> currentMvp,
    required List<PlayerResult> previousMvp,
    required MvpType mvpType,
  }) {
    if (isLoggedOut) return;

    final previousBestValue =
        previousMvp.isEmpty ? -1 : previousMvp.first.value;
    final currentBestValue = currentMvp.isEmpty
        ? -1
        : switch (mvpType) {
            MvpType.score => currentMvp.first.score,
            MvpType.stars => currentMvp.first.starsCollected
          };

    // Set the mvp score or stars for the team
    final mvp = switch (mvpType) {
      MvpType.score => teamResults.mvpScore,
      MvpType.stars => teamResults.mvpStars
    };
    if (currentBestValue >= previousBestValue) {
      mvp.addAll(currentMvp
          .map((e) => PlayerResult(
              name: e.name,
              value: switch (mvpType) {
                MvpType.score => currentMvp.first.score,
                MvpType.stars => currentMvp.first.starsCollected
              },
              teamName: teamName!))
          .toList());
    }
    if (previousBestValue >= currentBestValue) {
      final currentMvpNames = mvp.map((e) => e.name);
      mvp.addAll(previousMvp.where((e) => !currentMvpNames.contains(e.name)));
    }
  }

  ///
  /// Send a new score to the database
  Future<void> sendResults({
    required int stationReached,
    required List<Player> mvpScore,
    required List<Player> mvpStars,
  }) async {
    _logger.info('Sending results to the database...');
    _isSendingData = true;

    // Construct the TeamResult without mvp score and stars
    final previousTeamResult = await _getResultsOf(teamName: teamName!);
    final previousMvpScore =
        List<PlayerResult>.of(previousTeamResult?.mvpScore ?? []);
    final previousMvpStars =
        List<PlayerResult>.of(previousTeamResult?.mvpStars ?? []);
    previousTeamResult?.mvpScore.clear();
    previousTeamResult?.mvpStars.clear();
    final teamResults =
        previousTeamResult == null || stationReached > previousTeamResult.value
            ? TeamResult(name: teamName!, bestStation: stationReached)
            : previousTeamResult;

    // Set the mvp score and stars for the team
    _updateTeamResultsMvp(
        teamResults: teamResults,
        currentMvp: mvpScore,
        previousMvp: previousMvpScore,
        mvpType: MvpType.score);
    _updateTeamResultsMvp(
        teamResults: teamResults,
        currentMvp: mvpStars,
        previousMvp: previousMvpStars,
        mvpType: MvpType.stars);

    await _putTeamResults(team: teamResults);

    _isSendingData = false;
    _logger.info('Sent results to the database');
  }

  Future<TeamResult?> getCurrentTeamResult() async {
    if (isLoggedOut) return null;

    _logger.info('Fetching the results of team $teamName...');
    final results = await _getResultsOf(teamName: teamName!) ??
        TeamResult(name: teamName!, bestStation: -1);
    _logger.fine('Fetched the results of team $teamName');
    return results;
  }

  ///
  /// Returns all the stations for all the teams up to [top]
  /// The [stationReached] is the station reached by the current team
  /// If the current team is not in the [top], it will be added at the bottom
  /// Otherwise, it will be added at its rank
  Future<List<TeamResult>?> getBestTrainStationsReached({
    required int top,
    required int? stationReached,
  }) async {
    if (isLoggedOut) return null;
    _logger.info('Fetching the best train stations reached...');

    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    List<TeamResult> out = await _getTeamsResults();

    // Add the current results if necessary (only the best one were fetched)
    final currentResult = stationReached == null
        ? null
        : TeamResult(name: teamName!, bestStation: stationReached);

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
  /// Returns the [top] mvp player by score or stars accross all the teams. The [mvp]
  /// is added to the list. If the players are not in the top, they are added at
  /// the bottom. If they are in the top, they are added at their rank.
  Future<List<PlayerResult>?> getBestPlayers(
      {required int top,
      required List<Player>? mvp,
      required MvpType mvpType}) async {
    if (isLoggedOut) return null;
    _logger.info('Fetching the best players by ${mvpType.name}...');

    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final out = await _getAllMvpPlayersResult(mvpType: mvpType);

    // Add the current results if necessary (only the best one were fetched)
    if (mvp != null) {
      for (final mvpPlayer in mvp) {
        final value = switch (mvpType) {
          MvpType.score => mvpPlayer.score,
          MvpType.stars => mvpPlayer.starsCollected
        };
        final currentResult = PlayerResult(
            name: mvpPlayer.name, value: value, teamName: teamName!);
        _insertResultInList(currentResult, out);
      }
    }

    _computeRanks(out);

    // If our score did not get to the top, add it at the bottom
    if (mvp == null) {
      return out.sublist(0, min(top, out.length));
    } else {
      for (final mvpPlayer in mvp) {
        final value = switch (mvpType) {
          MvpType.score => mvpPlayer.score,
          MvpType.stars => mvpPlayer.starsCollected
        };
        _limitNumberOfResults(
            top,
            PlayerResult(
                name: mvpPlayer.name, value: value, teamName: teamName!),
            out);
      }
    }

    _logger.info('Fetched the best players');
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
  Map<String, (int, String)> _dummyBestPlayersScore = {};
  Map<String, (int, String)> _dummyBestPlayersStars = {};

  DatabaseManagerMock({
    bool? dummyIsSignedIn,
    String? dummyEmail,
    bool? emailIsVerified,
    String? dummyTeamName,
    String? dummyPassword,
    Map<String, int>? dummyBestStationResults,
    Map<String, (int, String)>? dummyBestPlayerScore,
    Map<String, (int, String)>? dummyBestPlayerStars,
  }) {
    _dummyIsSignedIn = dummyIsSignedIn ?? _dummyIsSignedIn;
    _dummyEmail = dummyEmail ?? _dummyEmail;
    _emailIsVerified = emailIsVerified ?? _emailIsVerified;
    _dummyTeamName = dummyTeamName ?? _dummyTeamName;
    _dummyPassword = dummyPassword ?? _dummyPassword;
    _dummyBestStationsResults =
        dummyBestStationResults ?? _dummyBestStationsResults;
    _dummyBestPlayersScore = dummyBestPlayerScore ?? _dummyBestPlayersScore;
    _dummyBestPlayersStars = dummyBestPlayerStars ?? _dummyBestPlayersStars;
  }

  @override
  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    _isInitialized = true;
    _logger.config('Ready');
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
    onLoggedOut.notifyListeners((callback) => callback());
  }

  @override
  Future<void> _checkForEmailVerification() async {
    if (!isEmailVerified) {
      // Simulate the time it takes to verify the email
      await Future.delayed(const Duration(seconds: 5));
    }

    _emailIsVerified = true;
    onEmailVerified.notifyListeners((callback) => callback());
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
    onTeamNameSet.notifyListeners((callback) => callback());
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

    final scores = await _getAllMvpPlayersResult(mvpType: MvpType.score);
    for (final team in out) {
      team.mvpScore.addAll(scores.where((e) => e.teamName == team.name));
    }

    final stars = await _getAllMvpPlayersResult(mvpType: MvpType.stars);
    for (final team in out) {
      team.mvpStars.addAll(stars.where((e) => e.teamName == team.name));
    }

    return out;
  }

  @override
  Future<List<PlayerResult>> _getAllMvpPlayersResult(
      {required MvpType mvpType}) async {
    final mvp = switch (mvpType) {
      MvpType.score => _dummyBestPlayersScore,
      MvpType.stars => _dummyBestPlayersStars
    };

    final out = mvp.entries.map((e) {
      return PlayerResult(name: e.key, value: e.value.$1, teamName: e.value.$2);
    }).toList();
    out.sort((a, b) => b.value.compareTo(a.value));

    return out;
  }

  @override
  Future<TeamResult> _getResultsOf({required String teamName}) async {
    final station = _dummyBestStationsResults[teamName] ?? 0;
    final mvpScoreOfTeam = _dummyBestPlayersScore.entries
        .where((e) => e.value.$2 == teamName)
        .map((e) =>
            PlayerResult(name: e.key, value: e.value.$1, teamName: teamName))
        .toList();
    final mvpStarsOfTeam = _dummyBestPlayersStars.entries
        .where((e) => e.value.$2 == teamName)
        .map((e) =>
            PlayerResult(name: e.key, value: e.value.$1, teamName: teamName))
        .toList();

    return TeamResult(
        name: teamName,
        bestStation: station,
        mvpScore: mvpScoreOfTeam,
        mvpStars: mvpStarsOfTeam);
  }

  @override
  Future<void> _putTeamResults({required TeamResult team}) async {
    _dummyBestStationsResults[team.name] = team.bestStation;
    _dummyBestPlayersScore.removeWhere((key, value) => value.$2 == team.name);
    _dummyBestPlayersScore.addAll({
      for (final player in team.mvpScore) player.name: (player.value, team.name)
    });
    _dummyBestPlayersStars.removeWhere((key, value) => value.$2 == team.name);
    _dummyBestPlayersStars.addAll({
      for (final player in team.mvpStars) player.name: (player.value, team.name)
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
