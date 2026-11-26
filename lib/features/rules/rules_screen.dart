import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../state/app_controller.dart';
import '../../ui/common.dart';

const fivbSource =
    'https://www.fivb.com/volleyball/the-game/official-volleyball-rules/';

class RulesScreen extends StatelessWidget {
  final AppController c;
  const RulesScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Rules and settings')),
      body: PageBody(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Point haptics'),
            subtitle: const Text('A light vibration when a point is saved.'),
            value: c.haptics,
            onChanged: c.busy ? null : c.setHaptics,
          ),
          SaveError(c),
          const Divider(),
          Text(
            'A quick guide to indoor volleyball',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          for (final entry in const {
            'Every rally counts':
                'Each rally awards one point. Tap +1 for the team that wins it; the app does not detect play or decide faults.',
            'Sets and matches':
                'Standard indoor matches are best of five. Win three sets to win the match. Sets go to 25; a fifth set goes to 15. Always lead by two, with no cap.',
            'Serving and rotation':
                'The rally winner serves next. When the receiving team wins the right to serve, its players rotate one position clockwise. A team that keeps winning keeps serving.',
            'First serve and court ends':
                'Alternate the starting server between non-deciding sets. A new toss decides first serve in the fifth set. Change ends between sets and when a team first reaches 8 in the fifth.',
            'Playing the ball':
                'Teams have three touches to return the ball, excluding a block contact. Do not catch or throw it. A ball touching a boundary line is in.',
            'What this app tracks':
                'Points, team serve, set wins, match completion, and end-change reminders. Swapping display sides only changes screen placement.',
            'What people enforce':
                'Players and referees handle rotations, positions, touches, faults, substitutions, and all official decisions. This manual counter is not a referee or an official scoresheet.',
            'Custom friendly matches':
                'Custom rules are not standard volleyball rules. A cap overrides the two-point lead. With win by two off, reaching the target wins. Best of one uses the normal target. Longer formats use the decider target only when both teams need one more set.',
          }.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.value),
                ],
              ),
            ),
          const Text(
            'Verified against FIVB Official Volleyball Rules 2025–2028, current edition, on 23 October 2026. See rules 6, 7.6, 8.3, 9, 12, 14.4 and 18.2. Guide available offline; opening the source requires internet.',
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                if (!await launchUrl(
                  Uri.parse(fivbSource),
                  mode: LaunchMode.externalApplication,
                )) {
                  throw StateError('Unavailable');
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open the browser. Copy the source link below.',
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Official FIVB rules'),
          ),
          const SelectableText(fivbSource),
        ],
      ),
    ),
  );
}
