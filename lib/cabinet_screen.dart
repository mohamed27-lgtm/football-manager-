import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'calendar.dart';
import 'game_state.dart';
import 'models.dart';
import 'trophies.dart';
import 'awards_screens.dart' show AwardMedal;
import 'title_screen.dart';
import 'widgets.dart';
import 'match_pages.dart' show gameBar;

const _cBg1 = Color(0xFF0B1226), _cBg2 = Color(0xFF05080F), _cGold = Color(0xFFE6B422), _cTile = Color(0xFF1B2236);

/// تسمية الموسم مثل 25/26 من رقم الموسم داخل اللعبة
String seasonLabel(int s) {
  final y = GameCalendar.seasonStart(s).year;
  return '${(y % 100).toString().padLeft(2, '0')}/${((y + 1) % 100).toString().padLeft(2, '0')}';
}

/// خزينة البطولات: رفوف لكل بطولة (نسخها الفائزة) ثم رف الجوائز الفردية للاعبي النادي
class CabinetScreen extends StatelessWidget {
  final GameState gs;
  const CabinetScreen({super.key, required this.gs});

  /// البطولات مرتبة: الدوري، ثم القارية، ثم بقية الكؤوس
  Map<String, List<int>> _titles() {
    final m = <String, List<int>>{};
    for (final h in gs.honours) {
      final p = parseHonour(h);
      if (p == null) continue;
      m.putIfAbsent(p.$1, () => []).add(p.$2);
    }
    for (final v in m.values) {
      v.sort((a, b) => b.compareTo(a));
    }
    int rank(String k) => k == 'الدوري' ? 0 : (k.contains('أبطال') || k.contains('القاري') || k.contains('الأوروبي') || k.contains('العالم') ? 1 : (k.contains('السوبر') ? 3 : 2));
    final keys = m.keys.toList()..sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.compareTo(b));
    return {for (final k in keys) k: m[k]!};
  }

  List<({String id, String title, int season, Player p})> _indiv() {
    final out = <({String id, String title, int season, Player p})>[];
    for (final p in gs.user.squad) {
      for (final a in p.awards) {
        if (a['k'] != 'indiv') continue;
        final id = kAwardInfo.entries.where((e) => e.value.title == a['c']).firstOrNull?.key;
        if (id == null) continue;
        out.add((id: id, title: a['c'] as String, season: a['s'] as int, p: p));
      }
    }
    out.sort((a, b) => b.season.compareTo(a.season));
    return out;
  }

  Widget _head(String t, String sub) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
        child: Column(children: [
          Text(t, style: const TextStyle(color: _cGold, fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Color(0xFF8FA0C0), fontSize: 13)),
        ]),
      );

  Widget _seasonChip(String label, {Widget? lead}) => Container(
        height: 42,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C3650)),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E4D3A), Color(0xFF123226)]),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          if (lead != null) ...[lead, const SizedBox(width: 6)],
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
          if (lead == null) Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFE8EDF5), shape: BoxShape.circle)),
        ]),
      );

  Widget _tile(Widget art, String title, String sub, {bool isNew = false, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A3F4C), _cTile, Color(0xFF10141F)]),
                border: Border.all(color: const Color(0xFF2C3650)),
              ),
              child: Stack(children: [
                Center(child: art),
                if (isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _cGold, borderRadius: BorderRadius.circular(8)), child: const Text('جديد', style: TextStyle(color: Color(0xFF3A2A00), fontWeight: FontWeight.w900, fontSize: 11))),
                  ),
              ]),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(3)),
            child: Column(children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF111A30), fontWeight: FontWeight.w900, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Color(0xFF59647A), fontSize: 12)),
            ]),
          ),
        ]),
      );

  /// رف: ثلاثة أعمدة في الصف ثم حافة الرف
  Widget _shelves(List<Widget> cols) {
    final rows = <Widget>[];
    for (var i = 0; i < cols.length; i += 3) {
      final chunk = cols.skip(i).take(3).toList();
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var k = 0; k < 3; k++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: k < chunk.length ? chunk[k] : const SizedBox())),
        ]),
      ));
      rows.add(Container(height: 18, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))])));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final titles = _titles();
    final ind = _indiv();
    final cur = gs.season;
    return Scaffold(
      appBar: gameBar(context, gs, 'خزينة البطولات'),
      body: Unfilter(
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_cBg1, _cBg2])),
          child: ListenableBuilder(
            listenable: gs,
            builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 30), children: [
              Column(children: [
                const SizedBox(height: 8),
                const Text('خزينة', style: TextStyle(color: Color(0xFF8FA0C0), fontSize: 14)),
                Text('${gs.user.name} · البطولات', style: const TextStyle(color: _cGold, fontWeight: FontWeight.w900, fontSize: 30)),
                Container(width: 50, height: 2, margin: const EdgeInsets.only(top: 6), color: _cGold),
              ]),
              if (titles.isEmpty && ind.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('الخزينة فارغة — ستظهر هنا كل ألقابك وجوائز لاعبيك', style: TextStyle(color: Color(0xFF8FA0C0)))),
                ),
              for (final e in titles.entries) ...[
                _head(e.key == 'الدوري' ? gs.leagueName : e.key, '${e.value.length} ${e.value.length > 2 ? 'نسخ' : (e.value.length == 1 ? 'نسخة' : 'نسختان')}'),
                _shelves([
                  for (final s in e.value)
                    Column(children: [
                      _seasonChip(seasonLabel(s)),
                      _tile(
                        trophyImage(trophyKey(e.key == 'الدوري' ? gs.leagueName : e.key, gs.leagueName, isLeague: e.key == 'الدوري'), size: 96),
                        e.key == 'الدوري' ? gs.leagueName : e.key,
                        seasonLabel(s),
                        isNew: s == cur || s == cur - 1 && gs.seasonOver,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TitleScreen(gs: gs, comp: e.key, season: s))),
                      ),
                    ]),
                ]),
              ],
              if (ind.isNotEmpty) ...[
                _head('الجوائز الفردية', '${ind.length} ${ind.length > 2 ? 'جوائز' : (ind.length == 1 ? 'جائزة' : 'جائزتان')} • لاعبو ${gs.user.name}'),
                _shelves([
                  for (final a in ind)
                    Column(children: [
                      _seasonChip('${seasonLabel(a.season)}\n${a.p.name}', lead: playerFace(a.p, 30)),
                      _tile(AwardMedal(a.id, size: 84), a.title, seasonLabel(a.season), isNew: a.season == cur || a.season == cur - 1 && gs.seasonOver),
                    ]),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
