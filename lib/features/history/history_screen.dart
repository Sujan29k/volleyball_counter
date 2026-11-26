import 'package:flutter/material.dart';
import '../../state/app_controller.dart';
import '../../ui/common.dart';
import '../match/match.dart';
import '../setup/setup_screen.dart';

class SetScores extends StatelessWidget {
  final VolleyMatch m;
  const SetScores(this.m, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (m.sets.isEmpty) const ListTile(title: Text('No completed sets yet.')),
      for (int i = 0; i < m.sets.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Set ${i + 1}'),
          subtitle: Text('${m.names[0]} (A) — ${m.names[1]} (B)'),
          trailing: Text(
            '${m.sets[i][0]} – ${m.sets[i][1]}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
    ],
  );
}

class MatchSummary extends StatelessWidget {
  final VolleyMatch m;
  const MatchSummary(this.m, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(m.names.join(' vs '), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        '${m.createdAt.substring(0, 10)} · ${m.status == MatchStatus.abandoned
            ? 'Abandoned · no winner'
            : m.status == MatchStatus.completed
            ? 'Completed'
            : 'In progress'}',
      ),
      Text('Sets: ${m.wins[0]} – ${m.wins[1]}'),
      Text(
        '${m.rules.standard ? 'Standard indoor' : 'Custom friendly rules'}\n${m.rules.summary}',
      ),
      SetScores(m),
      if (m.status == MatchStatus.abandoned)
        Text('Unfinished set: ${m.scores[0]} – ${m.scores[1]}'),
    ],
  );
}

class ResultScreen extends StatelessWidget {
  final AppController c;
  final VolleyMatch m;
  const ResultScreen(this.c, this.m, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Match summary')),
    body: PageBody(
      children: [
        Icon(
          m.winner == null ? Icons.flag_outlined : Icons.emoji_events_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          m.winner == null ? 'Abandoned' : '${m.names[m.winner!]} wins!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        MatchSummary(m),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: c.active != null && !c.active!.finished
              ? null
              : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SetupScreen(c, rematch: m)),
                ),
          child: const Text('Rematch · review setup'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text('Back to home'),
        ),
      ],
    ),
  );
}

class HistoryScreen extends StatelessWidget {
  final AppController c;
  const HistoryScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Match history')),
      body: PageBody(
        children: [
          if (c.history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'A fresh court. Finished and abandoned matches will appear here.',
              ),
            ),
          for (final m in c.history)
            Card(
              child: ListTile(
                isThreeLine: true,
                title: Text(m.names.join(' vs ')),
                subtitle: Text(
                  '${m.createdAt.substring(0, 10)} · ${m.status == MatchStatus.abandoned ? 'Abandoned' : '${m.names[m.winner!]} won'}\nSets ${m.wins[0]}–${m.wins[1]}',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultScreen(c, m)),
                ),
                trailing: IconButton(
                  tooltip: 'Delete match',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: c.busy
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'Delete this match?',
                            'This saved match will be permanently removed.',
                          )) {
                            await c.delete(m.id);
                          }
                        },
                ),
              ),
            ),
          if (c.history.isNotEmpty)
            TextButton(
              onPressed: c.busy
                  ? null
                  : () async {
                      if (await confirm(
                        context,
                        'Clear match history?',
                        'Permanently delete all completed and abandoned matches? Your unfinished match will stay.',
                      )) {
                        await c.clearHistory();
                      }
                    },
              child: const Text('Clear history'),
            ),
          SaveError(c),
        ],
      ),
    ),
  );
}
