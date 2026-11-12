import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'trophies.dart';
import 'widgets.dart';

/// شاشة التتويج بعد الفوز بلقب (خزينة البطولات): كأس كبير، إحصاءات الموسم وجوائز لاعبيك
class TitleScreen extends StatelessWidget {
  final GameState gs;
  final String comp;
  const TitleScreen({super.key, required this.gs, required this.comp});

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: c)),
            const SizedBox(height: 2),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 11.5)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    final isLeague = comp == 'الدوري';
    final count = gs.honours.where((h) => h.startsWith('🏆 $comp —')).length;
    final key = trophyKey(isLeague ? gs.leagueName : comp, gs.leagueName, isLeague: isLeague);
    final cs = gs.celebStats ?? const <String, int>{};
    final ssn = cs['s'] ?? gs.season;
    int v(String k, int d) => cs[k] ?? d;
    final won = <(String, String, String)>[];
    for (final p in u.squad) {
      for (final a in p.awards) {
        final info = kAwardInfo.values.where((x) => x.title == a['c']).firstOrNull;
        if (a['s'] == ssn && info != null) won.add((info.icon, info.title, p.name));
      }
    }
    final gd = v('gf', u.gf) - v('ga', u.ga);
    return Scaffold(
      appBar: AppBar(title: const Text('خزينة البطولات')),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 20), children: [
        Unfilter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22345C), Color(0xFF0F1B33)])),
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                child: Image.asset('assets/trophies/$key.png', height: 130, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 96))),
              ),
              const SizedBox(height: 10),
              Text('بطل ${isLeague ? gs.leagueName : comp}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 4),
              Text('الموسم $ssn • اللقب رقم $count في تاريخ النادي', style: const TextStyle(color: Color(0xFF9FB0D0), fontSize: 12.5)),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)), child: const Text('★ بقيادتك', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900, fontSize: 12.5))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          if (isLeague) ...[
            _tile('${v('pts', u.points)}', 'نقطة', const Color(0xFFD99A1C)),
            _tile('${v('w', u.won)}-${v('d', u.drawn)}-${v('l', u.lost)}', 'ف-ت-خ', kPrimary),
            _tile('${gd >= 0 ? '+' : ''}$gd', 'فارق الأهداف', const Color(0xFF1FA58A)),
          ] else ...[
            _tile('${v('pl', u.played)}', 'مباريات الموسم', kPrimary),
            _tile('${v('gf', u.gf)}', 'أهداف الفريق', const Color(0xFF1FA58A)),
          ],
          _tile('${v('top', 0)}', 'هدّاف الموسم', const Color(0xFFD99A1C)),
        ]),
        if (won.isNotEmpty) ...[
          sectionTitle('جوائز لاعبي الموسم'),
          SizedBox(
            height: 108,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final w in won.take(8))
                Container(
                  width: 92,
                  margin: const EdgeInsetsDirectional.only(end: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(w.$1, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(w.$2, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 10.5)),
                    Text(w.$3, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(flex: 2, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)), child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.w900))))),
          const SizedBox(width: 10),
          Expanded(
              flex: 3,
              child: GradientButton(
                label: 'مشاركة اللقب',
                icon: Icons.ios_share_rounded,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '🏆 ${u.name} بطل ${isLeague ? gs.leagueName : comp} — الموسم $ssn (اللقب رقم $count)'));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ نص اللقب إلى الحافظة')));
                },
              )),
        ]),
      ]),
    );
  }
}
