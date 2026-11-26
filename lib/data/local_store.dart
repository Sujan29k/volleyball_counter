import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../features/match/match.dart';

class LocalStore {
  final Database db;
  LocalStore(this.db);
  static Future<LocalStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final location = path ?? '${await f.getDatabasesPath()}/courtside.db';
    return LocalStore(
      await f.openDatabase(
        location,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE matches (id TEXT PRIMARY KEY, finished INTEGER NOT NULL, data TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
            );
          },
        ),
      ),
    );
  }

  Future<void> save(VolleyMatch m) async => db.insert('matches', {
    'id': m.id,
    'finished': m.finished ? 1 : 0,
    'data': jsonEncode(m.toJson()),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<VolleyMatch>> matches({required bool finished}) async =>
      (await db.query(
            'matches',
            where: 'finished = ?',
            whereArgs: [finished ? 1 : 0],
            orderBy: 'id DESC',
          ))
          .map((r) => VolleyMatch.fromJson(jsonDecode(r['data'] as String)))
          .toList();
  Future<void> delete(String id) async =>
      db.delete('matches', where: 'id = ?', whereArgs: [id]);
  Future<void> clearHistory() async =>
      db.delete('matches', where: 'finished = 1');
  Future<void> preference(String key, Object value) async => db.insert(
    'preferences',
    {'key': key, 'value': jsonEncode(value)},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<dynamic> readPreference(String key) async {
    final rows = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : jsonDecode(rows.first['value'] as String);
  }
}
