import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_de_mots/managers/database_manager.dart';

abstract class DatabaseResult {
  ///
  /// Get the name of the result
  final String name;

  ///
  /// Get the comparison value of the result
  int get value;

  ///
  /// Current rank of the result
  int? rank;

  ///
  /// Constructor
  DatabaseResult(this.name);
}

class TeamResult extends DatabaseResult {
  int bestStation;

  @override
  int get value => bestStation;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : bestStation =
            doc.exists ? (doc.data()?[DatabaseManager.bestStationKey]) : -1,
        super(doc.exists ? (doc.id) : '');

  TeamResult(super.name, this.bestStation);
}

class PlayerResult extends DatabaseResult {
  String teamName;

  int score;
  @override
  int get value => score;

  PlayerResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : teamName =
            doc.exists ? (doc.data()?[DatabaseManager.playerTeamNameKey]) : '',
        score = doc.exists ? (doc.data()?[DatabaseManager.bestScoreKey]) : -1,
        super(doc.exists ? (doc.id) : '');

  PlayerResult(super.name, this.score, this.teamName);
}
