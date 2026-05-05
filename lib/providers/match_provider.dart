import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/player_stats.dart';
import '../models/scoring.dart' as scoring;
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((_) => FirestoreService());

final matchesProvider = StreamProvider<List<PadelMatch>>((ref) {
  return ref.watch(firestoreServiceProvider).watchMatches();
});

final matchProvider = StreamProvider.family<PadelMatch, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchMatch(id);
});

final playerStatsProvider = Provider<List<PlayerStats>>((ref) {
  final matches = ref.watch(matchesProvider).valueOrNull ?? [];
  return computePlayerStats(matches);
});

final matchTimerProvider = StreamProvider.family<String, String>((ref, matchId) async* {
  while (true) {
    final match = ref.read(matchProvider(matchId)).valueOrNull;
    if (match?.matchStartedAt != null) {
      final e = DateTime.now().difference(match!.matchStartedAt!);
      final m = e.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = e.inSeconds.remainder(60).toString().padLeft(2, '0');
      yield '$m:$s';
    } else {
      yield '00:00';
    }
    await Future.delayed(const Duration(seconds: 1));
  }
});

final _undoStackProvider = StateProvider<Map<String, List<PadelMatch>>>((_) => {});

class MatchActions {
  final Ref _ref;
  MatchActions(this._ref);

  FirestoreService get _service => _ref.read(firestoreServiceProvider);

  Future<String> createMatch(
    String format,
    List<String> team1Players,
    List<String> team2Players,
  ) {
    return _service.createMatch(format, team1Players, team2Players);
  }

  Future<void> awardPoint(PadelMatch current, int team) async {
    _pushUndo(current);
    final updated = scoring.awardPoint(current, team);
    await _service.updateMatch(updated);
  }

  Future<void> undo(String matchId) async {
    final stack = Map<String, List<PadelMatch>>.from(_ref.read(_undoStackProvider));
    final history = stack[matchId];
    if (history == null || history.isEmpty) return;
    final previous = history.last;
    stack[matchId] = history.sublist(0, history.length - 1);
    _ref.read(_undoStackProvider.notifier).state = stack;
    await _service.updateMatch(previous);
  }

  bool canUndo(String matchId) {
    final history = _ref.read(_undoStackProvider)[matchId];
    return history != null && history.isNotEmpty;
  }

  Future<void> deleteMatch(String id) => _service.deleteMatch(id);

  void _pushUndo(PadelMatch match) {
    final stack = Map<String, List<PadelMatch>>.from(_ref.read(_undoStackProvider));
    final history = List<PadelMatch>.from(stack[match.id] ?? []);
    history.add(match);
    if (history.length > 20) history.removeAt(0);
    stack[match.id] = history;
    _ref.read(_undoStackProvider.notifier).state = stack;
  }
}

final matchActionsProvider = Provider((ref) => MatchActions(ref));

final canUndoProvider = Provider.family<bool, String>((ref, matchId) {
  final stack = ref.watch(_undoStackProvider);
  return (stack[matchId]?.isNotEmpty) ?? false;
});
