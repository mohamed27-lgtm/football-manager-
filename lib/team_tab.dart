import 'package:flutter/material.dart';
import 'game_state.dart';
import 'squad.dart';
import 'tactics.dart';
import 'widgets.dart';

/// صفحة الفريق: اللاعبون • التشكيلة والتكتيك • العقود
class TeamTab extends StatefulWidget {
  final GameState gs;
  const TeamTab({super.key, required this.gs});
  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  int view = 0;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('اللاعبون')),
              ButtonSegment(value: 1, label: Text('التشكيلة والتكتيك')),
              ButtonSegment(value: 2, label: Text('العقود')),
            ],
            selected: {view},
            onSelectionChanged: (s) => setState(() => view = s.first),
          ),
        ),
      ),
      Expanded(
        child: switch (view) {
          0 => SquadTab(gs: gs),
          1 => TacticsTab(gs: gs),
          _ => ContractsView(gs: gs),
        },
      ),
    ]);
  }
}
