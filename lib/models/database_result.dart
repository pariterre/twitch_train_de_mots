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
  DatabaseResult({required this.name});
}

class TeamResult extends DatabaseResult {
  int bestStation;
  List<PlayerResult> bestPlayers;

  @override
  int get value => bestStation;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : bestStation =
            doc.exists ? (doc.data()?[DatabaseManager.bestStationKey]) : -1,
        bestPlayers = doc.exists
            ? (((doc.data()?[DatabaseManager.bestPlayersKey])?['names']
                        as List?)
                    ?.map((name) => PlayerResult(
                        name: name,
                        teamName: doc.id,
                        score: doc.data()?[DatabaseManager.bestPlayersKey]
                            ?['score'])))?.toList() ??
                []
            : [],
        super(name: doc.exists ? (doc.id) : '');

  TeamResult({
    required super.name,
    required this.bestStation,
    List<PlayerResult>? bestPlayers,
  }) : bestPlayers = bestPlayers ?? [];
}

class PlayerResult extends DatabaseResult {
  String teamName;
  int score;
  @override
  int get value => score;

  PlayerResult(
      {required super.name, required this.teamName, required this.score});
}
