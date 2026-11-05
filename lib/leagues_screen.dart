import 'dart:math';
import 'package:flutter/material.dart';
import 'api_football.dart';
import 'bundled.dart';
import 'data_screen.dart';
import 'importer.dart';
import 'league_store.dart';
import 'models.dart';
import 'pack_service.dart';
import 'widgets.dart';

/// الدوريات الحقيقية المضمّنة في اللعبة؛ الصور تُنزَّل اختيارياً (مثل Super Kickoff)
class LeaguesScreen extends StatefulWidget {
  final StartReal onStart;
  const LeaguesScreen({super.key, required this.onStart});
  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<LeagueData>? leagues;
  final Map<String, PackInfo> packs = {};
  final Set<String> withImages = {};
  bool manifestFailed = false;
  bool busy = false;
  String? downloading;
  double progress = 0;
  String? error;

  String _k(LeagueData d) => '${d.id}_${d.season}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  Future<void> _init() async {
    final l = await Bundled.list();
    final h = <String>{};
    for (final d in l) {
      if (await LeagueStore.load(d.id, d.season) != null) h.add(_k(d));
    }
    _set(() {
      leagues = l;
      withImages
        ..clear()
        ..addAll(h);
    });
    try {
      final m = await PackService.manifest(await PackService.getBase());
      _set(() {
        for (final p in m) {
          packs['${p.id}_${p.season}'] = p;
        }
      });
    } catch (_) {
      _set(() => manifestFailed = true);
    }
  }

  LeagueData? _last;

  Future<void> _downloadImages(LeagueData d) async {
    _last = d;
    final p = packs[_k(d)];
    if (p == null) {
      _set(() => error = 'تنزيل الصور غير متاح لهذا الدوري حالياً، حاول لاحقاً.');
      return;
    }
    _set(() {
      busy = true;
      downloading = _k(d);
      progress = 0;
      error = null;
    });
    try {
      await PackService.download(await PackService.getBase(), p, (v) => _set(() => progress = v));
      _set(() => withImages.add(_k(d)));
    } on ApiException catch (e) {
      _set(() => error = e.message);
    } catch (_) {
      _set(() => error = 'فشل تنزيل الصور. تحقق من الإنترنت وحاول مجدداً.');
    } finally {
      _set(() {
        busy = false;
        downloading = null;
      });
    }
  }

  Future<void> _downloadAll() async {
    for (final d in leagues ?? const <LeagueData>[]) {
      if (!withImages.contains(_k(d)) && packs.containsKey(_k(d))) {
        await _downloadImages(d);
        if (error != null) break;
      }
    }
  }

  Future<void> _pick(LeagueData d) async {
    final local = await LeagueStore.load(d.id, d.season);
    final data = local ?? d;
    if (!mounted) return;
    final rng = Random();
    final teams = teamsFromLeague(data, rng);
    final same = (leagues ?? const <LeagueData>[]).where((x) => x.country == d.country && x.teams.length >= 8).toList();
    LeagueData? near(int dv) {
      final c = same.where((x) => x.div == dv).toList();
      return c.isEmpty ? null : c.first;
    }

    Future<List<Team>> load(LeagueData x) async => teamsFromLeague(await LeagueStore.load(x.id, x.season) ?? x, rng);
    final up = near(d.div - 1), lo = near(d.div + 1);
    final pyramid = Pyramid(
      div: d.div,
      upper: up == null ? const [] : await load(up),
      upperName: up?.name ?? '',
      lower: lo == null ? const [] : await load(lo),
      lowerName: lo?.name ?? '',
    );
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClubPickerScreen(teams: teams, leagueName: data.name, onStart: widget.onStart, pyramid: pyramid),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = leagues;
    final missing = l?.where((d) => !withImages.contains(_k(d)) && packs.containsKey(_k(d))).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('⚽ اختر الدوري'), backgroundColor: kBg),
      body: SafeArea(
        child: l == null
            ? ListView(padding: const EdgeInsets.all(14), children: [
                for (var i = 0; i < 7; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 64)),
              ])
            : ListView(padding: const EdgeInsets.all(14), children: [
                const Panel(
                  child: Text(
                    'الأندية واللاعبون الحقيقيون جاهزون للعب فوراً بدون إنترنت. '
                    'يمكنك اختيارياً تنزيل الصور (شعارات الأندية وصور اللاعبين) لكل دوري.',
                    style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.5),
                  ),
                ),
                if (error != null)
                  Panel(
                    color: const Color(0xFF2A1414),
                    child: Column(children: [
                      Text(error!, style: const TextStyle(color: Color(0xFFFF8A65))),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _last == null ? () => _set(() => error = null) : () => _downloadImages(_last!),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ]),
                  ),
                if (l.isEmpty)
                  const Panel(child: Text('لا توجد دوريات في هذه النسخة بعد. حدّث التطبيق لاحقاً.', style: TextStyle(color: kMuted))),
                if (missing > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledButton.tonalIcon(
                      onPressed: busy ? null : _downloadAll,
                      icon: const Icon(Icons.download),
                      label: Text('تنزيل صور كل الدوريات ($missing)'),
                    ),
                  ),
                for (final d in _ordered(l)) ...[
                  if (_firstOfCountry(l, d)) sectionTitle(d.country),
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(8)),
                          child: Text(_divLabel(d.div), style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text('${d.teams.length} فريقاً • ${d.playerCount} لاعباً',
                          style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      if (downloading == _k(d))
                        Column(children: [
                          LinearProgressIndicator(value: progress == 0 ? null : progress, color: kAccent, backgroundColor: kCard2),
                          const SizedBox(height: 4),
                          Text('تنزيل الصور ${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, color: kMuted)),
                        ])
                      else
                        Row(children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : () => _pick(d),
                              child: const Text('اختر فريقك'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (withImages.contains(_k(d)))
                            const Chip(label: Text('✅ الصور'), visualDensity: VisualDensity.compact)
                          else
                            OutlinedButton.icon(
                              onPressed: busy || (manifestFailed && !packs.containsKey(_k(d))) ? null : () => _downloadImages(d),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: Text(packs[_k(d)] != null ? 'الصور ${packs[_k(d)]!.sizeLabel}' : 'تنزيل الصور'),
                            ),
                        ]),
                    ]),
                  ),
                ],
              ]),
      ),
    );
  }

  static String _divLabel(int d) => d == 1 ? 'الدرجة الأولى' : (d == 2 ? 'الدرجة الثانية' : 'الدرجة الثالثة');

  /// ترتيب: الدولة الأقوى أولاً ثم الدرجات
  List<LeagueData> _ordered(List<LeagueData> l) {
    final best = <String, int>{};
    for (final d in l) {
      final t = d.tier;
      if (!best.containsKey(d.country) || t < best[d.country]!) best[d.country] = t;
    }
    return [...l]..sort((a, b) {
        final c = best[a.country]!.compareTo(best[b.country]!);
        if (c != 0) return c;
        final n = a.country.compareTo(b.country);
        return n != 0 ? n : a.div.compareTo(b.div);
      });
  }

  bool _firstOfCountry(List<LeagueData> l, LeagueData d) {
    final o = _ordered(l);
    final i = o.indexOf(d);
    return i == 0 || o[i - 1].country != d.country;
  }
}
