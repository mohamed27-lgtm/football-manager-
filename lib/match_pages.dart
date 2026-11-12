import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'activity_screen.dart';
import 'countries.dart';
import 'game_state.dart';
import 'calendar.dart';
import 'i18n.dart';
import 'lineup_pages.dart';
import 'last_match.dart';
import 'match_screen.dart';
import 'models.dart';
import 'tactics.dart';
import 'widgets.dart';

const _teal = Color(0xFF1FA58A);
const _orange = Color(0xFFF0583A);
const _blue = Color(0xFF2F7BE6);
const _purple = Color(0xFF6A6FC4);

/// شريط علوي موحّد: عودة + عنوان + الميزانية + الرسائل
PreferredSizeWidget gameBar(BuildContext context, GameState gs, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      budgetPill(gs),
      mailButton(context, gs),
    ],
  );
}

Widget budgetPill(GameState gs) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const Icon(Icons.circle, size: 11, color: Color(0xFFFFC857)),
        const SizedBox(width: 7),
        Text(money(gs.user.budget), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      ]),
    );

Widget mailButton(BuildContext context, GameState gs) {
  final n = gs.tasks.length;
  return IconButton(
    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityScreen(gs: gs, onOpen: (_) => Navigator.of(context).pop()))),
    icon: Badge(
      isLabelVisible: n > 0,
      backgroundColor: _orange,
      label: Text('$n'),
      child: const Icon(Icons.mail_outline_rounded, color: Colors.white),
    ),
  );
}

/// نقاط النتائج الأخيرة: ف فوز، ت تعادل، خ خسارة
Widget formChips(List<String> form, {double size = 26}) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (final r in form)
        Container(
          width: size,
          height: size,
          margin: const EdgeInsetsDirectional.only(end: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: r == 'W' ? _teal : (r == 'L' ? const Color(0xFFE5533D) : const Color(0xFF9AA3B2)), borderRadius: BorderRadius.circular(7)),
          child: Text(r == 'W' ? 'ف' : (r == 'L' ? 'خ' : 'ت'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.5)),
        ),
    ]);

Widget bottomActions(Widget left, Widget right) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [Expanded(flex: 2, child: left), const SizedBox(width: 12), Expanded(flex: 5, child: right)]),
      ),
    );

Widget whiteBtn(String label, VoidCallback on, {IconData? icon}) => GestureDetector(
      onTap: on,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 2))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 22)],
        ]),
      ),
    );

// ───────────────────────── ملخص المباراة ─────────────────────────

class MatchSummaryScreen extends StatefulWidget {
  final GameState gs;
  final LastMatch m;
  final VoidCallback onContinue;
  final int initialTab;
  const MatchSummaryScreen({super.key, required this.gs, required this.m, required this.onContinue, this.initialTab = 0});
  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  late int tab = widget.initialTab;
  LastMatch get m => widget.m;
  GameState get gs => widget.gs;

  Team? _t(int id) {
    try {
      return gs.team(id);
    } catch (_) {
      return null;
    }
  }

  Widget _head() {
    final h = _t(m.homeId), a = _t(m.awayId);
    Widget side(Team? t, String name) => Expanded(
          flex: 3,
          child: Column(children: [
            if (t != null) teamBadge(t, size: 62) else const SizedBox(height: 62),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
        );
    return Unfilter(
      child: Container(
        color: const Color(0xFF15233D),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(children: [
          Row(children: [
            Text('${m.label.isEmpty ? 'الجولة ${m.round}' : m.label} • ${m.comp}', style: const TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: _teal.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
              child: const Text('نهاية المباراة', style: TextStyle(color: Color(0xFF7FE0C8), fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            side(h, m.homeName),
            Expanded(flex: 3, child: Text('${m.hg} - ${m.ag}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900))),
            side(a, m.awayName),
          ]),
        ]),
      ),
    );
  }

  Widget _evSide(Map<String, dynamic> e, bool userSide) {
    final t = e['t'] as String;
    Widget icon;
    String title = e['a'] as String;
    String? sub;
    if (t == 'goal') {
      icon = Container(width: 60, height: 60, decoration: BoxDecoration(color: userSide ? _teal : const Color(0xFF8A94A6), shape: BoxShape.circle), child: const Icon(Icons.sports_soccer_rounded, color: Colors.white));
      sub = userSide && e['b'] != null ? 'صناعة: ${e['b']}' : '${e['s']}';
      if (userSide) sub = e['b'] != null ? 'صناعة: ${e['b']}' : '${e['s']}';
    } else if (t == 'yellow') {
      icon = Container(width: 60, height: 60, alignment: Alignment.center, child: Container(width: 26, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFC400), borderRadius: BorderRadius.circular(4))));
      sub = 'بطاقة صفراء';
    } else if (t == 'red') {
      icon = Container(width: 60, height: 60, alignment: Alignment.center, child: Container(width: 26, height: 36, decoration: BoxDecoration(color: const Color(0xFFE5533D), borderRadius: BorderRadius.circular(4))));
      sub = 'بطاقة حمراء';
    } else {
      icon = Container(width: 60, height: 60, decoration: const BoxDecoration(color: Color(0xFFD2E6FA), shape: BoxShape.circle), child: const Icon(Icons.swap_vert_rounded, color: _blue));
      title = 'دخل ${e['a']}';
      sub = 'خرج ${e['b']}';
    }
    final text = Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
        if (sub != null) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
      ]),
    );
    return Row(children: [icon, const SizedBox(width: 6), text]);
  }

  Widget _summaryTab() {
    final evs = m.events.where((e) => e['t'] != 'sub' || true).toList();
    final mom = m.mom;
    Player? momP;
    if (mom != null) {
      for (final t in gs.teams) {
        for (final p in t.squad) {
          if (p.id == mom['id']) momP = p;
        }
      }
    }
    return Column(children: [
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          if (evs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا أحداث مسجلة', style: TextStyle(color: kMuted))),
          for (final e in evs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [
                Expanded(child: (e['h'] as bool) ? _evSide(e, m.userHome) : const SizedBox()),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(12)),
                  child: Text("${e['m']}'", style: const TextStyle(fontWeight: FontWeight.w800, color: kMuted)),
                ),
                Expanded(child: !(e['h'] as bool) ? _evSide(e, !m.userHome) : const SizedBox()),
              ]),
            ),
        ]),
      ),
      if (mom != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Row(children: [
            if (momP != null)
              playerFace(momP, 72, ring: kGold, ringWidth: 2.5)
            else
              Container(width: 70, height: 70, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle), child: const Icon(Icons.person, size: 40, color: kMuted)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رجل المباراة', style: TextStyle(color: kMuted, fontSize: 13)),
                Row(children: [
                  Flexible(child: Text(mom['n'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19))),
                  if (countryByName(mom['nat'] as String?) != null) ...[const SizedBox(width: 8), FlagRect(countryByName(mom['nat'] as String?)!.iso, w: 30)],
                ]),
                Text([if ((mom['g'] as int) > 0) 'هدف${(mom['g'] as int) > 1 ? ' × ${mom['g']}' : ''}', if ((mom['a'] as int) > 0) 'تمريرة حاسمة', if ((mom['g'] as int) == 0 && (mom['a'] as int) == 0) 'أداء مميز'].join(' • '), style: const TextStyle(color: kMuted, fontSize: 13)),
              ]),
            ),
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _teal, shape: BoxShape.circle, border: Border.all(color: _teal.withOpacity(0.25), width: 5)),
              child: Text(((mom['r'] as num) * 10).round().toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _statRow(String label, num h, num a, {bool pct = false, bool lowerBetter = false}) {
    final mx = (h > a ? h : a).toDouble();
    final hv = mx == 0 ? 0.0 : h / mx, av = mx == 0 ? 0.0 : a / mx;
    final hBetter = lowerBetter ? h <= a : h >= a;
    final aBetter = lowerBetter ? a <= h : a >= h;
    String f(num v) => pct ? '${v.round()}%' : '${v is double && v != v.roundToDouble() ? v : v.round()}';
    Widget bar(double v, bool better, Color c, bool right) => Expanded(
          child: Align(
            alignment: right ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v.clamp(0.04, 1),
              child: Container(height: 10, decoration: BoxDecoration(color: better ? c : c.withOpacity(0.4), borderRadius: BorderRadius.circular(6))),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(children: [
        Text(label, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(children: [
          SizedBox(width: 48, child: Text(f(h), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: hBetter ? null : kMuted))),
          // الجانب الأيمن للمضيف (RTL): أول عنصر في الصف هو اليمين
          Expanded(
            child: Row(children: [
              bar(hv, hBetter, _orange, false),
              const SizedBox(width: 6),
              bar(av, aBetter, _blue, true),
            ]),
          ),
          SizedBox(width: 48, child: Text(f(a), textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: aBetter ? null : kMuted))),
        ]),
      ]),
    );
  }

  Widget _statsTab() {
    final s = m.stats;
    num h(String k) => s[k]![0];
    num a(String k) => s[k]![1];
    return Column(children: [
      Container(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Text(m.homeName, style: const TextStyle(color: _orange, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(m.awayName, style: const TextStyle(color: _blue, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 8),
          _statRow('الاستحواذ', h('poss'), a('poss'), pct: true),
          _statRow('التسديدات', h('shots'), a('shots')),
          _statRow('على المرمى', h('target'), a('target')),
          _statRow('التمريرات', h('passes'), a('passes')),
          _statRow('دقة التمرير', h('acc'), a('acc'), pct: true),
          _statRow('الركنيات', h('corners'), a('corners')),
          _statRow('الأخطاء', h('fouls'), a('fouls'), lowerBetter: true),
          _statRow('التسلل', h('offside'), a('offside'), lowerBetter: true),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Row(children: [
          Expanded(child: Column(children: [Text('${h('xg')}', style: const TextStyle(color: _orange, fontSize: 26, fontWeight: FontWeight.w900)), const Text('الأهداف المتوقعة xG', style: TextStyle(color: kMuted, fontSize: 13))])),
          Container(width: 1, height: 44, color: kLine),
          Expanded(child: Column(children: [Text('${a('xg')}', style: const TextStyle(color: _blue, fontSize: 26, fontWeight: FontWeight.w900)), const Text('المنافس xG', style: TextStyle(color: kMuted, fontSize: 13))])),
        ]),
      ),
    ]);
  }

  Widget _ratingsTab() {
    Widget list(String title, bool home) {
      final l = m.ratings.where((r) => r['h'] == home).toList();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(12), color: kCard2, child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: home ? _orange : _blue))),
          for (final r in l)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [
                Expanded(child: Text(r['n'] as String, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(Pos.values[r['p'] as int].label, style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(width: 12),
                Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ratingColor((r['r'] as num) * 10 + 15).withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text((r['r'] as num).toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w900, color: ratingColor((r['r'] as num) * 10 + 15))),
                ),
              ]),
            ),
        ]),
      );
    }

    return Column(children: [list(m.homeName, true), list(m.awayName, false)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'ملخص المباراة'),
      body: Column(children: [
        _head(),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 0, label: Text('الملخص')),
                ButtonSegment(value: 1, label: Text('الإحصائيات')),
                ButtonSegment(value: 2, label: Text('التقييمات')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 14),
            if (tab == 0) _summaryTab(),
            if (tab == 1) _statsTab(),
            if (tab == 2) _ratingsTab(),
          ]),
        ),
        bottomActions(
          whiteBtn('مشاركة', () {
            Clipboard.setData(ClipboardData(text: '${m.homeName} ${m.hg} - ${m.ag} ${m.awayName} • ${m.comp} • الجولة ${m.round}'));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النتيجة')));
          }),
          GradientButton(label: 'متابعة', icon: Icons.check_rounded, onPressed: widget.onContinue),
        ),
      ]),
    );
  }
}

// ───────────────────────── المباراة القادمة ─────────────────────────

class NextMatchScreen extends StatelessWidget {
  final GameState gs;
  const NextMatchScreen({super.key, required this.gs});

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _title(String t, {String? side}) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Spacer(), if (side != null) Text(side, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800))]),
      );

  Widget _cmp(String l, Widget a, Widget b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [Expanded(child: Align(alignment: Alignment.centerRight, child: a)), Text(l, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)), Expanded(child: Align(alignment: Alignment.centerLeft, child: b))]),
      );

  @override
  Widget build(BuildContext context) {
    final nm = gs.nextMatch;
    if (nm == null) {
      return Scaffold(appBar: gameBar(context, gs, 'المباراة القادمة'), body: const EmptyState(icon: Icons.event_busy_rounded, title: 'لا مباراة قادمة', subtitle: 'انتهى الموسم.'));
    }
    final u = gs.user;
    final home = nm.home, away = nm.away;
    final opp = home.id == u.id ? away : home;
    final oppRank = gs.table.indexOf(opp) + 1;
    final myForm = gs.formOf(u), oppForm = gs.formOf(opp);
    final key = ([...opp.squad]..sort((a, b) => b.overall.compareTo(a.overall))).take(3).toList();
    final h2h = gs.h2h[opp.id] ?? const <String>[];
    final w = h2h.where((r) => r == 'W').length, d = h2h.where((r) => r == 'D').length, l = h2h.where((r) => r == 'L').length;
    final out = [...u.squad.where((p) => p.injuredWeeks > 0 || p.suspendedMatches > 0)];
    final nTxt = (int v) => '$v';
    return Scaffold(
      appBar: gameBar(context, gs, 'المباراة القادمة'),
      body: Column(children: [
        Unfilter(
          child: Container(
            color: const Color(0xFF15233D),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(children: [
              Row(children: [
                Flexible(child: Text('${nm.round} • ${nm.comp}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w700))),
                const Spacer(),
                Text(home.venue ?? 'ملعب ${home.name}', style: const TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(flex: 3, child: Column(children: [teamBadge(home, size: 64), const SizedBox(height: 8), Text(home.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))])),
                Expanded(
                  flex: 2,
                  child: Column(children: [
                    const Text('VS', style: TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w900)),
                    Text(GameCalendar.dayNames[nm.date.weekday - 1], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(GameCalendar.fmtShort(nm.date), style: const TextStyle(color: Color(0xFFC9D6EC), fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(nm.time, style: const TextStyle(color: Color(0xFFFFC857), fontSize: 18, fontWeight: FontWeight.w900)),
                  ]),
                ),
                Expanded(flex: 3, child: Column(children: [teamBadge(away, size: 64), const SizedBox(height: 8), Text(away.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))])),
              ]),
            ]),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _title('مقارنة الفريقين'),
            _card(Column(children: [
              _cmp('المركز', Text('${gs.position}', style: const TextStyle(color: _orange, fontWeight: FontWeight.w900, fontSize: 17)), Text(oppRank == 0 ? '—' : '$oppRank', style: const TextStyle(color: _purple, fontWeight: FontWeight.w900, fontSize: 17))),
              _cmp('قوة الفريق', Text(nTxt(u.strength.round()), style: const TextStyle(color: _orange, fontWeight: FontWeight.w900, fontSize: 17)), Text(nTxt(opp.strength.round()), style: const TextStyle(color: _purple, fontWeight: FontWeight.w900, fontSize: 17))),
              _cmp('آخر ٥ مباريات', myForm.isEmpty ? const Text('—') : formChips(myForm), oppForm.isEmpty ? const Text('—') : formChips(oppForm)),
            ])),
            _title('أبرز لاعبي الخصم'),
            Row(children: [
              for (final p in key)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                    child: Column(children: [
                      playerFace(p, 58, ring: _purple, ringWidth: 2),
                      const SizedBox(height: 6),
                      Text(p.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      ratingRing(p.overall, size: 44),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            _title('المواجهات المباشرة', side: h2h.isEmpty ? null : 'آخر ${h2h.length}'),
            _card(Padding(
              padding: const EdgeInsets.all(14),
              child: h2h.isEmpty
                  ? const Text('لا مواجهات سابقة مسجلة بعد.', style: TextStyle(color: kMuted))
                  : Row(children: [
                      Expanded(
                        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                          const Text('فوز ', style: TextStyle(color: kMuted)),
                          Text('$w', style: const TextStyle(color: _teal, fontWeight: FontWeight.w900)),
                          const Text('  •  تعادل ', style: TextStyle(color: kMuted)),
                          Text('$d', style: const TextStyle(fontWeight: FontWeight.w900)),
                          const Text('  •  خسارة ', style: TextStyle(color: kMuted)),
                          Text('$l', style: const TextStyle(color: Color(0xFFE5533D), fontWeight: FontWeight.w900)),
                        ]),
                      ),
                      formChips(h2h.length > 5 ? h2h.sublist(h2h.length - 5) : h2h, size: 30),
                    ]),
            )),
            _title('الغيابات', side: '${out.length}'),
            _card(out.isEmpty
                ? const Padding(padding: EdgeInsets.all(14), child: Text('لا غيابات — التشكيلة كاملة.', style: TextStyle(color: kMuted)))
                : Column(children: [
                    for (final p in out)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
                        child: Row(children: [
                          Stack(clipBehavior: Clip.none, children: [
                            playerFace(p, 44, ring: const Color(0xFFE5533D), ringWidth: 2),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: const Color(0xFFE5533D), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                child: p.injuredWeeks > 0 ? const Icon(Icons.add, color: Colors.white, size: 12) : Container(width: 7, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5))),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                          Text(p.injuredWeeks > 0 ? 'إصابة • ${p.injuredWeeks} أسابيع' : 'إيقاف • ${p.suspendedMatches} مباراة', style: const TextStyle(color: kMuted)),
                        ]),
                      ),
                  ])),
          ]),
        ),
        bottomActions(
          whiteBtn('التشكيلة', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LineupScreen(gs: gs))), icon: Icons.groups_2_outlined),
          GradientButton(label: 'ابدأ المباراة', icon: Icons.sports_soccer_rounded, onPressed: gs.fired ? null : () => playMatch(context, gs)),
        ),
      ]),
    );
  }
}
