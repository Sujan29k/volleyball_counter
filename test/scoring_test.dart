import 'package:flutter_test/flutter_test.dart';
import 'package:courtside/features/match/match.dart';

VolleyMatch match([MatchRules rules = const MatchRules()]) => VolleyMatch(
  id: '1',
  createdAt: '2026-10-23',
  names: ['A', 'B'],
  colors: [0, 1],
  rules: rules,
);
void winSet(VolleyMatch m, int t) {
  while (m.status == MatchStatus.playing) {
    m.point(t);
  }
}

void main() {
  test('standard targets and deuce', () {
    final m = match();
    expect(m.setWon(25, 23), true);
    expect(m.setWon(25, 24), false);
    expect(m.setWon(26, 24), true);
    m.sets = [
      [25, 0],
      [0, 25],
      [25, 0],
      [0, 25],
    ];
    expect(m.target, 15);
    expect(m.setWon(15, 14), false);
    expect(m.setWon(16, 14), true);
  });
  test('custom win by two toggle and cap', () {
    final m = match(const MatchRules(standard: false, target: 15));
    expect(m.setWon(15, 14), false);
    expect(m.setWon(16, 14), true);
    final sudden = match(
      const MatchRules(standard: false, target: 15, winByTwo: false),
    );
    expect(sudden.setWon(15, 14), true);
    final capped = match(
      const MatchRules(standard: false, target: 15, cap: 17),
    );
    expect(capped.setWon(16, 15), false);
    expect(capped.setWon(17, 16), true);
  });
  for (final best in [1, 3, 5]) {
    test('best of $best completion and correct deciding target', () {
      final m = match(
        MatchRules(standard: false, bestOf: best, target: 3, decider: 2),
      );
      expect(m.target, 3);
      for (int n = 0; n < best ~/ 2; n++) {
        winSet(m, 0);
        m.startNextSet();
        winSet(m, 1);
        if (m.deciding) {
          expect(() => m.startNextSet(), throwsStateError);
          m.startNextSet(firstServer: 1);
        } else {
          m.startNextSet();
        }
      }
      expect(m.target, best == 1 ? 3 : 2);
      winSet(m, 0);
      expect(m.status, MatchStatus.completed);
      expect(m.winner, 0);
      final score = List.of(m.scores);
      m.point(1);
      expect(m.scores, score);
      m.undo();
      expect(m.status, MatchStatus.playing);
      expect(m.winner, null);
      expect(m.sets.length, best - 1);
    });
  }
  test('serve, alternating starts, swaps, and complete point undo', () {
    final m = match(const MatchRules(standard: false, target: 3));
    m.point(1);
    expect(m.server, 1);
    m.point(1);
    expect(m.server, 1);
    m.point(0);
    expect(m.server, 0);
    m.undo();
    expect(m.server, 1);
    expect(m.scores, [0, 2]);
    m.swapSides();
    expect(m.swapped, true);
    expect(m.names, ['A', 'B']);
    expect(m.scores, [0, 2]);
    m.point(1);
    expect(m.status, MatchStatus.betweenSets);
    expect(m.wins, [0, 1]);
    m.startNextSet();
    expect(m.server, 1);
    m.undo();
    expect(m.status, MatchStatus.playing);
    expect(m.scores, [0, 2]);
    expect(m.sets, isEmpty);
    expect(m.swapped, true);
  });
  test('decider reminder is non-scoring and can trigger again after undo', () {
    final m = match();
    m.sets = [
      [25, 0],
      [0, 25],
      [25, 0],
      [0, 25],
    ];
    for (int i = 0; i < 8; i++) {
      m.point(1);
    }
    expect(m.reminderPending, true);
    expect(m.scores, [0, 8]);
    expect(m.server, 1);
    m.undo();
    expect(m.reminderPending, false);
    m.point(1);
    expect(m.reminderPending, true);
  });
  test('validation covers both targets and best of one exception', () {
    expect(
      const MatchRules(
        standard: false,
        target: 15,
        decider: 21,
        cap: 15,
      ).validate(),
      isNotNull,
    );
    expect(
      const MatchRules(
        standard: false,
        bestOf: 1,
        target: 15,
        decider: 21,
        cap: 15,
      ).validate(),
      isNull,
    );
  });
  test('abandon never invents winner; reset clears scoring and undo', () {
    final m = match();
    m.point(0);
    m.abandon();
    expect(m.winner, null);
    expect(m.canUndo, false);
    m.reset();
    expect(m.scores, [0, 0]);
    expect(m.canUndo, false);
    expect(m.status, MatchStatus.playing);
  });
}
