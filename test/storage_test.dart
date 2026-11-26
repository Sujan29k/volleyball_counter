import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:courtside/data/local_store.dart';
import 'package:courtside/features/match/match.dart';
import 'package:courtside/state/app_controller.dart';

void main() {
  test(
    'SQLite restart restores unfinished match, undo, preferences and history',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('courtside_test');
      final path = '${dir.path}/test.db';
      var store = await LocalStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var c = AppController(store);
      await c.load();
      final m = VolleyMatch(
        id: '1',
        createdAt: '2026-10-23',
        names: ['A', 'B'],
        colors: [1, 2],
        rules: const MatchRules(standard: false, bestOf: 1, target: 2),
      );
      await c.create(m);
      await c.change((m) => m.point(1));
      await c.change((m) => m.swapSides());
      await c.setHaptics(false);
      await store.db.close();
      store = await LocalStore.open(factory: databaseFactoryFfi, path: path);
      c = AppController(store);
      await c.load();
      expect(c.active!.scores, [0, 1]);
      expect(c.active!.server, 1);
      expect(c.active!.swapped, true);
      expect(c.haptics, false);
      expect(c.custom.target, 2);
      await c.change((m) => m.point(1));
      expect(c.history.length, 1);
      await c.change((m) => m.undo());
      expect(c.history, isEmpty);
      expect((await store.matches(finished: false)).single.scores, [0, 1]);
      await c.change((m) => m.abandon());
      expect(c.history.single.winner, null);
      await c.clearHistory();
      expect(await store.matches(finished: true), isEmpty);
      await store.db.close();
      await dir.delete(recursive: true);
    },
  );
}
