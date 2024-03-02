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
  final int bestStation;
  final List<PlayerResult> mvpPlayers;

  @override
  int get value => bestStation;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : bestStation =
            doc.exists ? (doc.data()?[DatabaseManager.bestStationKey]) : -1,
        mvpPlayers = doc.exists
            ? (((doc.data()?[DatabaseManager.mvpPlayersKey])?[
                            DatabaseManager.mvpPlayersNameKey] as List?)
                        ?.map((name) => PlayerResult(
                            name: name,
                            teamName:
                                doc.data()?[DatabaseManager.teamNameKey] ?? '',
                            score: doc.data()?[DatabaseManager.mvpPlayersKey]
                                ?[DatabaseManager.mvpPlayersScoreKey])))
                    ?.toList() ??
                []
            : [],
        super(name: doc.data()?[DatabaseManager.teamNameKey] ?? '');

  TeamResult({
    required super.name,
    required this.bestStation,
    List<PlayerResult>? mvpPlayers,
  }) : mvpPlayers = mvpPlayers ?? [];
}

class PlayerResult extends DatabaseResult {
  final String teamName;
  final int score;
  @override
  int get value => score;

  PlayerResult(
      {required super.name, required this.teamName, required this.score});
}
