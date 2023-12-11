import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  /// Send a new score to the database
  Future<void> sendStation(int station) async {
    // Get the previous result for this team to see if we need to update it
    final previousResult = await FirebaseFirestore.instance
        .collection('stations')
        .doc(teamName)
        .get();

    // If the previous result is better, do not update
    if (previousResult.exists && previousResult.data()!['station'] >= station) {
      return;
    }

    final stations = FirebaseFirestore.instance.collection('stations');
    await stations.doc(teamName).set({'team': teamName, 'station': station});
  }

  ///
  /// Returns all the stations for all the teams up to [top]
  Future<List<Map<String, dynamic>>> teamStations(
      {required int top, int? includeStation}) async {
    final stations = (await FirebaseFirestore.instance
            .collection('stations')
            .orderBy('station', descending: true)
            .limit(top)
            .get())
        .docs;
    final stationsList = stations
        .map((e) => {'team': e.data()['team'], 'station': e.data()['station']})
        .toList();

    final out = _prepareTeamOutput(stationsList);

    // If our score did not get to the top, add it at the bottom
    if (includeStation != null) {
      await _addSpecificStationTeamOutput(top, includeStation, out);
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

  Future<void> _addSpecificStationTeamOutput(
      int top, int station, List<Map<String, dynamic>> out) async {
    bool isInTop = out.any((e) => e['station'] <= station);
    int position = out.firstWhere((e) => e['station'] == station)['position'];

    if (isInTop &&
        !out.any((e) => e['team'] == teamName && e['station'] == station)) {
      // If our team is in the top, but not in the list, it means there are
      // multiple results for the same station. We need to replace the first
      // one with our team

      final index = out.indexWhere((e) => e['station'] <= station);
      out.insert(index, {
        'team': teamName,
        'station': station,
        'position': position,
      });
      if (out.length > top) out.removeLast();
    }

    if (!isInTop) {
      // If our team is not in the top, just add it at the bottom so we can
      // see our position
      final toAdd = {
        'team': teamName,
        'station': station,
        'position': position,
      };

      if (out.length < top) {
        out.add(toAdd);
      } else {
        out.last = toAdd;
      }
    }
  }
}

class DatabaseManagerMock extends DatabaseManager {
  bool _isLoggedIn = false;
  String _email = 'train@pariterre.net';
  String? _teamName = 'Les Bleuets';
  @override
  String get teamName => _teamName!;
  String? _password = '123456';
  final Map<String, int> _stations = {
    'Les Verts': 3,
    'Les Oranges': 6,
    'Les Roses': 1,
    'Les Jaunes': 5,
    'Les Blancs': 1,
    'Les Bleus': 0,
    'Les Noirs': 1,
    'Les Rouges': 2,
    'Les Violets': 3,
    'Les Gris': 0,
    'Les Bruns': 0,
  };

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
  Future<void> sendStation(int station) async {
    if (!_stations.containsKey(teamName) || _stations[teamName]! < station) {
      _stations[teamName] = station;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> teamStations(
      {required int top, int? includeStation}) async {
    final sortedTeamNames =
        _stations.keys.sorted((a, b) => _stations[b]! - _stations[a]!);

    final List<Map<String, dynamic>> sortedTeams = [];
    for (int i = 0; i < sortedTeamNames.length; i++) {
      if (i >= top) break;

      final team = sortedTeamNames[i];
      sortedTeams.add({'team': team, 'station': _stations[team]});
    }
    final out = _prepareTeamOutput(sortedTeams);

    if (includeStation != null) {
      await _addSpecificStationTeamOutput(top, includeStation, out);
    }

    return out;
  }
}
