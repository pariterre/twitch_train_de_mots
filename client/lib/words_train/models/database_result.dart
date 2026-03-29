import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_de_mots/generic/managers/database_manager.dart';

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

String _extractTeamName(DocumentSnapshot<Map<String, dynamic>> doc) {
  return doc.data()?[DatabaseManager.teamNameKey] ?? '';
}

class TeamResult extends DatabaseResult {
  final List<int> bestStations;
  final List<PlayerResult> mvpScore;
  final List<PlayerResult> mvpStars;

  int get bestStation => bestStations.isNotEmpty ? bestStations.first : -1;

  @override
  int get value => bestStation;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : bestStations = doc.exists
            ? ((doc.data()?[DatabaseManager.bestStationsKey]) as List?)
                    ?.cast<int>() ??
                []
            : [],
        mvpScore = doc.exists
            ? (((doc.data()?[DatabaseManager.mvpScoreKey]) as List?)?.map(
                    (map) => PlayerResult.fromSerialized(map,
                        teamName: _extractTeamName(doc))))?.toList() ??
                []
            : [],
        mvpStars = doc.exists
            ? (((doc.data()?[DatabaseManager.mvpStarsKey]) as List?)?.map(
                    (map) => PlayerResult.fromSerialized(map,
                        teamName: _extractTeamName(doc))))?.toList() ??
                []
            : [],
        super(name: _extractTeamName(doc));

  TeamResult({
    required super.name,
    required this.bestStations,
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

  Map<String, dynamic> get serialized => {
        'name': name,
        'value': value,
      };

  PlayerResult.fromSerialized(Map<String, dynamic> data,
      {required this.teamName})
      : _value = data['value'] ?? 0,
        super(name: data['name'] ?? '');
}
