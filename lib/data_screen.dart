import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'api_football.dart';
import 'importer.dart';
import 'league_store.dart';
import 'models.dart';
import 'widgets.dart';

typedef StartReal = void Function(List<Team> teams, int userId, String leagueName, {Pyramid? pyramid});

class DataScreen extends StatefulWidget {
  final StartReal onStart;
  const DataScreen({super.key, required this.onStart});
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _keyCtl = TextEditingController();
  int season = 2023;
  Map<int, LeagueData?> data = {};
  bool busy = false;
  bool cancel = false;
  String status = '';
  double progress = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  Future<void> _init() async {
    _keyCtl.text = await LeagueStore.getKey();
    season = await LeagueStore.getSeason();
    await _reload();
  }

  Future<void> _reload() async {
    final m = <int, LeagueData?>{};
    for (final l in leagueCatalog) {
      m[l.id] = await LeagueStore.load(l.id, season);
    }
    _set(() => data = m);
  }

  Future<void> _sync(LeagueInfo info) async {
    final key = _keyCtl.text.trim();
    if (key.isEmpty) {
      setState(() => error = 'أدخل مفتاح API أولاً');
      return;
    }
    await LeagueStore.setKey(key);
    final api = ApiFootball(key);
    _set(() {
      busy = true;
      cancel = false;
      error = null;
      progress = 0;
      status = 'تجهيز ${info.name}…';
    });
    try {
      var existing = await LeagueStore.load(info.id, season);
      if (existing == null) {
        _set(() => status = 'جلب قائمة الفرق…');
        final teams = await api.teams(info.id, season);
        if (teams.isEmpty) {
          throw ApiException('لا توجد فرق لهذا الموسم. جرّب موسماً آخر.');
        }
        var st = <int, (int, int)>{};
        try {
          _set(() => status = 'جلب ترتيب الدوري…');
          st = await api.standings(info.id, season);
        } on ApiException catch (_) {}
        for (var i = 0; i < teams.length; i++) {
          final r = st[teams[i].id];
          teams[i].rank = r?.$1 ?? (99 + i);
          teams[i].points = r?.$2 ?? 0;
        }
        existing = LeagueData(
          id: info.id,
          name: info.name,
          country: info.country,
          tier: info.tier,
          season: season,
          teams: teams,
          fetchedAt: DateTime.now(),
        );
        await LeagueStore.save(existing);
      }
      final d = existing;
      for (final t in d.teams.where((t) => !t.squadLoaded).toList()) {
        if (cancel) break;
        _set(() {
          status = 'تحميل تشكيلة ${t.name}';
          progress = d.loaded / d.teams.length;
        });
        t.players = await api.squad(t.id);
        t.squadLoaded = true;
        await LeagueStore.save(d);
        final rem = api.dailyRemaining;
        if (rem != null && rem <= 1 && !d.complete) {
          throw ApiException('اقتربت من نهاية الحصة اليومية', quota: true);
        }
      }
      _set(() => progress = d.loaded / d.teams.length);
    } on ApiException catch (e) {
      _set(() => error = e.quota ? '${e.message}\nتم حفظ التقدم — تابع لاحقاً.' : e.message);
    } catch (e) {
      _set(() => error = 'خطأ غير متوقع: $e');
    } finally {
      _set(() => busy = false);
      await _reload();
    }
  }

  Future<void> _delete(LeagueInfo l) async {
    await LeagueStore.delete(l.id, season);
    await _reload();
  }

  void _play(LeagueData d) {
    final teams = teamsFromLeague(d, Random());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClubPickerScreen(teams: teams, leagueName: d.name, onStart: widget.onStart),
    ));
  }

  Widget _leagueTile(LeagueInfo l) {
    final d = data[l.id];
    final st = d == null
        ? 'غير محمّل'
        : d.complete
            ? 'جاهز ✅ • ${d.teams.length} فريقاً • ${d.playerCount} لاعباً'
            : 'محمّل جزئياً ${d.loaded}/${d.teams.length}';
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text('${l.country} • $st', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          if (d != null)
            IconButton(
              onPressed: busy ? null : () => _delete(l),
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: tr('حذف البيانات'),
            ),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: d != null && d.complete
              ? FilledButton(onPressed: busy ? null : () => _play(d), child: const Text('اختر ناديك والعب'))
              : FilledButton.tonal(
                  onPressed: busy ? null : () => _sync(l),
                  child: Text(d == null ? 'تحميل البيانات (~22 طلباً)' : 'متابعة التحميل'),
                ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌍 دوريات حقيقية')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(14), children: [
          const Panel(
            child: Text(
              'أو (متقدم) حمّل مباشرة بمفتاحك الخاص: تُحمَّل البيانات مرة واحدة ثم تُخزَّن على الهاتف وتعمل دون إنترنت.\n'
              '• أنشئ حساباً مجانياً في API-Football (api-football.com) وانسخ المفتاح.\n'
              '• الخطة المجانية: 100 طلب يومياً و10 طلبات في الدقيقة، ودوري من 20 فريقاً يحتاج نحو 22 طلباً (≈ 2.5 دقيقة).\n'
              '• إذا نفدت الحصة يُحفظ التقدم وتكمل في اليوم التالي.\n'
              '• قد تقتصر الخطة المجانية على مواسم قديمة، جرّب 2021–2023 إن ظهر خطأ.',
              style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.5),
            ),
          ),
          TextField(
            controller: _keyCtl,
            enabled: !busy,
            decoration: InputDecoration(labelText: tr('مفتاح API-Football'), border: OutlineInputBorder()),
            onChanged: (v) => LeagueStore.setKey(v.trim()),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Text('الموسم:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: season,
              items: [for (final s in [2021, 2022, 2023, 2024, 2025]) DropdownMenuItem(value: s, child: Text('$s'))],
              onChanged: busy
                  ? null
                  : (v) async {
                      if (v == null) return;
                      await LeagueStore.setSeason(v);
                      _set(() => season = v);
                      await _reload();
                    },
            ),
          ]),
          if (error != null)
            Panel(color: const Color(0xFF2A1414), child: Text(error!, style: const TextStyle(color: Color(0xFFFF8A65)))),
          if (busy)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(status),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress == 0 ? null : progress, color: kAccent, backgroundColor: kCard2),
                const SizedBox(height: 8),
                TextButton(onPressed: () => setState(() => cancel = true), child: const Text('إيقاف (يُحفظ التقدم)')),
              ]),
            ),
          const SizedBox(height: 6),
          for (final l in leagueCatalog) _leagueTile(l),
        ]),
      ),
    );
  }
}

class ClubPickerScreen extends StatefulWidget {
  final List<Team> teams;
  final String leagueName;
  final StartReal onStart;
  final Pyramid? pyramid;
  const ClubPickerScreen({super.key, required this.teams, required this.leagueName, required this.onStart, this.pyramid});
  @override
  State<ClubPickerScreen> createState() => _ClubPickerScreenState();
}

class _ClubPickerScreenState extends State<ClubPickerScreen> {
  String q = '';
  Team? chosen;

  @override
  Widget build(BuildContext context) {
    final shown = widget.teams.where((t) => q.isEmpty || t.name.toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        centerTitle: true,
        actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Center(child: Text('3/3', style: const TextStyle(color: kMuted))))],
        bottom: const WizardBar(3),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), children: [
              const Text('اختر فريقك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => setState(() => q = v.trim()),
                decoration: InputDecoration(
                  hintText: tr('ابحث عن ناد'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: kCard2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 6),
              for (final t in shown)
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => chosen = t),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: chosen?.id == t.id ? const Color(0x221FA58A) : kCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: chosen?.id == t.id ? kAccent : kLine, width: chosen?.id == t.id ? 1.6 : 1),
                    ),
                    child: Row(children: [
                      teamBadge(t, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                          Text('${'★' * t.reputation} • قوة ${t.strength.toStringAsFixed(1)}${t.venue != null ? ' • ${t.venue}' : ''}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      if (chosen?.id == t.id) const Icon(Icons.check_circle, color: kAccent),
                    ]),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: GradientButton(
              label: 'ابدأ اللعبة',
              icon: Icons.sports_soccer,
              onPressed: chosen == null
                  ? null
                  : () {
                      widget.onStart(widget.teams, chosen!.id, widget.leagueName, pyramid: widget.pyramid);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
            ),
          ),
        ]),
      ),
    );
  }
}
