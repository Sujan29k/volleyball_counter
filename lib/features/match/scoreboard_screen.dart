import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../state/app_controller.dart';
import '../../ui/common.dart';
import '../../ui/design.dart';
import '../history/history_screen.dart';
import 'match.dart';

class ScoreboardScreen extends StatefulWidget {
  final AppController c;
  const ScoreboardScreen(this.c, {super.key});
  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen>
    with WidgetsBindingObserver {
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.c.addListener(syncAwake);
    syncAwake();
  }

  void syncAwake() {
    WakelockPlus.toggle(
      enable: foreground && !(widget.c.active?.finished ?? true),
    ).catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    syncAwake();
  }

  @override
  void dispose() {
    widget.c.removeListener(syncAwake);
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  Future<void> nextSet() async {
    final m = widget.c.active!;
    int? first;
    if (m.deciding) {
      first = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deciding set · new toss'),
          content: const Text('Who serves first after the new toss?'),
          actions: [
            for (var t = 0; t < 2; t++)
              TextButton(
                onPressed: () => Navigator.pop(context, t),
                child: Text('${t == 0 ? 'A' : 'B'} · ${m.names[t]}'),
              ),
          ],
        ),
      );
      if (first == null) return;
    }
    await widget.c.change((m) => m.startNextSet(firstServer: first));
  }

  Widget teamSide(VolleyMatch m, int t) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: m.status != MatchStatus.playing || widget.c.busy
              ? null
              : () async {
                  final saved = await widget.c.change((m) => m.point(t));
                  if (saved && widget.c.haptics) {
                    HapticFeedback.lightImpact();
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              color: Color(m.colors[t]).withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(
                  color: Color(m.colors[t])
                      .withValues(alpha: m.server == t ? 1 : 0.2),
                  width: m.server == t ? 4 : 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (m.server == t)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(Icons.sports_volleyball,
                                        size: 18, color: Color(m.colors[t])),
                                  ),
                                Text(
                                  m.names[t].toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label: '${m.names[t]} score ${m.scores[t]}',
                              liveRegion: true,
                              excludeSemantics: true,
                              child: Text(
                                '${m.scores[t]}',
                                style: TextStyle(
                                  color: Color(m.colors[t]),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  letterSpacing: -6,
                                  fontSize: 140,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(m.colors[t])
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'SETS: ${m.wins[t]}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(m.colors[t]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Small Dedicated Decrease Button positioned seamlessly at the bottom of each half
                if (m.status == MatchStatus.playing)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          side: BorderSide(
                            color: Color(m.colors[t]).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: m.scores[t] <= 0 || widget.c.busy
                            ? null
                            : () async {
                                final saved = await widget.c
                                    .change((m) => m.removePoint(t));
                                if (saved && widget.c.haptics) {
                                  HapticFeedback.mediumImpact();
                                }
                              },
                        icon: const Icon(Icons.remove, size: 16),
                        label: Text(
                          '-1 ${m.names[t]}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.c,
        builder: (context, _) {
          final c = widget.c;
          final m = c.active!;
          final order = m.swapped ? [1, 0] : [0, 1];

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.finished ? 'MATCH FINISHED' : 'LIVE SCORE'),
                  Text(
                    'SET ${m.setNumber} · TO ${m.target}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
              actions: [
                if (!m.finished)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: c.busy ? null : () => c.change((m) => m.swapSides()),
                    tooltip: 'Swap sides',
                  ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: !m.canUndo || c.busy
                      ? null
                      : () => c.change((m) => m.undo()),
                  tooltip: 'Undo',
                ),
              ],
            ),
            body: Column(
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: panel.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < m.sets.length; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: muted.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'S${i + 1}: ${m.sets[i][0]}-${m.sets[i][1]}',
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ),
                    ],
                  ),
                ),

                // Main Score Area
                Expanded(
                  child: m.status == MatchStatus.playing ||
                          m.status == MatchStatus.betweenSets
                      ? Row(
                          children: order.map((t) => teamSide(m, t)).toList(),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                              child: MatchSummary(m)),
                        ),
                ),

                // Overlay/Status Area
                if (m.reminderPending)
                  GestureDetector(
                    onTap: c.busy
                        ? null
                        : () => c.change((m) => m.reminderPending = false),
                    child: Container(
                      width: double.infinity,
                      color: amber.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        'COURT CHANGE · TAP TO DISMISS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                  ),

                if (m.status == MatchStatus.betweenSets)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: panel,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SET ${m.setNumber} FINISHED',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: electric),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${m.names[m.scores[0] > m.scores[1] ? 0 : 1]} wins ${m.scores[0]}–${m.scores[1]}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: c.busy ? null : nextSet,
                            child: const Text('START NEXT SET'),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (m.finished)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ResultScreen(c, m)),
                        ),
                        child: const Text('VIEW FINAL SUMMARY'),
                      ),
                    ),
                  ),

                // Bottom Quick Actions
                if (!m.finished && m.status == MatchStatus.playing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TAP SIDE TO ADD POINT · LONG PRESS TO UNDO',
                          style: TextStyle(fontSize: 9, color: muted),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: c.busy
                                  ? null
                                  : () async {
                                      if (await confirm(
                                        context,
                                        'Abandon match?',
                                        'Save this match as Abandoned?',
                                      )) {
                                        await c.change((m) => m.abandon());
                                      }
                                    },
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('ABANDON',
                                  style: TextStyle(fontSize: 11)),
                            ),
                            TextButton.icon(
                              onPressed: c.busy
                                  ? null
                                  : () async {
                                      if (await confirm(
                                        context,
                                        'Reset match?',
                                        'Clear all points and sets?',
                                      )) {
                                        await c.change((m) => m.reset());
                                      }
                                    },
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('RESET',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );

}
