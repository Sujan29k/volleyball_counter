import 'package:flutter/material.dart';
import '../../state/app_controller.dart';
import '../../ui/common.dart';
import '../match/match.dart';
import '../match/scoreboard_screen.dart';

class SetupScreen extends StatefulWidget {
  final AppController c;
  final VolleyMatch? rematch;
  const SetupScreen(this.c, {super.key, this.rematch});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController a, b, normal, decider, cap, reminder;
  late bool standard, two, capped, remind;
  late int best;
  int serve = 0;
  late List<int> colors;
  final palette = [0xff8BA9FF, 0xffF5B66B, 0xffEF8DAB, 0xffB4A0EF, 0xffA5B2C8];
  @override
  void initState() {
    super.initState();
    final r = widget.rematch?.rules ?? widget.c.custom;
    standard = widget.rematch?.rules.standard ?? true;
    best = r.bestOf;
    two = r.winByTwo;
    capped = r.cap != null;
    remind = r.endChange != null;
    a = TextEditingController(text: widget.rematch?.names[0] ?? 'Team A');
    b = TextEditingController(text: widget.rematch?.names[1] ?? 'Team B');
    normal = TextEditingController(text: '${r.target}');
    decider = TextEditingController(text: '${r.decider}');
    cap = TextEditingController(text: '${r.cap ?? 25}');
    reminder = TextEditingController(
      text: '${r.endChange ?? (r.decider / 2).ceil()}',
    );
    colors = List.of(widget.rematch?.colors ?? [palette[0], palette[1]]);
  }

  @override
  void dispose() {
    for (final t in [a, b, normal, decider, cap, reminder]) {
      t.dispose();
    }
    super.dispose();
  }

  MatchRules get rules => standard
      ? const MatchRules()
      : MatchRules(
          standard: false,
          bestOf: best,
          target: int.tryParse(normal.text) ?? 0,
          decider: int.tryParse(decider.text) ?? 0,
          winByTwo: two,
          cap: capped ? int.tryParse(cap.text) ?? 0 : null,
          endChange: best > 1 && remind
              ? int.tryParse(reminder.text) ?? 0
              : null,
        );
  Widget number(
    String label,
    TextEditingController t, {
    bool suggest = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: t,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
          ? 'Enter a positive whole number'
          : null,
      onChanged: (_) => setState(() {
        if (suggest) {
          reminder.text = '${((int.tryParse(t.text) ?? 1) / 2).ceil()}';
        }
      }),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(widget.rematch == null ? 'New match' : 'Rematch'),
      ),
      body: Form(
        key: form,
        child: PageBody(
          children: [
            Text(
              'Make it your match',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<bool>(
              isExpanded: true,
              initialValue: standard,
              decoration: const InputDecoration(labelText: 'Match format'),
              items: const [
                DropdownMenuItem(value: true, child: Text('Standard indoor')),
                DropdownMenuItem(
                  value: false,
                  child: Text(
                    'Custom friendly match',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (v) => setState(() => standard = v!),
            ),
            const SizedBox(height: 20),
            for (int team = 0; team < 2; team++) ...[
              TextFormField(
                controller: team == 0 ? a : b,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'Team ${team == 0 ? 'A' : 'B'} name',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a team name' : null,
                onChanged: (_) => setState(() {}),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (int index = 0; index < palette.length; index++)
                    Semantics(
                      label:
                          'Team ${team == 0 ? 'A' : 'B'} color ${['blue', 'amber', 'rose', 'violet', 'slate'][index]}',
                      selected: colors[team] == palette[index],
                      child: IconButton.filledTonal(
                        onPressed: () =>
                            setState(() => colors[team] = palette[index]),
                        icon: Icon(
                          colors[team] == palette[index]
                              ? Icons.check_circle
                              : Icons.circle,
                          color: Color(palette[index]),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<int>(
              initialValue: serve,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'First serve (after the toss)',
              ),
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text('A · ${a.text}', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text('B · ${b.text}', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (v) => setState(() => serve = v!),
            ),
            const SizedBox(height: 20),
            if (!standard) ...[
              const Text(
                'CUSTOM RULES · Friendly match',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: best,
                decoration: const InputDecoration(labelText: 'Match length'),
                items: [
                  for (final n in [1, 3, 5])
                    DropdownMenuItem(value: n, child: Text('Best of $n')),
                ],
                onChanged: (v) => setState(() => best = v!),
              ),
              number('Normal-set target (e.g. 11, 15, 21, 25)', normal),
              if (best > 1)
                number('Deciding-set target', decider, suggest: true),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Win by 2'),
                subtitle: const Text(
                  'Reach the target AND lead by 2. When off, first to the target wins.',
                ),
                value: two,
                onChanged: (v) => setState(() => two = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maximum score cap'),
                subtitle: const Text(
                  'First to the cap wins, even with a one-point lead.',
                ),
                value: capped,
                onChanged: (v) => setState(() => capped = v),
              ),
              if (capped) number('Cap (at least all applicable targets)', cap),
              if (best > 1) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Decider end-change reminder'),
                  subtitle: const Text(
                    'Friendly-match setting. Suggested: half the deciding target, rounded up.',
                  ),
                  value: remind,
                  onChanged: (v) => setState(() => remind = v),
                ),
                if (remind) number('Remind at this many points', reminder),
              ],
              const Text(
                'A decider is used only when both teams are one set from winning. Best of 1 uses the normal target.',
              ),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${standard ? 'Standard indoor' : 'Custom friendly rules'}\n${rules.summary}',
                ),
              ),
            ),
            if (rules.validate() != null)
              Text(
                rules.validate()!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            SaveError(widget.c),
            FilledButton.icon(
              onPressed: widget.c.busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate() ||
                          rules.validate() != null) {
                        return;
                      }
                      final now = DateTime.now();
                      final m = VolleyMatch(
                        id: '${now.microsecondsSinceEpoch}',
                        createdAt: now.toIso8601String(),
                        names: [a.text.trim(), b.text.trim()],
                        colors: List.of(colors),
                        rules: rules,
                        initialServer: serve,
                      );
                      if (await widget.c.create(m) && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScoreboardScreen(widget.c),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start match'),
            ),
          ],
        ),
      ),
    ),
  );
}
