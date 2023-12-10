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
}
