import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'flags.dart';
import 'auth.dart';
import 'game_state.dart';
import 'models.dart';
import 'calendar.dart';
import 'world.dart';
import 'widgets.dart';

/// الترتيب العالمي: أندية (Elo) / دول (من جنسيات اللاعبين) / لاعبون / مدربون
class RankingScreen extends StatefulWidget {
  final GameState gs;
  const RankingScreen({super.key, required this.gs});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  GameState get gs => widget.gs;
  int tab = 0;
  String? _me;

  @override
  void initState() {
    super.initState();
    AuthService.current().then((a) {
      if (mounted && a != null) setState(() => _me = a.name);
    });
  }

  String conf = 'all'; // فلتر الاتحاد القاري

  static const _medals = [Color(0xFFE6B422), Color(0xFFB8BECB), Color(0xFFC98B5B)];

  Widget _rank(int i, bool me) {
    final medal = i <= 3 ? _medals[i - 1] : null;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: medal == null ? null : BoxDecoration(color: medal, shape: BoxShape.circle),
      child: Text('$i', style: TextStyle(fontWeight: FontWeight.w900, color: medal == null ? kMuted : Colors.white)),
    );
  }

  Widget _row(int i, Widget lead, String title, String sub, Widget trail, {bool me = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: me ? kPrimary.withOpacity(0.1) : kCard, border: const Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          _rank(i, me),
          const SizedBox(width: 10),
          lead,
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: me ? FontWeight.w900 : FontWeight.w700)),
              if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ]),
          ),
          trail,
        ]),
      );

  Widget _summary(int rank, Widget lead, String title, String sub) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withOpacity(0.35))),
        child: Row(children: [
          Text('#$rank', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(width: 14),
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
        ]),
      );

  Widget _pill(String t, bool sel, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: sel ? const Color(0xFF15233D) : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFF15233D) : kLine)),
          child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel ? Colors.white : kMuted)),
        ),
      );

  Widget _card(List<Widget> rows) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  Widget _confChips() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final e in [('all', 'الكل'), ...kConfNames.entries.map((x) => (x.key, x.value))])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: conf == e.$1 ? Unfilter(child: _pill(e.$2, true, () => setState(() => conf = e.$1))) : _pill(e.$2, false, () => setState(() => conf = e.$1)),
              ),
          ]),
        ),
      );

  Widget _initial(String n, {double size = 30}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: kCard2, shape: BoxShape.circle),
        child: Text(n.isEmpty ? '?' : n.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900, color: kMuted)),
      );

  List<Widget> _clubs() {
    final all = gs.worldClubTable();
    final mine = all.indexWhere((e) => e.$4 == gs.user) + 1;
    final shown = <(int, (String, String, double, Team?))>[
      for (var i = 0; i < all.length; i++)
        if (conf == 'all' || all[i].$2 == conf) (i + 1, all[i])
    ];
    return [
      _summary(mine, teamBadge(gs.user, size: 44), gs.user.name, '${(gs.clubPts[gs.user.name] ?? 0).toStringAsFixed(1)} نقطة • من ${all.length} نادياً'),
      _confChips(),
      _card([
        for (final e in shown.take(150))
          _row(e.$1, e.$2.$4 != null ? teamBadge(e.$2.$4!, size: 30) : _initial(e.$2.$1), e.$2.$1, kConfNames[e.$2.$2] ?? '', Text(e.$2.$3.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)), me: e.$2.$4 == gs.user),
      ]),
    ];
  }

  List<Player> _allPlayers() => [for (final t in gs.worldRanking) ...t.squad];

  /// ترتيب المنتخبات: نقاط فيفا (P = P0 + I × (W − We)) تتغير بعد كل مباراة دولية وبطولة
  List<Widget> _countries() {
    gs.ensureNat();
    final rank = gs.nat.pubRanking;
    if (rank.isEmpty) return [const EmptyState(icon: Icons.flag_outlined, title: 'لا بيانات', subtitle: 'لا توجد منتخبات.')];
    final mine = rank.indexOf(gs.country) + 1;
    final shown = <(int, String)>[
      for (var i = 0; i < rank.length; i++)
        if (conf == 'all' || gs.nat.conf[rank[i]] == conf) (i + 1, rank[i])
    ];
    Widget trail(String n) {
      final p = gs.nat.pub[n] ?? gs.nat.rating(n);
      final now = rank.indexOf(n) + 1;
      final was = gs.nat.prevRk[n] ?? now;
      final d = was - now; // موجب = صعود في الترتيب
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(p.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(d == 0 ? '—' : '${d > 0 ? '▲' : '▼'} ${d.abs()}', style: TextStyle(fontSize: 11, color: d == 0 ? kMuted : (d > 0 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)))),
      ]);
    }

    return [
      _release(),
      if (mine > 0) _summary(mine, FlagBadge(gs.country, size: 44), 'منتخب ${gs.country}', '${(gs.nat.pub[gs.country] ?? gs.nat.rating(gs.country)).toStringAsFixed(1)} نقطة • من ${rank.length} منتخباً'),
      _confChips(),
      _card([
        for (final e in shown.take(220)) InkWell(onTap: () => _natMatches(e.$2), child: _row(e.$1, FlagBadge(e.$2, size: 30), e.$2, kConfNames[gs.nat.conf[e.$2]] ?? '', trail(e.$2), me: e.$2 == gs.country)),
      ]),
    ];
  }

  /// بطاقة موعد الإصدار: آخر إصدار رسمي والنافذة الدولية القادمة
  Widget _release() {
    final w = gs.nextWindow;
    final next = w == null ? 'لا نوافذ هذا الموسم' : 'النافذة القادمة: ${NatState.winNames[w]} • ${GameCalendar.fmtShort(intlWindowDate(gs.season, w))}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
      child: Row(children: [
        const Icon(Icons.event_note_rounded, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gs.nat.pubDate.isEmpty ? 'لم يصدر تصنيف بعد' : 'آخر إصدار رسمي: ${gs.nat.pubDate}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text(next, style: const TextStyle(color: kMuted, fontSize: 12)),
            const Text('يتحدّث التصنيف بعد كل نافذة دولية بأسبوع', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  /// آخر المباريات الدولية لمنتخب: رسمية (تصفيات وبطولات) وودية
  void _natMatches(String n) {
    final rows = <(int, int, String, String, int, int, String)>[]; // موسم، ترتيب، أ، ب، هأ، هب، نوع
    for (final l in gs.nat.log) {
      if (l[2] == n || l[3] == n) rows.add((l[0] as int, l[1] as int, l[2] as String, l[3] as String, l[4] as int, l[5] as int, (l[6] as int) == 0 ? 'تصفيات رسمية • نافذة ${NatState.winNames[(l[1] as int).clamp(0, 4)]}' : 'ودية • نافذة ${NatState.winNames[(l[1] as int).clamp(0, 4)]}'));
    }
    for (final t in gs.nat.history) {
      for (final m in t.matches) {
        if (m.a == n || m.b == n) rows.add((t.season, 99, m.a, m.b, m.ag, m.bg, '${t.name} • ${m.stage}'));
      }
    }
    rows.sort((a, b) {
      final c = b.$1.compareTo(a.$1);
      return c != 0 ? c : b.$2.compareTo(a.$2);
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(14), children: [
          Row(children: [
            FlagBadge(n, size: 34),
            const SizedBox(width: 10),
            Expanded(child: Text('مباريات $n', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            Text('${gs.nat.rating(n).toStringAsFixed(1)} نقطة', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          if (rows.isEmpty) const EmptyState(icon: Icons.sports_soccer, title: 'لا مباريات بعد', subtitle: 'تُلعب النوافذ الدولية في نهاية كل موسم.'),
          for (final r in rows.take(60))
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
              child: Row(children: [
                Expanded(child: Text(r.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: r.$3 == n ? FontWeight.w900 : FontWeight.w600))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${r.$5} - ${r.$6}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('م${r.$1} • ${r.$7}', style: const TextStyle(color: kMuted, fontSize: 10.5)),
                ]),
                Expanded(child: Text(r.$4, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: r.$4 == n ? FontWeight.w900 : FontWeight.w600))),
              ]),
            ),
        ]),
      ),
    );
  }

  List<Widget> _players() {
    final all = _allPlayers()..sort((a, b) => b.overall.compareTo(a.overall));
    final club = {for (final t in gs.worldRanking) for (final p in t.squad) p.id: t};
    return [
      for (var i = 0; i < all.length && i < 300; i++)
        _row(
          i + 1,
          teamBadge(club[all[i].id] ?? gs.user, size: 30),
          all[i].name,
          '${club[all[i].id]?.name ?? ''} • ${all[i].nat ?? ''}',
          ratingRing(all[i].overall, size: 34),
          me: gs.user.squad.contains(all[i]),
        ),
    ];
  }

  List<Widget> _coaches() {
    final all = [...gs.worldRanking]..sort((a, b) => (gs.clubPts[b.name] ?? 0).compareTo(gs.clubPts[a.name] ?? 0));
    return [
      for (var i = 0; i < all.length && i < 100; i++)
        _row(i + 1, teamBadge(all[i], size: 30), all[i] == gs.user && _me != null ? _me! : all[i].coachName, '${all[i].name} • ${all[i].won} فوز • ${all[i].drawn} تعادل • ${all[i].lost} خسارة', Text((gs.clubPts[all[i].name] ?? 0).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)), me: all[i] == gs.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tab) { 0 => _clubs(), 1 => _countries(), 2 => _players(), _ => _coaches() };
    return Scaffold(
      appBar: AppBar(title: const Text('الترتيب العالمي')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: 0, label: Text('الأندية', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 1, label: Text('المنتخبات', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 2, label: Text('اللاعبون', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 3, label: Text('المدربون', style: TextStyle(fontSize: 12))),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
          const SizedBox(height: 12),
          ...body,
        ]),
      ),
    );
  }
}
