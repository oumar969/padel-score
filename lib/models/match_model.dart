import 'match_settings.dart';

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
  final String format;
  final List<String> team1Players;
  final List<String> team2Players;
  final List<SetScore> completedSets;
  final int currentSetT1;
  final int currentSetT2;
  final int currentGameT1;
  final int currentGameT2;
  final bool isTiebreak;
  final MatchStatus status;
  final int? winner;
  final DateTime createdAt;
  final DateTime? matchStartedAt;

  // Settings & features
  final MatchSettings settings;
  final int servingTeam;        // 1 or 2
  final int totalGamesPlayed;   // for ball reminder
  final DateTime? warmupStartedAt;
  final DateTime? timeoutStartedAt;

  static const warmupDuration = Duration(minutes: 5);
  static const timeoutDuration = Duration(seconds: 60);
  static const ballReminderEvery = 9;

  const PadelMatch({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    required this.format,
    required this.team1Players,
    required this.team2Players,
    required this.completedSets,
    required this.currentSetT1,
    required this.currentSetT2,
    required this.currentGameT1,
    required this.currentGameT2,
    required this.isTiebreak,
    required this.status,
    this.winner,
    required this.createdAt,
    this.matchStartedAt,
    required this.settings,
    required this.servingTeam,
    required this.totalGamesPlayed,
    this.warmupStartedAt,
    this.timeoutStartedAt,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  int get team1Sets => completedSets.where((s) => s.winner == 1).length;
  int get team2Sets => completedSets.where((s) => s.winner == 2).length;

  bool get isDeuce =>
      !isTiebreak && currentGameT1 >= 3 && currentGameT2 >= 3 && currentGameT1 == currentGameT2;

  bool get team1HasAdvantage =>
      !isTiebreak && currentGameT1 >= 3 && currentGameT2 >= 3 && currentGameT1 > currentGameT2;

  bool get team2HasAdvantage =>
      !isTiebreak && currentGameT1 >= 3 && currentGameT2 >= 3 && currentGameT2 > currentGameT1;

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

  Duration get elapsed =>
      matchStartedAt != null ? DateTime.now().difference(matchStartedAt!) : Duration.zero;

  bool get isInWarmup {
    if (!settings.warmup || warmupStartedAt == null) return false;
    return DateTime.now().difference(warmupStartedAt!) < warmupDuration;
  }

  Duration get warmupRemaining {
    if (warmupStartedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(warmupStartedAt!);
    final remaining = warmupDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isInTimeout {
    if (timeoutStartedAt == null) return false;
    return DateTime.now().difference(timeoutStartedAt!) < timeoutDuration;
  }

  Duration get timeoutRemaining {
    if (timeoutStartedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(timeoutStartedAt!);
    final remaining = timeoutDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get needsBallReminder =>
      settings.ballReminder &&
      totalGamesPlayed > 0 &&
      totalGamesPlayed % ballReminderEvery == 0;

  // ── copyWith ────────────────────────────────────────────────────────────────

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
    DateTime? matchStartedAt,
    int? servingTeam,
    int? totalGamesPlayed,
    DateTime? warmupStartedAt,
    DateTime? timeoutStartedAt,
    bool clearTimeout = false,
    bool clearWarmup = false,
  }) {
    return PadelMatch(
      id: id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      format: format,
      team1Players: team1Players,
      team2Players: team2Players,
      completedSets: completedSets ?? this.completedSets,
      currentSetT1: currentSetT1 ?? this.currentSetT1,
      currentSetT2: currentSetT2 ?? this.currentSetT2,
      currentGameT1: currentGameT1 ?? this.currentGameT1,
      currentGameT2: currentGameT2 ?? this.currentGameT2,
      isTiebreak: isTiebreak ?? this.isTiebreak,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      createdAt: createdAt,
      matchStartedAt: matchStartedAt ?? this.matchStartedAt,
      settings: settings,
      servingTeam: servingTeam ?? this.servingTeam,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      warmupStartedAt: clearWarmup ? null : (warmupStartedAt ?? this.warmupStartedAt),
      timeoutStartedAt: clearTimeout ? null : (timeoutStartedAt ?? this.timeoutStartedAt),
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'team1Name': team1Name,
        'team2Name': team2Name,
        'format': format,
        'team1Players': team1Players,
        'team2Players': team2Players,
        'completedSets': completedSets.map((s) => s.toMap()).toList(),
        'currentSetT1': currentSetT1,
        'currentSetT2': currentSetT2,
        'currentGameT1': currentGameT1,
        'currentGameT2': currentGameT2,
        'isTiebreak': isTiebreak,
        'status': status.name,
        'winner': winner,
        'createdAt': createdAt.toIso8601String(),
        'matchStartedAt': matchStartedAt?.toIso8601String(),
        'settings': settings.toMap(),
        'servingTeam': servingTeam,
        'totalGamesPlayed': totalGamesPlayed,
        'warmupStartedAt': warmupStartedAt?.toIso8601String(),
        'timeoutStartedAt': timeoutStartedAt?.toIso8601String(),
      };

  factory PadelMatch.fromMap(String id, Map<String, dynamic> m) {
    final t1Name = m['team1Name'] as String? ?? 'Hold 1';
    final t2Name = m['team2Name'] as String? ?? 'Hold 2';
    return PadelMatch(
      id: id,
      team1Name: t1Name,
      team2Name: t2Name,
      format: m['format'] as String? ?? '2v2',
      team1Players: (m['team1Players'] as List?)?.cast<String>() ?? [t1Name],
      team2Players: (m['team2Players'] as List?)?.cast<String>() ?? [t2Name],
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
      createdAt: DateTime.parse(m['createdAt'] ?? DateTime.now().toIso8601String()),
      matchStartedAt: m['matchStartedAt'] != null
          ? DateTime.parse(m['matchStartedAt'] as String)
          : null,
      settings: MatchSettings.fromMap(m['settings'] as Map<String, dynamic>?),
      servingTeam: (m['servingTeam'] as num?)?.toInt() ?? 1,
      totalGamesPlayed: (m['totalGamesPlayed'] as num?)?.toInt() ?? 0,
      warmupStartedAt: m['warmupStartedAt'] != null
          ? DateTime.parse(m['warmupStartedAt'] as String)
          : null,
      timeoutStartedAt: m['timeoutStartedAt'] != null
          ? DateTime.parse(m['timeoutStartedAt'] as String)
          : null,
    );
  }

  factory PadelMatch.create({
    required String id,
    required String format,
    required List<String> team1Players,
    required List<String> team2Players,
    required MatchSettings settings,
    required int initialServingTeam,
  }) =>
      PadelMatch(
        id: id,
        team1Name: team1Players.join(' & '),
        team2Name: team2Players.join(' & '),
        format: format,
        team1Players: team1Players,
        team2Players: team2Players,
        completedSets: const [],
        currentSetT1: 0,
        currentSetT2: 0,
        currentGameT1: 0,
        currentGameT2: 0,
        isTiebreak: false,
        status: MatchStatus.active,
        createdAt: DateTime.now(),
        settings: settings,
        servingTeam: initialServingTeam,
        totalGamesPlayed: 0,
        warmupStartedAt: settings.warmup ? DateTime.now() : null,
      );
}
