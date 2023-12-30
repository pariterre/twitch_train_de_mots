import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_de_mots/managers/database_manager.dart';

class TeamResult {
  String? name;
  int? station;
  int? rank;

  bool get exists => name != null && station != null;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.exists ? (doc.id) : null,
        station =
            doc.exists ? (doc.data()?[DatabaseManager.bestStationKey]) : null;

  TeamResult(this.name, this.station);
}
