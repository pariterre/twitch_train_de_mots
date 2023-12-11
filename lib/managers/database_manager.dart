import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';

class DatabaseManager {
  final onLoggedIn = CustomCallback();
  final onLoggedOut = CustomCallback();

  String get teamName => FirebaseAuth.instance.currentUser!.displayName!;

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
    onLoggedIn.notifyListeners();
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
            message: 'Addresse courriel ou mot de passe incorrect');
      } else {
        throw AuthenticationException(message: 'Erreur inconnue');
      }
    }
    onLoggedIn.notifyListeners();
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    onLoggedOut.notifyListeners();
  }

  ///
  /// Return true if the user is logged in
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  bool get isLoggedOut => !isLoggedIn;

  ///
  /// Returns all the stations for all the teams
  Future<List<Map<String, dynamic>>> teamStations(
      {required int top, required bool includeOurTeam}) async {
    final stations = (await FirebaseFirestore.instance
            .collection('finalStations')
            .orderBy('station', descending: true)
            .limit(top)
            .get())
        .docs;
    final stationsList = stations
        .map((e) => {'team': e.id, 'station': e.data()['station']})
        .toList();

    final out = _prepareTeamOutput(stationsList);

    if (includeOurTeam && !out.any((e) => e['team'] == teamName)) {
      final myTeamBestStation = (await FirebaseFirestore.instance
              .collection('finalStations')
              .doc(teamName)
              .get())
          .data()!['station'];
      final myPosition = (await FirebaseFirestore.instance
              .collection('finalStations')
              .orderBy('station', descending: true)
              .get())
          .docs
          .indexWhere((e) => e.id == teamName);

      // Replace the last team with our team
      out.last = {
        'team': teamName,
        'station': myTeamBestStation,
        'position': myPosition + 1
      };
    }

    return out;
  }

  List<Map<String, dynamic>> _prepareTeamOutput(
      List<Map<String, dynamic>> orderedTeams) {
    final List<Map<String, dynamic>> out = [];

    int position = 1;
    for (var i = 0; i < orderedTeams.length; i++) {
      final teamData = orderedTeams[i];
      final team = teamData['team'];
      final station = teamData['station'];

      if (i != 0) {
        final previousStation = orderedTeams[i - 1]['station'];
        position = station == previousStation ? position : i + 1;
      }
      out.add({'team': team, 'station': station, 'position': position});
    }
    return out;
  }
}

class DatabaseManagerMock extends DatabaseManager {
  bool _isLoggedIn = false;
  String _email = 'train@pariterre.net';
  String? _teamName = 'Les Bleuets';
  @override
  String get teamName => _teamName!;
  String? _password = '123456';

  DatabaseManagerMock._internal() : super._internal();

  static Future<void> initialize({bool isLoggedIn = false}) async {
    if (DatabaseManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          "DatabaseManager should not be initialized twice");
    }

    DatabaseManager._instance = DatabaseManagerMock._internal();
    (DatabaseManager._instance as DatabaseManagerMock)._isLoggedIn = isLoggedIn;
  }

  @override
  Future<void> signIn({
    required String email,
    required String teamName,
    required String password,
  }) async {
    if (email == _email) {
      throw AuthenticationException(message: 'Ce courriel est déjà enregistré');
    }

    _email = email;
    _teamName = teamName;
    _password = password;
    _isLoggedIn = true;
    onLoggedIn.notifyListeners();
  }

  @override
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    if (_email != email || _password != password) {
      throw AuthenticationException(
          message: 'Addresse courriel ou mot de passe incorrect');
    }
    _isLoggedIn = true;
    onLoggedIn.notifyListeners();
  }

  @override
  Future<void> logOut() async {
    _isLoggedIn = false;
    onLoggedOut.notifyListeners();
  }

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  Future<List<Map<String, dynamic>>> teamStations(
      {required int top, required bool includeOurTeam}) async {
    const teams = {
      'Les Verts': 30,
      'Les Oranges': 50,
      'Les Roses': 70,
      'Les Jaunes': 40,
      'Les Blancs': 100,
      'Les Bleus': 0,
      'Les Noirs': 90,
      'Les Bleuets': 50,
      'Les Rouges': 20,
      'Les Violets': 60,
      'Les Gris': 80,
    };
    final sortedTeamNames = teams.keys.sorted((a, b) => teams[b]! - teams[a]!);

    final List<Map<String, dynamic>> sortedTeams = [];
    for (final team in sortedTeamNames) {
      sortedTeams.add({'team': team, 'station': teams[team]});
    }
    final out = _prepareTeamOutput(sortedTeams);

    if (includeOurTeam && !out.any((e) => e['team'] == teamName)) {
      // Replace the last team with our team
      out.last = {'team': teamName, 'station': 3, 'position': 400};
    }

    return out;
  }
}
