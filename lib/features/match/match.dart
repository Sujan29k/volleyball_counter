import 'dart:convert';

class MatchRules {
  final bool standard, winByTwo;
  final int bestOf, target, decider;
  final int? cap, endChange;
  const MatchRules({
    this.standard = true,
    this.bestOf = 5,
    this.target = 25,
    this.decider = 15,
    this.winByTwo = true,
    this.cap,
    this.endChange = 8,
  });
  int get winsNeeded => bestOf ~/ 2 + 1;
  String? validate() {
    if (![1, 3, 5].contains(bestOf)) return 'Choose best of 1, 3 or 5.';
    if (target < 1 || decider < 1) {
      return 'Targets must be positive whole numbers.';
    }
    if (cap != null && (cap! < target || (bestOf > 1 && cap! < decider))) {
      return 'The cap must be at least every applicable set target.';
    }
    if (endChange != null && (endChange! < 1 || endChange! > decider)) {
      return 'End-change reminder must be between 1 and the deciding target.';
    }
    return null;
  }

  String get summary =>
      'Best of $bestOf • Sets to $target${bestOf > 1 ? ' • Decider to $decider' : ''} • ${winByTwo ? 'Win by 2' : 'First to target'} • ${cap == null ? 'No cap' : 'Cap $cap'}';
  Map<String, dynamic> toJson() => {
    'standard': standard,
    'bestOf': bestOf,
    'target': target,
    'decider': decider,
    'winByTwo': winByTwo,
    'cap': cap,
    'endChange': endChange,
  };
  factory MatchRules.fromJson(Map<String, dynamic> j) => MatchRules(
    standard: j['standard'],
    bestOf: j['bestOf'],
    target: j['target'],
    decider: j['decider'],
    winByTwo: j['winByTwo'],
    cap: j['cap'],
    endChange: j['endChange'],
  );
}

enum MatchStatus { playing, betweenSets, completed, abandoned }

class VolleyMatch {
  final String id, createdAt;
  final List<String> names;
  final List<int> colors;
  final MatchRules rules;
  final int initialServer;
  List<int> scores = [0, 0];
  List<List<int>> sets = [];
  int server, setFirstServer;
  bool swapped = false, reminderShown = false, reminderPending = false;
  MatchStatus status = MatchStatus.playing;
  final List<Map<String, dynamic>> _undo = [];
  VolleyMatch({
    required this.id,
    required this.createdAt,
    required this.names,
    required this.colors,
    required this.rules,
    this.initialServer = 0,
  }) : server = initialServer,
       setFirstServer = initialServer;
  List<int> get wins => [
    sets.where((s) => s[0] > s[1]).length,
    sets.where((s) => s[1] > s[0]).length,
  ];
  bool get deciding =>
      rules.bestOf > 1 && wins.every((w) => w == rules.winsNeeded - 1);
  // During a finished set, its target is determined from the preceding sets.
  bool get currentDeciding => rules.bestOf > 1 && setNumber == rules.bestOf;
  int get target => currentDeciding ? rules.decider : rules.target;
  int get setNumber => sets.length + (status == MatchStatus.playing ? 1 : 0);
  bool get finished =>
      status == MatchStatus.completed || status == MatchStatus.abandoned;
  bool get canUndo => _undo.isNotEmpty && status != MatchStatus.abandoned;
  int? get winner =>
      status == MatchStatus.completed ? (wins[0] > wins[1] ? 0 : 1) : null;
  bool setWon(int a, int b) =>
      (rules.cap != null && a >= rules.cap!) ||
      (a >= target && a - b >= (rules.winByTwo ? 2 : 1));
  void point(int team) {
    if (status != MatchStatus.playing || team < 0 || team > 1) return;
    _undo.add(_state());
    scores[team]++;
    server = team;
    if (currentDeciding &&
        !reminderShown &&
        rules.endChange != null &&
        scores[team] >= rules.endChange!) {
      reminderShown = true;
      reminderPending = true;
    }
    if (setWon(scores[team], scores[1 - team])) {
      sets.add(List.of(scores));
      status = wins[team] == rules.winsNeeded
          ? MatchStatus.completed
          : MatchStatus.betweenSets;
    }
  }

  void removePoint(int team) {
    if (status != MatchStatus.playing || team < 0 || team > 1 || scores[team] <= 0) return;
    _undo.add(_state());
    scores[team]--;
    // Logic for reminder undo is implicit in _state restoration
  }

  void startNextSet({int? firstServer}) {
    if (status != MatchStatus.betweenSets) return;
    if (deciding && firstServer == null) {
      throw StateError('A deciding set needs a new toss.');
    }
    if (firstServer != null && firstServer != 0 && firstServer != 1) {
      throw ArgumentError('Invalid team');
    }
    setFirstServer = deciding ? firstServer! : 1 - setFirstServer;
    server = setFirstServer;
    scores = [0, 0];
    reminderShown = reminderPending = false;
    status = MatchStatus.playing;
  }

  void undo() {
    if (canUndo) _restore(_undo.removeLast());
  }

  void swapSides() {
    swapped = !swapped;
  }

  void abandon() {
    if (!finished) status = MatchStatus.abandoned;
  }

  void reset() {
    scores = [0, 0];
    sets = [];
    server = setFirstServer = initialServer;
    status = MatchStatus.playing;
    reminderShown = reminderPending = false;
    _undo.clear();
  }

  Map<String, dynamic> _state() => {
    'scores': List.of(scores),
    'sets': sets.map((s) => List.of(s)).toList(),
    'server': server,
    'setFirstServer': setFirstServer,
    'swapped': swapped,
    'status': status.name,
    'reminderShown': reminderShown,
    'reminderPending': reminderPending,
  };
  void _restore(Map<String, dynamic> j) {
    scores = List<int>.from(j['scores']);
    sets = (j['sets'] as List).map((s) => List<int>.from(s)).toList();
    server = j['server'];
    setFirstServer = j['setFirstServer'];
    swapped = j['swapped'];
    status = MatchStatus.values.byName(j['status']);
    reminderShown = j['reminderShown'];
    reminderPending = j['reminderPending'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'names': names,
    'colors': colors,
    'rules': rules.toJson(),
    'initialServer': initialServer,
    'state': _state(),
    'undo': _undo,
  };
  factory VolleyMatch.fromJson(Map<String, dynamic> j) {
    final m = VolleyMatch(
      id: j['id'],
      createdAt: j['createdAt'],
      names: List<String>.from(j['names']),
      colors: List<int>.from(j['colors']),
      rules: MatchRules.fromJson(j['rules']),
      initialServer: j['initialServer'],
    );
    m._restore(j['state']);
    m._undo.addAll(
      (j['undo'] as List).map((s) => Map<String, dynamic>.from(s)),
    );
    return m;
  }
  VolleyMatch copy() => VolleyMatch.fromJson(jsonDecode(jsonEncode(toJson())));
}
