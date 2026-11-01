import 'dart:math';
import 'package:flutter/material.dart';
import 'api_football.dart';
import 'bundled.dart';
import 'data_screen.dart';
import 'importer.dart';
import 'league_store.dart';
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

  Future<void> _downloadImages(LeagueData d) async {
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
    final teams = teamsFromLeague(data, Random());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClubPickerScreen(teams: teams, leagueName: data.name, onStart: widget.onStart),
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
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(14), children: [
                const Panel(
                  child: Text(
                    'الأندية واللاعبون الحقيقيون جاهزون للعب فوراً بدون إنترنت. '
                    'يمكنك اختيارياً تنزيل الصور (شعارات الأندية وصور اللاعبين) لكل دوري.',
                    style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.5),
                  ),
                ),
                if (error != null)
                  Panel(color: const Color(0xFF2A1414), child: Text(error!, style: const TextStyle(color: Color(0xFFFF8A65)))),
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
                for (final d in l)
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${d.country} • ${d.teams.length} فريقاً • ${d.playerCount} لاعباً',
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
              ]),
      ),
    );
  }
}
