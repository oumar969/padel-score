import 'match_model.dart';

class PlayerStats {
  final String name;
  final int played;
  final int wins;
  final Map<String, int> partnerWins;

  const PlayerStats({
    required this.name,
    required this.played,
    required this.wins,
    required this.partnerWins,
  });

  int get losses => played - wins;
  double get winRate => played > 0 ? wins / played : 0;
  String get winRatePct => '${(winRate * 100).round()}%';

  String? get bestPartner {
    if (partnerWins.isEmpty) return null;
    return partnerWins.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

List<PlayerStats> computePlayerStats(List<PadelMatch> matches) {
  final data = <String, _Raw>{};

  for (final m in matches.where((m) => m.status == MatchStatus.finished)) {
    void process(List<String> players, bool won) {
      for (final p in players) {
        data.putIfAbsent(p, _Raw.new);
        data[p]!.played++;
        if (won) {
          data[p]!.wins++;
          for (final partner in players.where((x) => x != p)) {
            data[p]!.partnerWins[partner] = (data[p]!.partnerWins[partner] ?? 0) + 1;
          }
        }
      }
    }

    process(m.team1Players, m.winner == 1);
    process(m.team2Players, m.winner == 2);
  }

  return data.entries
      .map((e) => PlayerStats(
            name: e.key,
            played: e.value.played,
            wins: e.value.wins,
            partnerWins: e.value.partnerWins,
          ))
      .toList()
    ..sort((a, b) => b.wins != a.wins
        ? b.wins.compareTo(a.wins)
        : b.winRate.compareTo(a.winRate));
}

class _Raw {
  int played = 0;
  int wins = 0;
  final partnerWins = <String, int>{};
}
