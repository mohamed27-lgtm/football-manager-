import 'package:flutter/material.dart' hide Text;
import 'calendar.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'match_pages.dart';
import 'widgets.dart';

/// جدول مباريات فريقك القادمة في كل البطولات بتواريخها وأوقاتها
class FixturesScreen extends StatefulWidget {
  final GameState gs;
  const FixturesScreen({super.key, required this.gs});
  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  GameState get gs => widget.gs;
  String comp = '';

  static const _colors = {
    'league': Color(0xFF1FA58A),
    'dom': Color(0xFFF0583A),
    'con': Color(0xFF2F7BE6),
    'uel': Color(0xFFF5A524),
    'uecl': Color(0xFF1FA58A),
    'sup': Color(0xFF6A6FC4),
  };

  @override
  Widget build(BuildContext context) {
    final all = gs.upcomingSchedule();
    final comps = <String, String>{};
    for (final m in all) {
      comps[m.key] = m.comp;
    }
    final list = comp.isEmpty ? all : all.where((m) => m.key == comp).toList();
    String? lastMonth;
    return Scaffold(
      appBar: gameBar(context, gs, 'جدول المباريات'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Row(children: [
            const Icon(Icons.calendar_month_rounded, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اليوم: ${GameCalendar.fmt(gs.today)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text('الموسم ${gs.season} • ${all.length} مباراة قادمة', style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            ChoiceChip(label: const Text('الكل'), selected: comp.isEmpty, onSelected: (_) => setState(() => comp = '')),
            for (final e in comps.entries) ...[
              const SizedBox(width: 8),
              ChoiceChip(label: Text(e.value), selected: comp == e.key, onSelected: (_) => setState(() => comp = e.key)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty) const EmptyState(icon: Icons.event_available_rounded, title: 'لا مباريات قادمة', subtitle: 'انتهت مبارياتك هذا الموسم.'),
        for (final m in list) ...[
          Builder(builder: (_) {
            final mk = GameCalendar.monthNames[m.date.month - 1];
            final head = lastMonth != mk;
            lastMonth = mk;
            return head
                ? Padding(padding: const EdgeInsets.only(top: 10, bottom: 8), child: Text('$mk ${m.date.year}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w900)))
                : const SizedBox.shrink();
          }),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(children: [
                Container(width: 5, color: _colors[m.key] ?? kPrimary),
                Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(children: [
                    Text('${m.date.day}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    Text(GameCalendar.dayNames[m.date.weekday - 1], style: const TextStyle(color: kMuted, fontSize: 11.5)),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${m.comp} • ${m.round}', style: TextStyle(color: _colors[m.key] ?? kPrimary, fontWeight: FontWeight.w900, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(m.home == null ? 'يُحدد الخصم بعد القرعة' : '${m.home!.name}  ×  ${m.away!.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text(m.time, style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary)))),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
