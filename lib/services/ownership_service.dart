import 'package:web/web.dart' as web;

class OwnershipService {
  static const _key = 'padel_owned_matches';

  Future<void> claim(String matchId) async {
    try {
      final list = _load();
      if (!list.contains(matchId)) {
        list.add(matchId);
        web.window.localStorage.setItem(_key, list.join(','));
      }
    } catch (_) {}
  }

  Future<bool> isOwner(String matchId) async {
    try {
      return _load().contains(matchId);
    } catch (_) {
      return false;
    }
  }

  List<String> _load() {
    final raw = web.window.localStorage.getItem(_key) ?? '';
    return raw.isEmpty ? [] : raw.split(',');
  }
}
