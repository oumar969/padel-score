import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class FirestoreService {
  final _col = FirebaseFirestore.instance.collection('matches');

  Stream<List<PadelMatch>> watchMatches() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PadelMatch.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<PadelMatch> watchMatch(String id) {
    return _col.doc(id).snapshots().map((d) {
      if (!d.exists) throw StateError('Match $id not found');
      return PadelMatch.fromMap(d.id, d.data()!);
    });
  }

  Future<String> createMatch(String team1Name, String team2Name) async {
    final doc = _col.doc();
    final match = PadelMatch.create(
      id: doc.id,
      team1Name: team1Name,
      team2Name: team2Name,
    );
    await doc.set(match.toMap());
    return doc.id;
  }

  Future<void> updateMatch(PadelMatch match) async {
    await _col.doc(match.id).set(match.toMap());
  }

  Future<void> deleteMatch(String id) async {
    await _col.doc(id).delete();
  }
}
