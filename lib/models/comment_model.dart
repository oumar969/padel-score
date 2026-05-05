class MatchComment {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isOwnerReply;
  final String? replyToId; // set when owner replies to a comment

  const MatchComment({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isOwnerReply = false,
    this.replyToId,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isOwnerReply': isOwnerReply,
        'replyToId': replyToId,
      };

  factory MatchComment.fromMap(String id, Map<String, dynamic> m) => MatchComment(
        id: id,
        text: m['text'] as String? ?? '',
        createdAt: DateTime.parse(m['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        isOwnerReply: m['isOwnerReply'] as bool? ?? false,
        replyToId: m['replyToId'] as String?,
      );
}
