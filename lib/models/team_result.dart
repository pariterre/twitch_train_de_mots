import 'package:cloud_firestore/cloud_firestore.dart';

class TeamResult {
  String? name;
  int? station;
  int? rank;

  bool get exists => name != null && station != null;

  TeamResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.exists ? (doc.id) : null,
        station = doc.exists ? (doc.data()?['station']) : null;

  TeamResult(this.name, this.station);
}
