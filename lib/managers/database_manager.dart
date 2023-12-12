import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/train_result.dart';

class DatabaseManager {
  /// Declare the singleton
  static DatabaseManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          "DatabaseManager must be initialized before being used");
    }
    return _instance!;
  }

  static DatabaseManager? _instance;
  DatabaseManager._internal();

  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          "DatabaseManager should not be initialized twice");
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
    _teamName = FirebaseAuth.instance.currentUser!.displayName!;

    onLoggedIn.notifyListeners();
  }

  ///
  /// Return true if the user is logged in
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  bool get isLoggedOut => !isLoggedIn;

  ///
  /// Log in with the given email and password
  Future<void> logIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw AuthenticationException(
            message: 'Addresse courriel ou mot de passe incorrect');
      } else {
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }
    _teamName = FirebaseAuth.instance.currentUser!.displayName!;

    onLoggedIn.notifyListeners();
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    onLoggedOut.notifyListeners();
  }

  /////////////////////////////////////////
  //// COMMUNICATION RELATED FUNCTIONS ////
  /////////////////////////////////////////

  Future<List<TrainResult>> _getAllResults({bool ordered = false}) async {
    final query = FirebaseFirestore.instance.collection('stations');
    if (ordered) {
      query.orderBy('station', descending: true);
    }

    final results = (await query.get()).docs;
    return results.map((e) => TrainResult.fromFirebaseQuery(e)).toList();
  }

  Future<TrainResult> _getBestResultOfATeam(String name) async =>
      TrainResult.fromFirebaseQuery(await FirebaseFirestore.instance
          .collection('stations')
          .doc(name)
          .get());

  Future<void> _putNewResultForATeam(TrainResult result) async =>
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(result.name)
          .set({'station': result.station});

  ////////////////////////////////
  //// GAME RELATED FUNCTIONS ////
  ////////////////////////////////

  ///
  /// Return the name of the current team
  String? _teamName;
  String get teamName => _teamName!;

  ///
  /// Send a new score to the database
  Future<void> registerTrainStationReached(int station) async {
    // Get the previous result for this team to see if we need to update it
    final previousResult = await _getBestResultOfATeam(teamName);

    // If the previous result is better, do not update
    if (previousResult.exists && previousResult.station! >= station) {
      return;
    }

    await _putNewResultForATeam(TrainResult(teamName, station));
  }

  ///
  /// Returns all the stations for all the teams up to [top]
  /// If [currentStation] is not null, it will add the current team's score
  /// for this session at the bottom of the list
  Future<List<TrainResult>> getBestScoresOfTrainStationsReached({
    required int top,
    required int currentStation,
  }) async {
    final out = await _getAllResults(ordered: true);
    _computeStationRanks(out);

    // If our score did not get to the top, add it at the bottom
    _limitNumberOfResults(top, TrainResult(teamName, currentStation), out);

    return out;
  }
}

class DatabaseManagerMock extends DatabaseManager {
  late final bool _dummyIsLoggedIn;
  late final String _dummyEmail;
  late final String _dummyTeamName;
  late final String _dummyPassword;
  late final Map<String, int> _dummyResults;

  DatabaseManagerMock._internal() : super._internal();

  static Future<void> initialize({
    bool dummyIsLoggedIn = false,
    String dummyEmail = 'train@pariterre.net',
    String dummyTeamName = 'Les Bleuets',
    String dummyPassword = '123456',
    Map<String, int>? dummyResults,
  }) async {
    if (DatabaseManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          "DatabaseManager should not be initialized twice");
    }

    DatabaseManager._instance = DatabaseManagerMock._internal();

    final mock = DatabaseManager._instance as DatabaseManagerMock;
    mock._dummyIsLoggedIn = dummyIsLoggedIn;
    mock._dummyEmail = dummyEmail;
    mock._dummyTeamName = dummyTeamName;
    if (dummyIsLoggedIn) DatabaseManager.instance._teamName = dummyTeamName;
    mock._dummyPassword = dummyPassword;
    mock._dummyResults = dummyResults ?? {};
  }

  ///////////////////////
  //// AUTH MOCKINGS ////
  ///////////////////////

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
    _teamName = teamName;
    _dummyPassword = password;
    _dummyIsLoggedIn = true;
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
    _dummyIsLoggedIn = true;
    _teamName = _dummyTeamName;
    onLoggedIn.notifyListeners();
  }

  @override
  Future<void> logOut() async {
    _dummyIsLoggedIn = false;
    onLoggedOut.notifyListeners();
  }

  @override
  bool get isLoggedIn => _dummyIsLoggedIn;

  ////////////////////////////////
  //// COMMUNICATION MOCKINGS ////
  ////////////////////////////////

  @override
  Future<List<TrainResult>> _getAllResults({bool ordered = false}) async {
    final out =
        _dummyResults.entries.map((e) => TrainResult(e.key, e.value)).toList();
    if (ordered) out.sort((a, b) => b.station!.compareTo(a.station!));

    return out;
  }

  @override
  Future<TrainResult> _getBestResultOfATeam(String name) async {
    final station = _dummyResults[name];
    return TrainResult(name, station);
  }

  @override
  Future<void> _putNewResultForATeam(TrainResult result) async {
    _dummyResults[result.name!] = result.station!;
  }
}

///
/// This function will take a list results and augment them with their rank
/// in the game.
void _computeStationRanks(List<TrainResult> results) {
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

void _limitNumberOfResults(
    int top, TrainResult current, List<TrainResult> out) {
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
    out.removeRange(top - 1, out.length);
    out.add(tp);
  }
}
