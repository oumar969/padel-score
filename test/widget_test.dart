import 'package:flutter_test/flutter_test.dart';
import 'package:padel_score/models/match_model.dart';
import 'package:padel_score/models/scoring.dart';

void main() {
  group('Padel scoring', () {
    late PadelMatch match;

    setUp(() {
      match = PadelMatch.create(
        id: 'test',
        format: '2v2',
        team1Players: ['Ali', 'Bob'],
        team2Players: ['Carl', 'Dan'],
      );
    });

    test('point tæller korrekt', () {
      final m = awardPoint(match, 1);
      expect(m.currentGameT1, 1);
      expect(m.currentGameT2, 0);
    });

    test('timer starter ved første point', () {
      expect(match.matchStartedAt, isNull);
      final m = awardPoint(match, 1);
      expect(m.matchStartedAt, isNotNull);
    });

    test('spil vindes ved 4 points med 2 forans', () {
      var m = match;
      for (int i = 0; i < 4; i++) { m = awardPoint(m, 1); }
      expect(m.currentSetT1, 1);
      expect(m.currentGameT1, 0);
    });

    test('deuce og advantage', () {
      var m = match;
      for (int i = 0; i < 3; i++) { m = awardPoint(m, 1); }
      for (int i = 0; i < 3; i++) { m = awardPoint(m, 2); }
      expect(m.isDeuce, true);
      m = awardPoint(m, 1);
      expect(m.team1HasAdvantage, true);
      m = awardPoint(m, 2);
      expect(m.isDeuce, true);
    });

    test('sæt vindes ved 6 spil med 2 forans', () {
      var m = match;
      for (int game = 0; game < 6; game++) {
        for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 1); }
      }
      expect(m.completedSets.length, 1);
      expect(m.completedSets.first.t1, 6);
    });

    test('tiebreak aktiveres ved 6-6 i samme sæt', () {
      var m = match;
      for (int game = 0; game < 5; game++) {
        for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 1); }
      }
      for (int game = 0; game < 5; game++) {
        for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 2); }
      }
      for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 1); }
      for (int pt = 0; pt < 4; pt++) { m = awardPoint(m, 2); }
      expect(m.isTiebreak, true);
    });
  });
}
