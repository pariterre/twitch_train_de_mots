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
  final List<PlayerResult> mvpScore;
  final List<PlayerResult> mvpStars;

  @override
  int get value => bestStation;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : bestStation =
            doc.exists ? (doc.data()?[DatabaseManager.bestStationKey]) : -1,
        mvpScore = doc.exists
            ? (((doc.data()?[DatabaseManager.mvpScoreKey])?[
                            DatabaseManager.mvpPlayersNameKey] as List?)
                        ?.map((name) => PlayerResult(
                            name: name,
                            teamName:
                                doc.data()?[DatabaseManager.teamNameKey] ?? '',
                            value: doc.data()?[DatabaseManager.mvpScoreKey]
                                ?[DatabaseManager.mvpPlayersValueKey])))
                    ?.toList() ??
                []
            : [],
        mvpStars = doc.exists
            ? (((doc.data()?[DatabaseManager.mvpStarsKey])?[
                            DatabaseManager.mvpPlayersNameKey] as List?)
                        ?.map((name) => PlayerResult(
                            name: name,
                            teamName:
                                doc.data()?[DatabaseManager.teamNameKey] ?? '',
                            value: doc.data()?[DatabaseManager.mvpStarsKey]
                                ?[DatabaseManager.mvpPlayersValueKey])))
                    ?.toList() ??
                []
            : [],
        super(name: doc.data()?[DatabaseManager.teamNameKey] ?? '');

  TeamResult({
    required super.name,
    required this.bestStation,
    List<PlayerResult>? mvpScore,
    List<PlayerResult>? mvpStars,
  })  : mvpScore = mvpScore ?? [],
        mvpStars = mvpStars ?? [];
}

class PlayerResult extends DatabaseResult {
  final String teamName;
  final int _value;
  @override
  int get value => _value;

  PlayerResult(
      {required super.name, required this.teamName, required int value})
      : _value = value;
}
