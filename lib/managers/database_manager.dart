import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/team_result.dart';

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
    final teamNames = await _teamsCollection.get();
    if (teamNames.docs
        .any((element) => element.id.toLowerCase() == name.toLowerCase())) {
      throw AuthenticationException(message: 'Ce nom d\'équipe existe déjà...');
    }

    // Adds it to the database
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    await _teamsCollection.doc(name).set({});

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
  CollectionReference<Map<String, dynamic>> get _resultsCollection =>
      FirebaseFirestore.instance
          .collection('results')
          .doc('v1.0.0')
          .collection('teams');

  CollectionReference<Map<String, dynamic>> get _teamsCollection =>
      FirebaseFirestore.instance.collection('teams');

  static const String bestStationKey = 'bestStation';
  static const String bestScoreKey = 'bestScore';

  ///
  /// Returns the name of the current team
  String get teamName => FirebaseAuth.instance.currentUser!.displayName!;

  ///
  /// Returns all the stations for all the teams
  Future<List<TeamResult>> _getAllResults({bool ordered = false}) async {
    late final List<QueryDocumentSnapshot<Map<String, dynamic>>> results;

    if (ordered) {
      results = (await _resultsCollection
              .orderBy(bestStationKey, descending: true)
              .get())
          .docs;
    } else {
      results = (await _resultsCollection.get()).docs;
    }
    return results.map((e) => TeamResult.fromFirebaseQuery(e)).toList();
  }

  ///
  /// Returns the best result for a given team
  Future<TeamResult> _getBestResultOfATeam(String name) async =>
      TeamResult.fromFirebaseQuery(await _resultsCollection.doc(name).get());

  ///
  /// Send a new score to the database
  Future<void> _putNewResultForATeam(TeamResult result) async =>
      await _resultsCollection
          .doc(result.name)
          .set({bestStationKey: result.station});

  ////////////////////////////////
  //// GAME RELATED FUNCTIONS ////
  ////////////////////////////////

  ///
  /// Simple mutex to wait for data to be sent before fetching
  bool _isSendingData = false;

  ///
  /// Send a new score to the database
  Future<void> registerTrainStationReached(int station) async {
    _isSendingData = true;

    // Get the previous result for this team to see if we need to update it
    final previousResult = await _getBestResultOfATeam(teamName);

    // If the previous result is better, do not update
    if (previousResult.exists && previousResult.station! >= station) {
      _isSendingData = false;
      return;
    }

    await _putNewResultForATeam(TeamResult(teamName, station));

    _isSendingData = false;
  }

  ///
  /// Returns all the stations for all the teams up to [top]
  /// If [currentStation] is not null, it will add the current team's score
  /// for this session at the bottom of the list
  Future<List<TeamResult>> getBestScoresOfTrainStationsReached({
    required int top,
    required int currentStation,
  }) async {
    while (_isSendingData) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final currentResult = TeamResult(teamName, currentStation);

    final out = await _getAllResults(ordered: true);

    // Add the current results if necessary (only the best one were fetched)
    _insertResultInList(currentResult, out);

    _computeStationRanks(out);

    // If our score did not get to the top, add it at the bottom
    _limitNumberOfResults(top, currentResult, out);

    return out;
  }
}

class DatabaseManagerMock extends DatabaseManager {
  bool _dummyIsSignedIn = false;
  String _dummyEmail = 'train@pariterre.net';
  bool _emailIsVerified = true;
  String _dummyTeamName = 'Les Bleuets';
  String _dummyPassword = '123456';
  Map<String, int> _dummyResults = {};

  DatabaseManagerMock._internal() : super._internal();

  static Future<void> initialize({
    bool? dummyIsSignedIn,
    String? dummyEmail,
    bool? emailIsVerified,
    String? dummyTeamName,
    String? dummyPassword,
    Map<String, int>? dummyResults,
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
    mock._dummyResults = dummyResults ?? mock._dummyResults;
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
    if (_dummyResults.containsKey(name)) {
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
  Future<List<TeamResult>> _getAllResults({bool ordered = false}) async {
    final out =
        _dummyResults.entries.map((e) => TeamResult(e.key, e.value)).toList();
    if (ordered) out.sort((a, b) => b.station!.compareTo(a.station!));

    return out;
  }

  @override
  Future<TeamResult> _getBestResultOfATeam(String name) async {
    final station = _dummyResults[name];
    return TeamResult(name, station);
  }

  @override
  Future<void> _putNewResultForATeam(TeamResult result) async {
    _dummyResults[result.name!] = result.station!;
  }
}

///
/// This function will take a list results and augment them with their rank
/// in the game.
void _computeStationRanks(List<TeamResult> results) {
  for (var i = 0; i < results.length; i++) {
    // Make a copy of the result
    final result = results[i];

    if (i == 0) {
      result.rank = 1;
    } else {
      // If the previous result is the same, we have the same rank, otherwise
      // we are one position ahead
      final previous = results[i - 1];
      result.rank = result.station == previous.station ? previous.rank : i + 1;
    }
  }
}

void _insertResultInList(TeamResult current, List<TeamResult> out) {
  final currentIndex = out.indexWhere(
      (e) => e.name == current.name && e.station == current.station);

  if (currentIndex < 0) {
    final index =
        out.indexWhere((e) => (e.station ?? 0) <= (current.station ?? -1));
    if (index < 0) {
      out.add(current);
    } else {
      out.insert(index, current);
    }
  }
}

void _limitNumberOfResults(int top, TeamResult current, List<TeamResult> out) {
  final index = out.indexWhere(
      (e) => e.name == current.name && e.station == current.station);

  // Something went wrong if we don't have our result in the list
  if (index < 0) return;

  if (index < top) {
    // If we are in the top, we only need to drop all the elements after top
    if (out.length > top) out.removeRange(top, out.length);

    // We can finally swap out the first index with our result
    final tp = out[index];
    final indexPrevious = out.indexWhere((e) => e.station == current.station);
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
