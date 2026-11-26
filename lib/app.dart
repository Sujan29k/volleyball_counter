import 'package:flutter/material.dart';
import 'state/app_controller.dart';
import 'features/setup/setup_screen.dart';
import 'features/match/scoreboard_screen.dart';
import 'features/history/history_screen.dart';
import 'features/rules/rules_screen.dart';
import 'ui/common.dart';
import 'ui/design.dart';

class CourtsideApp extends StatelessWidget {
  final AppController controller;
  const CourtsideApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Courtside',
    debugShowCheckedModeBanner: false,
    theme: courtsideTheme(),
    home: HomeScreen(controller),
  );
}

class HomeScreen extends StatelessWidget {
  final AppController c;
  const HomeScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final resumable = c.active != null && !c.active!.finished;
      void open(Widget page) =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'COURT / SIDE',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.sports_volleyball_outlined, color: electric),
            ),
          ],
        ),
        body: PageBody(
          children: [
            const SizedBox(height: 12),
            const Text(
              'THE GAME, IN YOUR HANDS',
              style: TextStyle(
                color: electric,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Every rally.\nEvery point.',
              style: TextStyle(
                fontSize: 46,
                height: 1.05,
                letterSpacing: -2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Stay in the game. We’ll keep score.',
              style: TextStyle(color: muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: panel,
                child: const Column(
                  children: [
                    CourtArt(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'READY FOR THE FIRST SERVE',
                              style: TextStyle(
                                color: muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (resumable) ...[
              FilledButton.icon(
                onPressed: () => open(ScoreboardScreen(c)),
                icon: const Icon(Icons.play_arrow),
                label: Text('Resume: ${c.active!.names.join(' vs ')}'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: () => open(SetupScreen(c)),
              icon: const Icon(Icons.add),
              label: const Text('New match'),
            ),
            const SizedBox(height: 24),
            HomeLink(
              icon: Icons.history_rounded,
              title: 'Match history',
              subtitle: 'Your games, all in one place',
              onTap: () => open(HistoryScreen(c)),
            ),
            HomeLink(
              icon: Icons.tune_rounded,
              title: 'Rules and settings',
              subtitle: 'Set up your way to play',
              onTap: () => open(RulesScreen(c)),
            ),
            const SizedBox(height: 16),
            const Text(
              'OFFLINE. ON COURT. ALL YOURS.',
              style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.8),
              textAlign: TextAlign.center,
            ),
            SaveError(c),
          ],
        ),
      );
    },
  );
}
