import 'package:flutter/material.dart' hide Text;
import 'api_football.dart';
import 'bundled.dart';
import 'flags.dart';
import 'i18n.dart';
import 'league_store.dart';
import 'pack_service.dart';
import 'widgets.dart';

/// صفحة تنزيل الصور (شعارات الأندية وصور اللاعبين) لكل دوري — على غرار متجر الإضافات
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});
  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  List<LeagueData>? leagues;
  final Map<String, PackInfo> packs = {};
  final Set<String> have = {};
  bool failed = false;
  bool busy = false;
  String? current;
  double progress = 0;
  String? error;
  int filter = 0; // 0 الكل، 1 محمّل، 2 غير محمّل
  String query = '';

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
    final l = (await Bundled.list()).toList()
      ..sort((a, b) {
        final c = a.country.compareTo(b.country);
        return c != 0 ? c : a.div.compareTo(b.div);
      });
    final h = <String>{};
    for (final d in l) {
      if (await LeagueStore.load(d.id, d.season) != null) h.add(_k(d));
    }
    _set(() {
      leagues = l;
      have
        ..clear()
        ..addAll(h);
    });
    try {
      final m = await PackService.manifest(await PackService.getBase());
      _set(() {
        failed = false;
        for (final p in m) {
          packs['${p.id}_${p.season}'] = p;
        }
      });
    } on ApiException catch (e) {
      _set(() {
        failed = true;
        error = e.message;
      });
    } catch (_) {
      _set(() => failed = true);
    }
  }

  Future<void> _download(LeagueData d) async {
    final p = packs[_k(d)];
    if (p == null) {
      _set(() => error = 'تنزيل الصور غير متاح لهذا الدوري حالياً، حاول لاحقاً.');
      return;
    }
    _set(() {
      busy = true;
      current = _k(d);
      progress = 0;
      error = null;
    });
    try {
      await PackService.download(await PackService.getBase(), p, (v) => _set(() => progress = v));
      _set(() => have.add(_k(d)));
    } on ApiException catch (e) {
      _set(() => error = e.message);
    } catch (_) {
      _set(() => error = 'فشل تنزيل الصور. تحقق من الإنترنت وحاول مجدداً.');
    } finally {
      _set(() {
        busy = false;
        current = null;
      });
    }
  }

  Future<void> _remove(LeagueData d) async {
    final p = packs[_k(d)];
    final ok = await confirmDialog(context,
        title: 'حذف الصور', body: 'ستُحذف صور ${d.name} من هذا الجهاز وتعود الأندية بلا شعارات.', confirm: 'حذف', danger: true);
    if (ok != true) return;
    if (p != null) {
      await PackService.remove(p);
    } else {
      await LeagueStore.delete(d.id, d.season);
    }
    _set(() => have.remove(_k(d)));
  }

  Future<void> _all() async {
    for (final d in leagues ?? const <LeagueData>[]) {
      if (!have.contains(_k(d)) && packs.containsKey(_k(d))) {
        await _download(d);
        if (error != null) break;
      }
    }
  }

  String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final all = leagues;
    final missing = all?.where((d) => !have.contains(_k(d)) && packs.containsKey(_k(d))).toList() ?? [];
    final missingBytes = missing.fold<int>(0, (a, d) => a + packs[_k(d)]!.bytes);
    final haveBytes = all?.where((d) => have.contains(_k(d)) && packs.containsKey(_k(d))).fold<int>(0, (a, d) => a + packs[_k(d)]!.bytes) ?? 0;
    final shown = (all ?? const <LeagueData>[]).where((d) {
      if (filter == 1 && !have.contains(_k(d))) return false;
      if (filter == 2 && have.contains(_k(d))) return false;
      final q = query.trim();
      return q.isEmpty || d.name.contains(q) || d.country.contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('تحميل الصور'), centerTitle: true),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 30), children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0B6B3A), Color(0xFF08361F)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.photo_library_outlined, size: 38, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('شعارات الأندية وصور اللاعبين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${have.length} / ${all.length} • ${_mb(haveBytes)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const Text('اللعبة تعمل بدون الصور، وتنزيلها اختياري ويُحفظ على جهازك.',
                          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0x33FF5252), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF8A80)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: const TextStyle(fontSize: 12))),
                    TextButton(onPressed: busy ? null : () => _set(() => error = null), child: const Text('إغلاق')),
                  ]),
                ),
              if (failed && packs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _set(() => error = null);
                      _init();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ),
              GradientButton(
                label: missing.isEmpty ? 'كل الصور محمّلة ✅' : '${tr('تحميل كل الصور')} (${_mb(missingBytes)})',
                icon: missing.isEmpty ? Icons.check_circle_outline : Icons.download_rounded,
                onPressed: busy || missing.isEmpty ? null : _all,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: tr('ابحث عن دولة'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: kCard2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final e in const {0: 'الكل', 1: 'محمّل', 2: 'غير محمّل'}.entries)
                  ChoiceChip(label: Text(e.value), selected: filter == e.key, onSelected: (_) => setState(() => filter = e.key)),
              ]),
              const SizedBox(height: 8),
              for (final d in shown) _row(d),
              if (shown.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا نتائج', style: TextStyle(color: kMuted)))),
            ]),
    );
  }

  Widget _row(LeagueData d) {
    final k = _k(d);
    final p = packs[k];
    final has = have.contains(k);
    final cur = current == k;
    final tier = d.div <= 1 ? 'الدرجة الأولى' : d.div == 2 ? 'الدرجة الثانية' : 'الدرجة الثالثة';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      child: Column(children: [
        Row(children: [
          FlagBadge(d.country, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text('${d.country} • $tier • ${d.teams.length} ${tr('فرق')}', style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 8),
          if (has) ...[
            const Icon(Icons.check_circle, color: kAccent),
            IconButton(
              tooltip: tr('حذف'),
              onPressed: busy ? null : () => _remove(d),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8A65)),
            ),
          ] else if (cur)
            Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: kAccent))
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onPressed: busy || p == null ? null : () => _download(d),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(p == null ? '—' : _mb(p.bytes)),
            ),
        ]),
        if (cur) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6)),
        ],
      ]),
    );
  }
}
