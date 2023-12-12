import 'package:cloud_firestore/cloud_firestore.dart';

class TrainResult {
  String? name;
  int? station;
  int? rank;

  bool get exists => name != null && station != null;

  TrainResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.exists ? (doc.id) : null,
        station = doc.exists ? (doc.data()?['station']) : null;

  TrainResult(this.name, this.station);
}
