import 'package:flutter/material.dart' hide Text;
import 'game_state.dart';
import 'i18n.dart';
import 'widgets.dart';

/// رخصة المدرب: مستوى وخبرة ونقاط تُصرف على مزايا تؤثر فعلاً في اللعب
class ManagerScreen extends StatefulWidget {
  final GameState gs;
  const ManagerScreen({super.key, required this.gs});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  GameState get gs => widget.gs;

  static const _icons = {
    'sp': Icons.sports_soccer_rounded,
    'youth': Icons.trending_up_rounded,
    'negot': Icons.handshake_rounded,
    'motiv': Icons.mood_rounded,
    'fit': Icons.favorite_rounded,
    'tact': Icons.psychology_rounded,
  };

  static const _effects = {
    'sp': 'فرصة الجزاء +1.2% والحرة +8% لكل رتبة',
    'youth': 'نمو اللاعبين حتى 23 سنة +6% لكل رتبة',
    'negot': 'سعر الشراء -2.5% لكل رتبة',
    'motiv': 'معنويات الفريق +0.25 أسبوعياً لكل رتبة',
    'fit': 'تعافي اللياقة أسرع لكل رتبة',
    'tact': 'الألفة التكتيكية +1 إضافية لكل مباراة استقرار',
  };

  String _title(int l) => const ['', 'مدرب مبتدئ', 'مدرب ناشئ', 'مدرب محلي', 'مدرب محترف', 'مدرب متمرس', 'مدرب نخبة', 'مدرب قاري', 'مدرب عالمي', 'مدرب أسطوري', 'أسطورة التدريب'][l.clamp(1, 10)];

  @override
  Widget build(BuildContext context) {
    final lvl = gs.mgrLevel;
    final nx = gs.mgrNext;
    return Scaffold(
      appBar: AppBar(title: const Text('رخصة المدرب')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 26, backgroundColor: const Color(0xFF1FA58A), child: Text('$lvl', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title(lvl), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  Text('الخبرة: ${gs.mgrXp}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: gs.perkPoints > 0 ? const Color(0xFFF5A524) : kLine, borderRadius: BorderRadius.circular(20)),
                child: Text('نقاط: ${gs.perkPoints}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            ]),
            const SizedBox(height: 12),
            if (nx != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: nx.$1 / nx.$2, minHeight: 8, color: const Color(0xFF1FA58A), backgroundColor: kLine)),
              const SizedBox(height: 6),
              Text('${nx.$1} / ${nx.$2} للمستوى التالي', style: const TextStyle(color: kMuted, fontSize: 12)),
            ] else
              const Text('بلغت أعلى مستوى!', style: TextStyle(color: Color(0xFF1FA58A), fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('تكسب الخبرة من الفوز (10) والتعادل (4) والخسارة (1) ومن ترتيبك آخر الموسم (حتى 160). كل مستوى يمنحك نقطة.', style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 14),
        for (final e in GameState.perkDefs.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: Row(children: [
              Icon(_icons[e.key], color: const Color(0xFF1FA58A), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(e.value.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_effects[e.key]!, style: const TextStyle(color: Color(0xFF1FA58A), fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (var i = 0; i < GameState.maxPerkRank; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 5),
                        width: 22,
                        height: 8,
                        decoration: BoxDecoration(color: i < gs.user.perk(e.key) ? const Color(0xFFF5A524) : kLine, borderRadius: BorderRadius.circular(4)),
                      ),
                  ]),
                ]),
              ),
              FilledButton(
                onPressed: gs.user.perk(e.key) >= GameState.maxPerkRank || gs.perkPoints <= 0
                    ? null
                    : () {
                        final err = gs.spendPerk(e.key);
                        if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        setState(() {});
                      },
                child: const Text('+'),
              ),
            ]),
          ),
      ]),
    );
  }
}
