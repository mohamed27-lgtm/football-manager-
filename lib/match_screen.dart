import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'game_state.dart';
import 'models.dart';
import 'pitch_view.dart';
import 'tactics.dart';
import 'widgets.dart';

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
  int speed = 1;
  String? banner;
  String? flash;
  bool halftime = false;
  bool talkDone = false;

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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            teamBadge(s.home.team, size: 22),
            const SizedBox(width: 6),
            Flexible(child: Text(s.home.team.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
        ),
        Column(children: [
          Text('${s.home.goals} - ${s.away.goals}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          Text(s.finished ? 'انتهت' : "${s.minute}'", style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Text(s.away.team.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(width: 6),
            teamBadge(s.away.team, size: 22),
          ]),
        ),
      ]),
    );
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
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(alignment: Alignment.center, children: [
            Center(
              child: AspectRatio(
                aspectRatio: 0.74,
                child: LivePitch(sim: sim, anim: _anim),
              ),
            ),
            if (flash != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xDD000000),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAccent, width: 2),
                ),
                child: Text(flash!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Text(sim.lastText, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted)),
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

  Widget _summary() {
    final s = sim;
    final mom = s.manOfMatch;
    final all = <(Player, Side, double)>[];
    for (final side in [s.home, s.away]) {
      side.ratings.forEach((p, r) => all.add((p, side, r)));
    }
    all.sort((a, b) => b.$3.compareTo(a.$3));
    return ListView(padding: const EdgeInsets.all(14), children: [
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
                          widget.gs.finishMatchday();
                          Navigator.pop(context);
                        },
                        child: const Text('متابعة'),
                      ),
                    )
                  : Row(children: [
                      IconButton.filled(
                        onPressed: running ? () => setState(_pause) : _start,
                        icon: Icon(running ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () {
                          speed = speed == 1 ? 2 : (speed == 2 ? 4 : 1);
                          if (running) {
                            _start();
                          } else {
                            setState(() {});
                          }
                        },
                        child: Text('${speed}x'),
                      ),
                      const Spacer(),
                      IconButton(onPressed: _infoSheet, tooltip: 'الإحصاءات', icon: const Icon(Icons.bar_chart)),
                      IconButton(onPressed: _tactics, tooltip: 'التكتيك', icon: const Icon(Icons.tune)),
                      IconButton(onPressed: _subs, tooltip: 'التبديلات', icon: const Icon(Icons.swap_vert)),
                      IconButton(
                        onPressed: () {
                          _pause();
                          sim.simulateAll();
                          setState(() {});
                        },
                        tooltip: 'إنهاء',
                        icon: const Icon(Icons.fast_forward),
                      ),
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
  gs.startMatch();
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchScreen(gs: gs)));
}
