import 'package:flutter_test/flutter_test.dart';
import 'package:padel_score/models/match_model.dart';
import 'package:padel_score/models/match_settings.dart';
import 'package:padel_score/models/scoring.dart';

PadelMatch _newMatch() => PadelMatch.create(
      id: 'test',
      format: '2v2',
      team1Players: ['Ali', 'Bob'],
      team2Players: ['Carl', 'Dan'],
      settings: const MatchSettings(serveIndicator: true),
      initialServingTeam: 1,
      ownerId: 'test-user',
    );

void main() {
  group('Padel scoring', () {
    test('point tæller korrekt', () {
      final m = awardPoint(_newMatch(), 1);
      expect(m.currentGameT1, 1);
      expect(m.currentGameT2, 0);
    });

    test('timer starter ved første point', () {
      final m = awardPoint(_newMatch(), 1);
      expect(m.matchStartedAt, isNotNull);
    });

    test('serve skifter efter spil', () {
      var m = _newMatch();
      expect(m.servingTeam, 1);
      for (int i = 0; i < 4; i++) { m = awardPoint(m, 1); }
      expect(m.servingTeam, 2);
    });

    test('spil tæller for boldbytte', () {
      var m = _newMatch();
      for (int i = 0; i < 4; i++) { m = awardPoint(m, 1); }
      expect(m.totalGamesPlayed, 1);
    });

    test('deuce og advantage', () {
      var m = _newMatch();
      for (int i = 0; i < 3; i++) { m = awardPoint(m, 1); }
      for (int i = 0; i < 3; i++) { m = awardPoint(m, 2); }
      expect(m.isDeuce, true);
      m = awardPoint(m, 1);
      expect(m.team1HasAdvantage, true);
    });

    test('sæt vindes ved 6 spil', () {
      var m = _newMatch();
      for (int game = 0; game < 6; game++) {
        for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 1); }
      }
      expect(m.completedSets.length, 1);
    });

    test('tiebreak ved 6-6', () {
      var m = _newMatch();
      for (int g = 0; g < 5; g++) { for (int p = 0; p < 4; p++) { m = awardPoint(m, 1); } }
      for (int g = 0; g < 5; g++) { for (int p = 0; p < 4; p++) { m = awardPoint(m, 2); } }
      for (int p = 0; p < 4; p++) { m = awardPoint(m, 1); }
      for (int p = 0; p < 4; p++) { m = awardPoint(m, 2); }
      expect(m.isTiebreak, true);
    });
  });
}
