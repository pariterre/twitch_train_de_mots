import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:train_de_mots/firebase_options.dart';
import 'package:train_de_mots/models/exceptions.dart';

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

  ///
  /// Create a new user with the given email and password
  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  ///
  /// Log in with the given email and password
  Future<void> logIn({required String email, required String password}) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  ///
  /// Log out the current user
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  ///
  /// Return true if the user is logged in
  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;
}

class DatabaseManagerMock extends DatabaseManager {
  DatabaseManagerMock._internal() : super._internal();

  static Future<void> initialize() async {
    if (DatabaseManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          "DatabaseManager should not be initialized twice");
    }

    DatabaseManager._instance = DatabaseManagerMock._internal();
  }

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> logIn({required String email, required String password}) async {}

  @override
  Future<void> logOut() async {}

  @override
  bool get isUserLoggedIn => false;
}
