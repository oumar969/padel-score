import 'dart:math';
import 'match_model.dart';

class MatchAnalysis {
  final PadelMatch match;
  MatchAnalysis(this.match);

  /// Cumulative lead from game 0. Positive = team1 ahead, negative = team2.
  List<int> get momentumPoints {
    int lead = 0;
    final result = <int>[0];
    for (final w in match.gameLog) {
      lead += w == 1 ? 1 : -1;
      result.add(lead);
    }
    return result;
  }

  /// Which team won each game within each completed set.
  List<List<int>> get setGameWinners {
    int offset = 0;
    return match.completedSets.map((s) {
      final count = s.t1 + s.t2;
      final end = (offset + count).clamp(0, match.gameLog.length);
      final slice = match.gameLog.sublist(offset, end);
      offset += count;
      return slice;
    }).toList();
  }

  /// Which team had the longest consecutive game-winning streak.
  ({int team, int count}) get longestStreak {
    if (match.gameLog.isEmpty) return (team: 0, count: 0);
    int maxTeam = match.gameLog[0], maxCount = 1;
    int curTeam = match.gameLog[0], curCount = 1;
    for (int i = 1; i < match.gameLog.length; i++) {
      if (match.gameLog[i] == curTeam) {
        curCount++;
        if (curCount > maxCount) { maxCount = curCount; maxTeam = curTeam; }
      } else {
        curTeam = match.gameLog[i];
        curCount = 1;
      }
    }
    return (team: maxTeam, count: maxCount);
  }

  /// Descriptions of detected comeback moments.
  List<String> get comebacks {
    if (match.gameLog.isEmpty) return [];
    final results = <String>[];

    // Came back from losing the first set
    if (match.status == MatchStatus.finished && match.winner != null) {
      final w = match.winner!;
      if (match.completedSets.length >= 2 && match.completedSets[0].winner != w) {
        final name = w == 1 ? match.team1Name : match.team2Name;
        results.add('$name vendte fra at tabe 1. sæt');
      }
    }

    // Came back from 3+ games down within a set
    final sg = setGameWinners;
    for (int s = 0; s < sg.length; s++) {
      final games = sg[s];
      if (s >= match.completedSets.length) break;
      final setWinner = match.completedSets[s].winner;
      int t1 = 0, t2 = 0;
      bool wasDown = false;
      for (final g in games) {
        if (g == 1) { t1++; } else { t2++; }
        if (setWinner == 1 && t2 - t1 >= 3) wasDown = true;
        if (setWinner == 2 && t1 - t2 >= 3) wasDown = true;
      }
      if (wasDown) {
        final name = setWinner == 1 ? match.team1Name : match.team2Name;
        results.add('$name kom tilbage fra bagud i sæt ${s + 1}');
      }
    }

    return results;
  }

  int get maxAbsMomentum {
    final pts = momentumPoints;
    if (pts.isEmpty) return 1;
    return pts.map((v) => v.abs()).reduce(max).clamp(1, 999);
  }
}
