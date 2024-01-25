import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_de_mots/managers/database_manager.dart';

class PlayerResult {
  String? name;
  int? score;
  int? rank;

  bool get exists => name != null && score != null;

  PlayerResult.fromFirebaseQuery(DocumentSnapshot<Map<String, dynamic>> doc)
      : name = doc.exists ? (doc.id) : null,
        score = doc.exists ? (doc.data()?[DatabaseManager.bestScoreKey]) : null;

  PlayerResult(this.name, this.score);
}
