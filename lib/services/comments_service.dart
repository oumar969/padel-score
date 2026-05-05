import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentsService {
  CollectionReference _col(String matchId) => FirebaseFirestore.instance
      .collection('matches')
      .doc(matchId)
      .collection('comments');

  Stream<List<MatchComment>> watch(String matchId) {
    return _col(matchId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => MatchComment.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> add(String matchId, String text) async {
    final comment = MatchComment(
      id: '',
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _col(matchId).add(comment.toMap());
  }
}
