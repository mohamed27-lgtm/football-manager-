import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'lineup_pages.dart';
import 'match_pages.dart';
import 'more_screen.dart';
import 'squad.dart';
import 'widgets.dart';

/// مركز الفريق: أزرار التشكيلة/التكتيك/التدريب + قائمة اللاعبين
class TeamTab extends StatelessWidget {
  final GameState gs;
  const TeamTab({super.key, required this.gs});

  void _go(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  Widget _big(String label, IconData icon, bool primary, VoidCallback on) => Expanded(
        child: GestureDetector(
          onTap: on,
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? kPrimary : const Color(0xFFA9D4F8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: primary ? const Color(0x55B02A10) : const Color(0x4400A0FF), offset: const Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: primary ? Colors.white : const Color(0xFF15233D)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: primary ? Colors.white : const Color(0xFF15233D))),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: Row(children: [
            _big('التشكيلة', Icons.groups_2_outlined, true, () => _go(context, LineupScreen(gs: gs))),
            _big('التكتيك', Icons.account_tree_outlined, false, () => _go(context, TacticsScreen(gs: gs))),
            _big('التدريب', Icons.fitness_center_rounded, false, () => _go(context, TrainingScreen(gs: gs))),
          ]),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => _go(context, Scaffold(appBar: gameBar(context, gs, 'العقود'), body: ContractsView(gs: gs))),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('العقود'),
          ),
        ),
        Expanded(child: SquadTab(gs: gs)),
      ]);
}
