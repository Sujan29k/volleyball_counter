import 'package:flutter/foundation.dart';
import '../data/local_store.dart';
import '../features/match/match.dart';

class AppController extends ChangeNotifier {
  final LocalStore store;
  AppController(this.store);
  VolleyMatch? active;
  List<VolleyMatch> history = [];
  MatchRules custom = const MatchRules(
    standard: false,
    bestOf: 3,
    target: 15,
    decider: 11,
    endChange: 6,
  );
  bool haptics = true, busy = false;
  String? error;
  Future<void> load() async {
    final unfinished = await store.matches(finished: false);
    active = unfinished.isEmpty ? null : unfinished.first;
    history = await store.matches(finished: true);
    final settings = await store.readPreference('custom');
    if (settings != null) custom = MatchRules.fromJson(settings);
    haptics = await store.readPreference('haptics') ?? true;
    notifyListeners();
  }

  Future<bool> perform(Future<void> Function() operation) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (_) {
      error =
          'Could not save locally. Your last saved score is unchanged. Please retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> create(VolleyMatch m) => perform(() async {
    if (active != null && !active!.finished) {
      active!.abandon();
      await store.save(active!);
    }
    await store.save(m);
    active = m;
    if (!m.rules.standard) {
      custom = m.rules;
      await store.preference('custom', custom.toJson());
    }
  });
  Future<bool> change(void Function(VolleyMatch) update) => perform(() async {
    final next = active!.copy();
    update(next);
    await store.save(next);
    active = next;
    history = await store.matches(finished: true);
  });
  Future<bool> setHaptics(bool value) => perform(() async {
    await store.preference('haptics', value);
    haptics = value;
  });
  Future<bool> delete(String id) => perform(() async {
    await store.delete(id);
    history.removeWhere((m) => m.id == id);
    if (active?.id == id) active = null;
  });
  Future<bool> clearHistory() => perform(() async {
    await store.clearHistory();
    history = [];
    if (active?.finished ?? false) active = null;
  });
}
