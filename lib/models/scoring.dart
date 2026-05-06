import 'match_model.dart';

PadelMatch awardPoint(PadelMatch match, int team) {
  if (match.status == MatchStatus.finished) return match;
  if (match.isInTimeout || match.isInWarmup) return match;

  final startedAt = match.matchStartedAt ?? DateTime.now();
  final t1 = match.currentGameT1 + (team == 1 ? 1 : 0);
  final t2 = match.currentGameT2 + (team == 2 ? 1 : 0);

  bool gameWon = false;
  int gameWinner = 0;

  if (match.isTiebreak) {
    if (t1 >= 7 && t1 - t2 >= 2) { gameWon = true; gameWinner = 1; }
    else if (t2 >= 7 && t2 - t1 >= 2) { gameWon = true; gameWinner = 2; }
  } else {
    if (t1 >= 4 && t1 - t2 >= 2) { gameWon = true; gameWinner = 1; }
    else if (t2 >= 4 && t2 - t1 >= 2) { gameWon = true; gameWinner = 2; }
  }

  if (!gameWon) {
    return match.copyWith(currentGameT1: t1, currentGameT2: t2, matchStartedAt: startedAt);
  }

  // Game won — toggle serve, increment game count, log winner
  final newServingTeam = match.settings.serveIndicator
      ? (match.servingTeam == 1 ? 2 : 1)
      : match.servingTeam;
  final newGamesPlayed = match.totalGamesPlayed + 1;
  final newGameLog = [...match.gameLog, gameWinner];

  final setT1 = match.currentSetT1 + (gameWinner == 1 ? 1 : 0);
  final setT2 = match.currentSetT2 + (gameWinner == 2 ? 1 : 0);

  bool setWon = false;
  if (match.isTiebreak) {
    setWon = true;
  } else if (setT1 >= 6 && setT1 - setT2 >= 2) {
    setWon = true;
  } else if (setT2 >= 6 && setT2 - setT1 >= 2) {
    setWon = true;
  }

  final newTiebreak = !match.isTiebreak && setT1 == 6 && setT2 == 6;

  if (!setWon) {
    return match.copyWith(
      currentGameT1: 0,
      currentGameT2: 0,
      currentSetT1: setT1,
      currentSetT2: setT2,
      isTiebreak: newTiebreak,
      matchStartedAt: startedAt,
      servingTeam: newServingTeam,
      totalGamesPlayed: newGamesPlayed,
      gameLog: newGameLog,
    );
  }

  final completedSets = [...match.completedSets, SetScore(t1: setT1, t2: setT2)];
  final team1Sets = completedSets.where((s) => s.winner == 1).length;
  final team2Sets = completedSets.where((s) => s.winner == 2).length;
  final matchWon = team1Sets == 2 || team2Sets == 2;
  final matchWinner = team1Sets == 2 ? 1 : (team2Sets == 2 ? 2 : null);

  return match.copyWith(
    completedSets: completedSets,
    currentGameT1: 0,
    currentGameT2: 0,
    currentSetT1: 0,
    currentSetT2: 0,
    isTiebreak: false,
    status: matchWon ? MatchStatus.finished : MatchStatus.active,
    winner: matchWinner,
    matchStartedAt: startedAt,
    servingTeam: newServingTeam,
    totalGamesPlayed: newGamesPlayed,
    gameLog: newGameLog,
  );
}
