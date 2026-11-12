import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'flags.dart';
import 'game_state.dart';
import 'widgets.dart';
import 'world.dart';

const _gold = Color(0xFFE6B422);
const _green = Color(0xFF1FA58A);

/// صفحة بطولة منتخبات: المجموعات • الأدوار الإقصائية • الهدّافون • الأبطال السابقون
class NatTourScreen extends StatefulWidget {
  final GameState gs;
  final String tourKey;
  const NatTourScreen({super.key, required this.gs, required this.tourKey});
  @override
  State<NatTourScreen> createState() => _NatTourScreenState();
}

class _NatTourScreenState extends State<NatTourScreen> {
  int tab = 0;
  int ed = 0; // 0 = الأحدث

  NatTourDef get def => kNatTours.firstWhere((d) => d.key == widget.tourKey);

  static String stageName(String s) => switch (s) {
        'R32' => 'دور الـ32',
        'R16' => 'دور الـ16',
        'QF' => 'ربع النهائي',
        'SF' => 'نصف النهائي',
        'F' => 'النهائي',
        _ => s.startsWith('G') ? 'المجموعة ${s.substring(1)}' : s,
      };

  Widget _pill(String t, bool sel, VoidCallback f) {
    final w = GestureDetector(
      onTap: f,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: sel ? const Color(0xFF15233D) : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFF15233D) : kLine)),
        child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel ? Colors.white : kMuted)),
      ),
    );
    return sel ? Unfilter(child: w) : w;
  }

  Widget _team(String n, {double size = 26, bool bold = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        FlagBadge(n, size: size),
        const SizedBox(width: 8),
        Flexible(child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: 13.5))),
      ]);

  Widget _empty(GameState gs) {
    final d = def;
    final n = ((d.offset - gs.season) % d.cycle + d.cycle) % d.cycle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 150, height: 150, decoration: BoxDecoration(color: kCard, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(30), child: CompLogo(kNatTourLogoId[d.key], fallback: Icons.emoji_events_rounded, color: _gold, size: 90))),
          const SizedBox(height: 20),
          const Text('لا توجد نسخة سابقة بعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            n == 0 ? 'تُقام النسخة القادمة في نهاية هذا الموسم.' : 'تُقام النسخة القادمة بعد $n ${n == 1 ? 'موسم' : 'مواسم'} (نهاية الموسم ${gs.season + n}).',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 14.5),
          ),
          const SizedBox(height: 6),
          Text('${d.teams} منتخباً • ${d.groups} مجموعات • تأهل حسب نتائج التصفيات داخل كل اتحاد.', textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
        ]),
      ),
    );
  }

  List<Widget> _groups(NatTour t) {
    final out = <Widget>[];
    for (var gi = 0; gi < t.groups.length; gi++) {
      final label = 'G${String.fromCharCode(65 + gi)}';
      final ms = t.matches.where((m) => m.stage == label).toList();
      final rows = {for (final n in t.groups[gi]) n: [0, 0, 0, 0, 0, 0]}; // لعب، فوز، تعادل، خسارة، فارق، نقاط
      for (final m in ms) {
        for (final s in [(m.a, m.ag, m.bg), (m.b, m.bg, m.ag)]) {
          final r = rows[s.$1]!;
          r[0]++;
          r[4] += s.$2 - s.$3;
          if (s.$2 > s.$3) {
            r[1]++;
            r[5] += 3;
          } else if (s.$2 == s.$3) {
            r[2]++;
            r[5]++;
          } else {
            r[3]++;
          }
        }
      }
      final order = t.groups[gi].toList()
        ..sort((a, b) {
          final c = rows[b]![5].compareTo(rows[a]![5]);
          return c != 0 ? c : rows[b]![4].compareTo(rows[a]![4]);
        });
      final adv = <String>{for (final m in t.matches.where((m) => !m.stage.startsWith('G'))) ...[m.a, m.b]};
      out.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: kCard2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(child: Text('المجموعة ${String.fromCharCode(65 + gi)}', style: const TextStyle(fontWeight: FontWeight.w900))),
              for (final h in const ['لعب', 'ف', 'ت', 'خ', '+/-', 'ن']) SizedBox(width: 34, child: Text(h, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w800))),
            ]),
          ),
          for (final n in order)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: adv.contains(n) ? _green.withOpacity(0.10) : null,
                border: const Border(top: BorderSide(color: kLine)),
              ),
              child: Row(children: [
                Expanded(child: _team(n, bold: n == t.champion)),
                for (var i = 0; i < 6; i++)
                  SizedBox(
                    width: 34,
                    child: Text(i == 4 && rows[n]![4] > 0 ? '+${rows[n]![4]}' : '${rows[n]![i]}', textAlign: TextAlign.center, style: TextStyle(fontWeight: i == 5 ? FontWeight.w900 : FontWeight.w600, fontSize: 13)),
                  ),
              ]),
            ),
        ]),
      ));
    }
    return out;
  }

  List<Widget> _knockout(NatTour t) {
    final out = <Widget>[];
    for (final st in const ['R32', 'R16', 'QF', 'SF', 'F']) {
      final ms = t.matches.where((m) => m.stage == st).toList();
      if (ms.isEmpty) continue;
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
        child: Text(stageName(st), style: TextStyle(color: st == 'F' ? _gold : kMuted, fontWeight: FontWeight.w900, fontSize: 14)),
      ));
      for (final m in ms) {
        final w = m.winner;
        out.add(Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: st == 'F' ? _gold : kLine, width: st == 'F' ? 1.6 : 1)),
          child: Row(children: [
            Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: _team(m.a, bold: w == m.a))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${m.ag} - ${m.bg}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (m.pa != null) Text('(${m.pa}-${m.pb}) ركلات', style: const TextStyle(color: kMuted, fontSize: 10.5)),
            ]),
            Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: _team(m.b, bold: w == m.b))),
          ]),
        ));
      }
    }
    return out;
  }

  List<Widget> _awards(NatTour t) {
    const meta = [('ball', '🏆', 'أفضل لاعب في البطولة'), ('boot', '👟', 'الحذاء الذهبي (الهدّاف)'), ('glove', '🧤', 'القفاز الذهبي'), ('young', '⭐', 'أفضل لاعب شاب')];
    final rows = <Widget>[];
    for (final m in meta) {
      final v = t.awards[m.$1];
      if (v == null) continue;
      final f = v.split('|');
      final mine = f.length == 3 && f[2] == widget.gs.user.name;
      rows.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: mine ? kPrimary : kLine, width: mine ? 2 : 1)),
        child: Row(children: [
          Container(width: 46, height: 46, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFBEBB5)), child: Text(m.$2, style: const TextStyle(fontSize: 22))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.$3, style: const TextStyle(color: kMuted, fontSize: 12)),
              Text(f[0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (f.length == 3) Text('${f[1]} • ${f[2]}', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          if (f.length == 3) FlagBadge(f[1], size: 30),
        ]),
      ));
    }
    if (rows.isEmpty) return [const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا جوائز لهذه النسخة', style: TextStyle(color: kMuted))))];
    return rows;
  }

  List<Widget> _scorers(NatTour t) {
    if (t.scorers.isEmpty) return [const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا بيانات للهدّافين', style: TextStyle(color: kMuted))))];
    final l = t.scorers.entries.toList();
    return [
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < l.length; i++)
            Builder(builder: (_) {
              final f = l[i].key.split('|');
              final mine = f.length == 3 && f[2] == widget.gs.user.name;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: mine ? kPrimary.withOpacity(0.10) : null, border: i == 0 ? null : const Border(top: BorderSide(color: kLine))),
                child: Row(children: [
                  SizedBox(width: 26, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: i == 0 ? _gold : kMuted))),
                  if (f.length == 3) FlagBadge(f[1], size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f[0], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (f.length == 3) Text('${f[1]} • ${f[2]}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
                    ]),
                  ),
                  Text('${l[i].value}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(width: 4),
                  const Icon(Icons.sports_soccer_rounded, size: 16, color: kMuted),
                ]),
              );
            }),
        ]),
      ),
    ];
  }

  List<Widget> _history(List<NatTour> eds) => [
        Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < eds.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: kLine))),
                child: Row(children: [
                  SizedBox(width: 62, child: Text('م${eds[i].season}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800))),
                  CompLogo(kNatTourLogoId[def.key], fallback: Icons.emoji_events_rounded, color: _gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: _team(eds[i].champion ?? '—', bold: true)),
                  Text('الوصيف: ${eds[i].runnerUp ?? '—'}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
                ]),
              ),
          ]),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final d = def;
    final eds = gs.nat.history.where((t) => t.key == d.key).toList().reversed.toList(); // الأحدث أولاً
    final cur = eds.isEmpty ? null : eds[ed.clamp(0, eds.length - 1)];
    final tabs = ['المجموعات', 'الإقصائيات', 'الهدّافون', 'الجوائز', 'السجل'];
    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: cur == null
          ? _empty(gs)
          : ListView(padding: const EdgeInsets.all(14), children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold, width: 1.4)),
                child: Row(children: [
                  CompLogo(kNatTourLogoId[d.key], fallback: Icons.emoji_events_rounded, color: _gold, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('بطل نسخة الموسم ${cur.season}', style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      _team(cur.champion ?? '—', size: 30, bold: true),
                      const SizedBox(height: 4),
                      Text('الوصيف: ${cur.runnerUp ?? '—'}${cur.hosts.isEmpty ? '' : '  •  المضيف: ${cur.hosts.join('، ')}'}', style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
              if (eds.length > 1) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [for (var i = 0; i < eds.length; i++) _pill('نسخة م${eds[i].season}', i == ed.clamp(0, eds.length - 1), () => setState(() => ed = i))]),
                ),
              ],
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (var i = 0; i < tabs.length; i++) _pill(tabs[i], tab == i, () => setState(() => tab = i))]),
              ),
              const SizedBox(height: 12),
              if (tab == 0) ..._groups(cur),
              if (tab == 1) ..._knockout(cur),
              if (tab == 2) ..._scorers(cur),
              if (tab == 3) ..._awards(cur),
              if (tab == 4) ..._history(eds),
            ]),
    );
  }
}
