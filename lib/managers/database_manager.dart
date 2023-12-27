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

  final onLoggedIn = CustomCallback();
  final onLoggedOut = CustomCallback();

  ///
  /// Create a new user with the given email and password
  Future<void> signIn(
      {required String email,
      required String teamName,
      required String password}) async {
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

    await FirebaseAuth.instance.currentUser!.updateDisplayName(teamName);

    // Launch the waiting for email verification, do not wait for it to finish
    // because the UI need to update
    _waitForEmailVerification();

    // If we get here, we are logged in
    onLoggedIn.notifyListeners();
  }

  ///
  /// Return true if the user is logged in
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get isLoggedIn => isSignedIn && isEmailVerified;
  bool get isLoggedOut => !isLoggedIn;
  bool get isEmailVerified => FirebaseAuth.instance.currentUser!.emailVerified;

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

    if (!isEmailVerified) {
      throw AuthenticationException(
          message: 'Veillez vérifier votre adresse courriel');
    }

    // Launch the waiting for email verification, do not wait for it to finish
    // because the UI need to update
    _waitForEmailVerification();

    // If we get here, we are logged in
    onLoggedIn.notifyListeners();
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    onLoggedOut.notifyListeners();
  }

  ///
  /// Send a password reset email to the given email
  void resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  ///
  /// Wait for the email to be verified by the user
  void _waitForEmailVerification() async {
    while (!isEmailVerified) {
      await Future.delayed(const Duration(milliseconds: 500));
      await FirebaseAuth.instance.currentUser!.reload();
    }
  }

  /////////////////////////////////////////
  //// COMMUNICATION RELATED FUNCTIONS ////
  /////////////////////////////////////////

  ///
  /// Returns the name of the current team
  String get teamName => FirebaseAuth.instance.currentUser!.displayName!;

  ///
  /// Returns all the stations for all the teams
  Future<List<TeamResult>> _getAllResults({bool ordered = false}) async {
    late final List<QueryDocumentSnapshot<Map<String, dynamic>>> results;

    if (ordered) {
      results = (await FirebaseFirestore.instance
              .collection('stations')
              .orderBy('station', descending: true)
              .get())
          .docs;
    } else {
      results =
          (await FirebaseFirestore.instance.collection('stations').get()).docs;
    }
    return results.map((e) => TeamResult.fromFirebaseQuery(e)).toList();
  }

  ///
  /// Returns the best result for a given team
  Future<TeamResult> _getBestResultOfATeam(String name) async =>
      TeamResult.fromFirebaseQuery(await FirebaseFirestore.instance
          .collection('stations')
          .doc(name)
          .get());

  ///
  /// Send a new score to the database
  Future<void> _putNewResultForATeam(TeamResult result) async =>
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(result.name)
          .set({'station': result.station});

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
    required String teamName,
    required String password,
  }) async {
    if (email == _dummyEmail) {
      throw AuthenticationException(message: 'Ce courriel est déjà enregistré');
    }

    _dummyEmail = email;
    _dummyTeamName = teamName;
    _dummyPassword = password;
    _dummyIsSignedIn = true;
    onLoggedIn.notifyListeners();
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
    onLoggedIn.notifyListeners();
  }

  @override
  Future<void> logOut() async {
    _dummyIsSignedIn = false;
    onLoggedOut.notifyListeners();
  }

  @override
  void resetPassword(String email) {
    // Do nothing
  }

  @override
  bool get isSignedIn => _dummyIsSignedIn;

  @override
  bool get isEmailVerified => _emailIsVerified;

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
    final index = out.indexWhere((e) => e.station == current.station);
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
