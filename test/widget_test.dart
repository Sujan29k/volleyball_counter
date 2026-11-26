import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:courtside/features/match/match.dart';
import 'package:courtside/app.dart';
import 'package:courtside/data/local_store.dart';
import 'package:courtside/state/app_controller.dart';

void main() {
  testWidgets(
    'setup and scoreboard fit portrait, landscape, and enlarged text',
    (tester) async {
      final c = AppController(MemoryStore());
      await c.load();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(CourtsideApp(controller: c));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home.png'));
      await tester.tap(find.text('New match'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/setup.png'));
      await tester.ensureVisible(find.text('Start match'));
      await tester.tap(find.text('Start match'));
      await tester.pumpAndSettle();
      expect(find.text('TEAM A'), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/scoreboard.png'));
      await tester.tap(find.text('TEAM A'));
      await tester.pumpAndSettle();
      expect(c.active!.scores, [1, 0]);
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());

    },
  );
}

class FakeDatabase extends Fake implements Database {}
class MemoryStore extends LocalStore {
  MemoryStore() : super(FakeDatabase());
  final saved = <String, VolleyMatch>{};
  final prefs = <String, Object>{};
  @override
  Future<void> save(VolleyMatch m) async { saved[m.id] = m.copy(); }
  @override
  Future<List<VolleyMatch>> matches({required bool finished}) async => saved.values.where((m) => m.finished == finished).toList();
  @override
  Future<void> preference(String key, Object value) async { prefs[key] = value; }
  @override
  Future<dynamic> readPreference(String key) async => prefs[key];
}
