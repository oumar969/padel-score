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

  Future<String> createMatch(
    String format,
    List<String> team1Players,
    List<String> team2Players,
  ) async {
    final doc = _col.doc();
    final match = PadelMatch.create(
      id: doc.id,
      format: format,
      team1Players: team1Players,
      team2Players: team2Players,
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
