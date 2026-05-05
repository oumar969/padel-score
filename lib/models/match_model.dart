class SetScore {
  final int t1;
  final int t2;

  const SetScore({required this.t1, required this.t2});

  int get winner => t1 > t2 ? 1 : 2;

  Map<String, dynamic> toMap() => {'t1': t1, 't2': t2};

  factory SetScore.fromMap(Map<String, dynamic> m) =>
      SetScore(t1: (m['t1'] as num).toInt(), t2: (m['t2'] as num).toInt());
}

enum MatchStatus { active, finished }

class PadelMatch {
  final String id;
  final String team1Name;
  final String team2Name;
  final List<SetScore> completedSets;
  final int currentSetT1;
  final int currentSetT2;
  final int currentGameT1;
  final int currentGameT2;
  final bool isTiebreak;
  final MatchStatus status;
  final int? winner;
  final DateTime createdAt;

  const PadelMatch({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    required this.completedSets,
    required this.currentSetT1,
    required this.currentSetT2,
    required this.currentGameT1,
    required this.currentGameT2,
    required this.isTiebreak,
    required this.status,
    this.winner,
    required this.createdAt,
  });

  int get team1Sets => completedSets.where((s) => s.winner == 1).length;
  int get team2Sets => completedSets.where((s) => s.winner == 2).length;

  bool get isDeuce =>
      !isTiebreak &&
      currentGameT1 >= 3 &&
      currentGameT2 >= 3 &&
      currentGameT1 == currentGameT2;

  bool get team1HasAdvantage =>
      !isTiebreak &&
      currentGameT1 >= 3 &&
      currentGameT2 >= 3 &&
      currentGameT1 > currentGameT2;

  bool get team2HasAdvantage =>
      !isTiebreak &&
      currentGameT1 >= 3 &&
      currentGameT2 >= 3 &&
      currentGameT2 > currentGameT1;

  String get team1GameDisplay => _gameDisplay(currentGameT1, currentGameT2);
  String get team2GameDisplay => _gameDisplay(currentGameT2, currentGameT1);

  String _gameDisplay(int my, int other) {
    if (isTiebreak) return '$my';
    if (my >= 3 && other >= 3) {
      if (my == other) return '40';
      return my > other ? 'Ad' : '40';
    }
    return const ['0', '15', '30', '40'][my.clamp(0, 3)];
  }

  PadelMatch copyWith({
    String? team1Name,
    String? team2Name,
    List<SetScore>? completedSets,
    int? currentSetT1,
    int? currentSetT2,
    int? currentGameT1,
    int? currentGameT2,
    bool? isTiebreak,
    MatchStatus? status,
    int? winner,
  }) {
    return PadelMatch(
      id: id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      completedSets: completedSets ?? this.completedSets,
      currentSetT1: currentSetT1 ?? this.currentSetT1,
      currentSetT2: currentSetT2 ?? this.currentSetT2,
      currentGameT1: currentGameT1 ?? this.currentGameT1,
      currentGameT2: currentGameT2 ?? this.currentGameT2,
      isTiebreak: isTiebreak ?? this.isTiebreak,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'team1Name': team1Name,
        'team2Name': team2Name,
        'completedSets': completedSets.map((s) => s.toMap()).toList(),
        'currentSetT1': currentSetT1,
        'currentSetT2': currentSetT2,
        'currentGameT1': currentGameT1,
        'currentGameT2': currentGameT2,
        'isTiebreak': isTiebreak,
        'status': status.name,
        'winner': winner,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PadelMatch.fromMap(String id, Map<String, dynamic> m) => PadelMatch(
        id: id,
        team1Name: m['team1Name'] ?? 'Hold 1',
        team2Name: m['team2Name'] ?? 'Hold 2',
        completedSets: (m['completedSets'] as List? ?? [])
            .map((s) => SetScore.fromMap(s as Map<String, dynamic>))
            .toList(),
        currentSetT1: (m['currentSetT1'] as num?)?.toInt() ?? 0,
        currentSetT2: (m['currentSetT2'] as num?)?.toInt() ?? 0,
        currentGameT1: (m['currentGameT1'] as num?)?.toInt() ?? 0,
        currentGameT2: (m['currentGameT2'] as num?)?.toInt() ?? 0,
        isTiebreak: m['isTiebreak'] as bool? ?? false,
        status: MatchStatus.values.byName(m['status'] ?? 'active'),
        winner: (m['winner'] as num?)?.toInt(),
        createdAt: DateTime.parse(
            m['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  factory PadelMatch.create({
    required String id,
    required String team1Name,
    required String team2Name,
  }) =>
      PadelMatch(
        id: id,
        team1Name: team1Name,
        team2Name: team2Name,
        completedSets: const [],
        currentSetT1: 0,
        currentSetT2: 0,
        currentGameT1: 0,
        currentGameT2: 0,
        isTiebreak: false,
        status: MatchStatus.active,
        createdAt: DateTime.now(),
      );
}
