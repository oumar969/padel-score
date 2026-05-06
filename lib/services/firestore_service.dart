import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/match_settings.dart';

class FirestoreService {
  final _col = FirebaseFirestore.instance.collection('matches');

  Stream<List<PadelMatch>> watchMatches(String userId) {
    return _col
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => PadelMatch.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
    MatchSettings settings,
    int initialServingTeam,
    String ownerId,
  ) async {
    final doc = _col.doc();
    final match = PadelMatch.create(
      id: doc.id,
      format: format,
      team1Players: team1Players,
      team2Players: team2Players,
      settings: settings,
      initialServingTeam: initialServingTeam,
      ownerId: ownerId,
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
