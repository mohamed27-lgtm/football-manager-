import 'dart:math';
import 'package:flutter/material.dart';
import 'api_football.dart';
import 'data_screen.dart';
import 'importer.dart';
import 'league_store.dart';
import 'pack_service.dart';
import 'widgets.dart';

/// تنزيل حزم الدوريات الجاهزة (بيانات حقيقية + صور) من المستودع
class PacksScreen extends StatefulWidget {
  final StartReal onStart;
  const PacksScreen({super.key, required this.onStart});
  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  final _baseCtl = TextEditingController();
  List<PackInfo>? packs;
  final Set<String> have = {};
  bool loading = false;
  String? error;
  int? downloadingId;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _baseCtl.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  Future<void> _init() async {
    _baseCtl.text = await PackService.getBase();
    await _refresh();
  }

  Future<void> _refresh() async {
    final base = _baseCtl.text.trim();
    if (base.contains('OWNER/REPO')) {
      _set(() => error = 'اضبط رابط المستودع أولاً (https://github.com/اسمك/المستودع/releases/download/data-latest)');
      return;
    }
    await PackService.setBase(base);
    _set(() {
      loading = true;
      error = null;
    });
    try {
      final list = await PackService.manifest(base);
      final h = <String>{};
      for (final p in list) {
        if (await LeagueStore.load(p.id, p.season) != null) h.add('${p.id}_${p.season}');
      }
      _set(() {
        packs = list;
        have
          ..clear()
          ..addAll(h);
      });
    } on ApiException catch (e) {
      _set(() => error = e.message);
    } catch (e) {
      _set(() => error = 'خطأ: $e');
    } finally {
      _set(() => loading = false);
    }
  }

  Future<void> _download(PackInfo p) async {
    _set(() {
      downloadingId = p.id;
      progress = 0;
      error = null;
    });
    try {
      final d = await PackService.download(_baseCtl.text.trim(), p, (v) => _set(() => progress = v));
      _set(() => have.add('${p.id}_${p.season}'));
      if (mounted) _pick(d);
    } on ApiException catch (e) {
      _set(() => error = e.message);
    } catch (e) {
      _set(() => error = 'فشل التنزيل: $e');
    } finally {
      _set(() => downloadingId = null);
    }
  }

  Future<void> _open(PackInfo p) async {
    final d = await LeagueStore.load(p.id, p.season);
    if (d != null && mounted) _pick(d);
  }

  void _pick(LeagueData d) {
    final teams = teamsFromLeague(d, Random());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClubPickerScreen(teams: teams, leagueName: d.name, onStart: widget.onStart),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final busy = downloadingId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('📦 حزم الدوريات'), backgroundColor: kBg),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(14), children: [
          const Panel(
            child: Text(
              'تنزّل كل حزمة مرة واحدة (بيانات الدوري + شعارات الأندية + صور اللاعبين) '
              'فتعمل اللعبة بعدها دون إنترنت. يتحدّث المستودع تلقائياً مع اكتمال الاستيراد.',
              style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.5),
            ),
          ),
          TextField(
            controller: _baseCtl,
            enabled: !busy,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رابط الحزم', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: busy || loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: Text(loading ? 'جارٍ التحديث…' : 'تحديث القائمة'),
          ),
          const SizedBox(height: 10),
          if (error != null)
            Panel(color: const Color(0xFF2A1414), child: Text(error!, style: const TextStyle(color: Color(0xFFFF8A65)))),
          if (packs != null && packs!.isEmpty)
            const Panel(child: Text('لا توجد حزم جاهزة بعد. شغّل workflow الاستيراد في GitHub وانتظر اكتمال أول دوري.', style: TextStyle(color: kMuted))),
          for (final p in packs ?? const <PackInfo>[])
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${p.country} • ${p.teams} فريقاً • ${p.players} لاعباً • ${p.sizeLabel} • موسم ${p.season}',
                    style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 8),
                if (downloadingId == p.id)
                  Column(children: [
                    LinearProgressIndicator(value: progress == 0 ? null : progress, color: kAccent, backgroundColor: kCard2),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ])
                else
                  SizedBox(
                    width: double.infinity,
                    child: have.contains('${p.id}_${p.season}')
                        ? Row(children: [
                            Expanded(child: FilledButton(onPressed: busy ? null : () => _open(p), child: const Text('اختر ناديك والعب'))),
                            const SizedBox(width: 8),
                            OutlinedButton(onPressed: busy ? null : () => _download(p), child: const Text('تحديث')),
                          ])
                        : FilledButton.tonal(onPressed: busy ? null : () => _download(p), child: const Text('تنزيل')),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}
