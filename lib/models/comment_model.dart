class MatchComment {
  final String id;
  final String text;
  final DateTime createdAt;

  const MatchComment({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MatchComment.fromMap(String id, Map<String, dynamic> m) => MatchComment(
        id: id,
        text: m['text'] as String? ?? '',
        createdAt: DateTime.parse(m['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );
}
