import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'lineup_pages.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'game_state.dart';
import 'models.dart';
import 'settings.dart';
import 'pitch_view.dart';
import 'tactics.dart';
import 'widgets.dart';
import 'last_match.dart';
import 'match_pages.dart';

class MatchScreen extends StatefulWidget {
  final GameState gs;
  const MatchScreen({super.key, required this.gs});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  Timer? _timer;
  Timer? _flashTimer;
  bool running = false;
  int speed = AppSettings.i.speed;
  String? banner;
  String? flash;
  bool halftime = false;
  bool talkDone = false;
  int view = 0; // 0 الملعب، 1 التعليق، 2 الأرقام

  MatchSim get sim => widget.gs.sim!;
  bool get userHome => sim.home.isUser;
  Side get mySide => userHome ? sim.home : sim.away;

  int get _ms => speed == 1 ? 500 : (speed == 2 ? 220 : 90);
  Duration get _anim => Duration(milliseconds: (_ms * 0.9).round());

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    banner = null;
    halftime = false;
    running = true;
    _timer = Timer.periodic(Duration(milliseconds: _ms), (_) => _tick());
    if (mounted) setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    running = false;
  }

  void _showFlash(String text) {
    if (AppSettings.i.haptics) HapticFeedback.heavyImpact();
    if (!AppSettings.i.goalFlash) return;
    flash = text;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => flash = null);
    });
  }

  void _tick() {
    if (sim.finished) {
      _pause();
      if (mounted) setState(() {});
      return;
    }
    final before = sim.events.length;
    sim.step();
    for (final e in sim.events.skip(before)) {
      if (e.type == 'goal') {
        _showFlash(e.text);
        if (e.home == userHome) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
      if (e.home == userHome && (e.type == 'injury' || e.type == 'red')) {
        _pause();
        banner = e.text;
      }
    }
    if (sim.minute == 45) {
      _pause();
      halftime = true;
      talkDone = false;
      banner = 'استراحة بين الشوطين — تحدّث مع اللاعبين وعدّل خطتك ثم تابع';
    }
    if (sim.finished) _pause();
    if (mounted) setState(() {});
  }

  void _tactics() {
    final wasRunning = running;
    _pause();
    setState(() {});
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تعديل التكتيك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            TacticsControls(gs: widget.gs, allowFormation: false),
          ]),
        ),
      ),
    ).then((_) {
      if (wasRunning && !sim.finished) _start();
    });
  }

  void _subs() {
    final wasRunning = running;
    _pause();
    setState(() {});
    final side = mySide;
    Player? sel;
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final bench = side.bench;
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                sel == null ? 'من يخرج؟ (متبقٍ ${side.subsLeft} تبديلات)' : 'من يدخل بدلاً من ${sel!.name}؟',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: sel == null
                  ? ListView(children: [
                      for (final sl in side.slots)
                        ListTile(
                          leading: RatingBadge(sl.p.overall),
                          title: Text(sl.p.name),
                          subtitle: Text('${sl.p.pos.label} • لياقة ${sl.p.fitness.round()}%'),
                          onTap: () => set(() => sel = sl.p),
                        ),
                    ])
                  : bench.isEmpty
                      ? const Center(child: Text('لا يوجد لاعبون على مقاعد البدلاء'))
                      : ListView(children: [
                          for (final b in bench)
                            ListTile(
                              leading: RatingBadge(b.overall),
                              title: Text(b.name),
                              subtitle: Text('${b.pos.label} • لياقة ${b.fitness.round()}%'),
                              onTap: () {
                                final ok = sim.substitute(side, sel!, b);
                                Navigator.pop(ctx);
                                if (!ok) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('لا يمكن إجراء التبديل')));
                                }
                              },
                            ),
                        ]),
            ),
          ]),
        );
      }),
    ).then((_) {
      if (mounted) setState(() {});
      if (wasRunning && !sim.finished) _start();
    });
  }

  Widget _statRow(String label, num h, num a) {
    final total = (h + a) == 0 ? 1 : (h + a);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 30, child: Text('$h', style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(
          child: Column(children: [
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: h / total,
                minHeight: 6,
                color: teamColor(sim.home.team.id),
                backgroundColor: teamColor(sim.away.team.id),
              ),
            ),
          ]),
        ),
        SizedBox(width: 30, child: Text('$a', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _scoreboard() {
    final s = sim;
    final gs = widget.gs;
    final venue = s.home.team.venue ?? 'ملعب ${s.home.team.name}';
    final att = s.home.team == gs.user ? gs.attendance : ((12000 + 8000 * s.home.team.stadium) * 0.8).round();
    final hp = (s.home.poss + s.away.poss) == 0 ? 50 : (100 * s.home.poss / (s.home.poss + s.away.poss)).round();
    Widget side(Team t) => Expanded(
          child: Column(children: [
            teamBadge(t, size: 52),
            const SizedBox(height: 6),
            Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ]),
        );
    return Column(children: [
      Unfilter(
        child: Container(
          color: kNavy,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(children: [
            const Expanded(child: Text('المباراة المباشرة', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
            budgetPill(widget.gs),
          ]),
        ),
      ),
      Container(
        color: kCard,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('$venue • ${att.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} متفرج', style: const TextStyle(color: kMuted, fontSize: 12))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: s.finished ? kMuted : const Color(0xFFE5533D), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!s.finished) const Icon(Icons.circle, size: 8, color: Colors.white),
                const SizedBox(width: 4),
                Text(s.finished ? 'انتهت' : "مباشر  ${s.minute}'", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            side(s.home.team),
            Text('${s.home.goals} - ${s.away.goals}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
            side(s.away.team),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('$hp%', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
            const Expanded(child: Text('الاستحواذ', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12))),
            Text('${100 - hp}%', style: const TextStyle(color: Color(0xFF2F7BE6), fontWeight: FontWeight.w900, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(children: [
                Expanded(flex: hp.clamp(1, 99).toInt(), child: Container(color: kPrimary)),
                Expanded(flex: (100 - hp).clamp(1, 99).toInt(), child: Container(color: const Color(0xFF2F7BE6))),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _talkPanel() => Panel(
        color: const Color(0xFF1F1B0E),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🗣 حديث الاستراحة', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (talkDone)
            Text(banner ?? '', style: const TextStyle(color: Color(0xFFFFCA28)))
          else
            Wrap(spacing: 8, children: [
              ActionChip(label: const Text('تشجيع'), onPressed: () => _talk(0)),
              ActionChip(label: const Text('تحدٍّ (مخاطرة)'), onPressed: () => _talk(1)),
              ActionChip(label: const Text('تهدئة'), onPressed: () => _talk(2)),
            ]),
        ]),
      );

  void _talk(int k) {
    final msg = sim.teamTalk(mySide, k);
    setState(() {
      talkDone = true;
      banner = msg;
    });
  }

  Widget _pitchArea() {
    return Column(children: [
      if (halftime) Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: _talkPanel())
      else if (banner != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(banner!, style: const TextStyle(color: Color(0xFFFFCA28), fontSize: 13)),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('الملعب', style: TextStyle(fontSize: 12)), icon: Icon(Icons.sports_soccer, size: 16)),
            ButtonSegment(value: 1, label: Text('التعليق', style: TextStyle(fontSize: 12)), icon: Icon(Icons.chat_bubble_outline, size: 16)),
            ButtonSegment(value: 2, label: Text('الأرقام', style: TextStyle(fontSize: 12)), icon: Icon(Icons.bar_chart, size: 16)),
          ],
          selected: {view},
          onSelectionChanged: (v) => setState(() => view = v.first),
        ),
      ),
      if (view == 1)
        Expanded(child: _commentary())
      else if (view == 2)
        Expanded(child: _liveStats())
      else ...[
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(10, 10, 10, 6), children: [
          Stack(alignment: Alignment.center, children: [
            AspectRatio(aspectRatio: 0.86, child: LivePitch(sim: sim, anim: _anim)),
            if (flash != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xDD000000),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAccent, width: 2),
                ),
                child: Text(flash!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 4), child: Text(sim.lastText, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted))),
          const Padding(padding: EdgeInsets.fromLTRB(4, 8, 4, 6), child: Text('أحداث المباراة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          _eventsPanel(),
        ]),
      ),
      ],
    ]);
  }


  Widget _commentary() {
    final list = sim.events.reversed.toList();
    if (list.isEmpty) return const Center(child: Text('لم تبدأ المباراة بعد', style: TextStyle(color: kMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];
        final big = e.major && e.type != 'info';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 40, child: Text("${e.minute}'", style: const TextStyle(color: kMuted))),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: e.type == 'info' ? kMuted : teamColor(e.home ? sim.home.team.id : sim.away.team.id),
              ),
            ),
            Expanded(
              child: Text(e.text,
                  style: TextStyle(
                      fontWeight: big ? FontWeight.w700 : FontWeight.w400,
                      color: big || e.type == 'info' ? null : kMuted)),
            ),
          ]),
        );
      },
    );
  }

  Widget _liveStats() {
    final side = mySide;
    final rows = side.slots.toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      _statsPanel(),
      sectionTitle('لاعبوك الآن'),
      Panel(
        child: Column(children: [
          for (final sl in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 44, child: Text(sl.pos.label, style: const TextStyle(color: kMuted, fontSize: 11))),
                Expanded(child: Text(sl.p.name, overflow: TextOverflow.ellipsis)),
                SizedBox(
                  width: 70,
                  child: LinearProgressIndicator(
                    value: (sl.p.fitness / 100).clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    color: sl.p.fitness < 60 ? const Color(0xFFEF5350) : const Color(0xFF29B6F6),
                    backgroundColor: kLine,
                  ),
                ),
                const SizedBox(width: 10),
                Text((side.ratings[sl.p] ?? 6.0).toStringAsFixed(1),
                    style: TextStyle(fontWeight: FontWeight.w800, color: ratingColor((side.ratings[sl.p] ?? 6.0) * 10 + 15))),
              ]),
            ),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text('الشريط الأزرق = اللياقة، والرقم = تقييم اللاعب في المباراة.', style: TextStyle(color: kMuted, fontSize: 12)),
      ),
    ]);
  }

  Widget _eventsPanel() {
    final s = sim;
    final shown = s.events.where((e) => e.major && e.type != 'info').toList().reversed.toList();
    return Panel(
      child: shown.isEmpty
          ? const Text('لا أحداث بعد', style: TextStyle(color: kMuted))
          : Column(children: [
              for (final e in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 38, child: Text("${e.minute}'", style: const TextStyle(color: kMuted))),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, left: 8),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: teamColor(e.home ? s.home.team.id : s.away.team.id)),
                    ),
                    Expanded(child: Text(e.text)),
                  ]),
                ),
            ]),
    );
  }

  Widget _statsPanel() => Panel(
        child: Column(children: [
          _statRow('الاستحواذ %', sim.homePoss, sim.awayPoss),
          _statRow('التسديدات', sim.home.shots, sim.away.shots),
          _statRow('على المرمى', sim.home.onTarget, sim.away.onTarget),
          _statRow('الركنيات', sim.home.corners, sim.away.corners),
          _statRow('الأخطاء', sim.home.fouls, sim.away.fouls),
        ]),
      );

  void _infoSheet() {
    final wasRunning = running;
    _pause();
    setState(() {});
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: ListView(padding: const EdgeInsets.all(14), children: [_statsPanel(), sectionTitle('أحداث المباراة'), _eventsPanel()]),
      ),
    ).then((_) {
      if (wasRunning && !sim.finished) _start();
    });
  }


  Widget _report() {
    final s = sim;
    final me = mySide;
    final op = identical(me, s.home) ? s.away : s.home;
    final diff = me.goals - op.goals;
    final head = diff > 0
        ? (diff >= 3 ? 'فوز كاسح ${me.goals}-${op.goals} 🔥' : 'فوز ${me.goals}-${op.goals} ✅')
        : diff < 0
            ? (diff <= -3 ? 'خسارة قاسية ${me.goals}-${op.goals} 😞' : 'خسارة ${me.goals}-${op.goals}')
            : 'تعادل ${me.goals}-${op.goals}';
    final myPoss = identical(me, s.home) ? s.homePoss : s.awayPoss;
    final lines = <String>[];
    if (myPoss >= 58) {
      lines.add('سيطرت على الكرة بنسبة $myPoss% وفرضت إيقاعك.');
    } else if (myPoss <= 42) {
      lines.add('تركت الكرة للخصم (${100 - myPoss}%) واعتمدت على التنظيم.');
    } else {
      lines.add('مباراة متكافئة في الاستحواذ ($myPoss%).');
    }
    if (me.shots > op.shots + 4) {
      lines.add('هجومك كان الأخطر: ${me.shots} تسديدة مقابل ${op.shots}.');
    } else if (op.shots > me.shots + 4) {
      lines.add('عانى دفاعك: واجه ${op.shots} تسديدة مقابل ${me.shots} فقط.');
    }
    if (diff < 0 && me.shots > op.shots) {
      lines.add('خسرت رغم الأفضلية — حارس الخصم أو نقص الفعالية أمام المرمى.');
    } else if (diff > 0 && op.shots > me.shots) {
      lines.add('فزت بفضل الفعالية، لكن عليك تحصين الدفاع.');
    }
    final reds = s.events.where((e) => e.type == 'red').length;
    final inj = s.events.where((e) => e.type == 'injury' && e.home == identical(me, s.home)).length;
    if (reds > 0) lines.add('شهدت المباراة $reds بطاقة حمراء.');
    if (inj > 0) lines.add('خسرت ${inj == 1 ? 'لاعباً' : '$inj لاعبين'} بسبب الإصابة.');
    final goals = s.events.where((e) => e.type == 'goal').toList();
    final tired = me.slots.where((x) => x.p.fitness < 55).map((x) => x.p.name).toList();
    if (tired.isNotEmpty) lines.add('منهكون: ${tired.take(3).join('، ')} — فكّر في إراحتهم.');
    final mine = me.ratings.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تقرير المباراة', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(head, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final l in lines) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $l', style: const TextStyle(height: 1.4))),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final g in goals)
            Text("${g.minute}'  ${g.text.replaceAll('⚽ ', '').replaceAll('هدف! ', '')}", style: const TextStyle(color: kMuted, fontSize: 13)),
        ],
        if (mine.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('تقييم لاعبيك', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final r in mine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kLine)),
                child: Text('${r.key.name.split(' ').last} ${r.value.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ratingColor(r.value * 10 + 15))),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _summary() {
    final s = sim;
    final mom = s.manOfMatch;
    final all = <(Player, Side, double)>[];
    for (final side in [s.home, s.away]) {
      side.ratings.forEach((p, r) => all.add((p, side, r)));
    }
    all.sort((a, b) => b.$3.compareTo(a.$3));
    return ListView(padding: const EdgeInsets.all(14), children: [
      _report(),
      _statsPanel(),
      if (mom != null)
        Panel(
          child: Row(children: [
            const Text('⭐', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رجل المباراة', style: TextStyle(color: kMuted, fontSize: 12)),
                Text('${mom.$1.name} • ${mom.$2.team.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
            Text(mom.$3.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kAccent)),
          ]),
        ),
      sectionTitle('أفضل التقييمات'),
      Panel(
        child: Column(children: [
          for (final r in all.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                CircleAvatar(radius: 6, backgroundColor: teamColor(r.$2.team.id)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.$1.name)),
                Text(r.$3.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w800, color: ratingColor(r.$3 * 10 + 15))),
              ]),
            ),
        ]),
      ),
      sectionTitle('أحداث المباراة'),
      _eventsPanel(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = sim;
    if (s.finished) {
      final cup = widget.gs.activeCup;
      final lm = LastMatch.fromSim(s, comp: cup?.name ?? widget.gs.leagueName, round: widget.gs.week + 1, label: cup?.roundName ?? 'الجولة ${widget.gs.week + 1}', userHome: s.home.team == widget.gs.user);
      return PopScope(
        canPop: false,
        child: MatchSummaryScreen(
          gs: widget.gs,
          m: lm,
          onContinue: () {
            widget.gs.finishCurrent();
            Navigator.pop(context);
          },
        ),
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _scoreboard(),
            Expanded(child: s.finished ? _summary() : _pitchArea()),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kLine))),
              child: s.finished
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          widget.gs.finishCurrent();
                          Navigator.pop(context);
                        },
                        child: const Text('متابعة'),
                      ),
                    )
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(border: Border.all(color: kLine), borderRadius: BorderRadius.circular(10)),
                        clipBehavior: Clip.antiAlias,
                        child: Row(children: [
                          for (final x in const [1, 2, 4])
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  speed = x;
                                  if (running) {
                                    _start();
                                  } else {
                                    setState(() {});
                                  }
                                },
                                child: Unfilter(child: Container(alignment: Alignment.center, color: speed == x ? kNavy : Colors.transparent, child: Text('×$x', style: TextStyle(fontWeight: FontWeight.w900, color: speed == x ? Colors.white : kMuted)))),
                              ),
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _pause();
                                sim.simulateAll();
                                setState(() {});
                              },
                              child: Container(alignment: Alignment.center, child: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted))),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: whiteBtn(running ? 'إيقاف' : 'استئناف', () => setState(running ? _pause : _start), icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: blueBtn('التكتيك', _tactics, icon: Icons.account_tree_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: GradientButton(label: 'تبديل', icon: Icons.swap_horiz_rounded, onPressed: _subs)),
                      ]),
                    ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// يبدأ مباراة الجولة الحالية ويفتح شاشة المباراة
Future<void> playMatch(BuildContext context, GameState gs) async {
  final c = gs.pendingCup;
  if (c != null) {
    gs.startCupMatch(c);
  } else {
    gs.startMatch();
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchScreen(gs: gs)));
}
