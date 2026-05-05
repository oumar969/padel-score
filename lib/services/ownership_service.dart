import 'package:shared_preferences/shared_preferences.dart';

class OwnershipService {
  static const _key = 'owned_matches';

  Future<void> claim(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_key) ?? [];
    if (!owned.contains(matchId)) {
      owned.add(matchId);
      await prefs.setStringList(_key, owned);
    }
  }

  Future<bool> isOwner(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).contains(matchId);
  }
}
