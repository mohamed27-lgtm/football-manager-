import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'widgets.dart';

Widget _row(String k, String v, {Color? c}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(k, style: const TextStyle(color: kMuted))),
        Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
      ]),
    );

/// التقرير الافتتاحي بعد اختيار النادي + اختيار مستوى الصعوبة
Future<void> showOpeningReport(BuildContext context, GameState gs) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        final u = gs.user;
        return Dialog(
          backgroundColor: kCard,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('📋 تقرير الإدارة — ${u.name}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('مرحباً بك رئيساً/مدرباً للنادي. هذا وضعك قبل أول مباراة:',
                  textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
              const Divider(height: 24),
              _row('الميزانية', gs.money1(u.budget), c: kAccent),
              _row('حجم التشكيلة', '${u.squad.length} لاعباً'),
              _row('عقود تنتهي قريباً', '${gs.expiring.length} لاعب'),
              _row('المسابقة', gs.leagueName),
              _row('هدف الإدارة', 'المركز ${gs.objective} أو أفضل', c: kGold),
              const SizedBox(height: 16),
              GradientButton(
                label: 'ادخل إدارة النادي',
                icon: Icons.arrow_back,
                onPressed: () {
                  gs.startCareer(1);
                  Navigator.pop(c);
                },
              ),
            ]),
          ),
        );
      },
    ),
  );
}

/// تقرير نهاية الموسم
Future<void> showSeasonReport(BuildContext context, GameState gs) {
  final u = gs.user;
  final pos = gs.position;
  final ok = pos <= gs.objective;
  final top = [...u.squad]..sort((a, b) => b.goals.compareTo(a.goals));
  final scorer = top.isEmpty || top.first.goals == 0 ? '-' : '${top.first.name} (${top.first.goals})';
  final cup = gs.domestic?.champion == u.id;
  return showDialog(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: kCard,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('📊 التقرير السنوي — موسم ${gs.season}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Divider(height: 24),
          _row('المركز النهائي', '$pos (الهدف ${gs.objective})', c: ok ? kAccent : Colors.redAccent),
          _row('النقاط', '${u.points}'),
          _row('فوز / تعادل / خسارة', '${u.won} / ${u.drawn} / ${u.lost}'),
          _row('الأهداف', '${u.gf} له • ${u.ga} عليه'),
          _row('هداف الفريق', scorer),
          _row('كأس الدوري المحلي', cup ? 'بطل 🏆' : '—'),
          _row('ثقة الإدارة', '${gs.confidence.round()}٪'),
          _row('شعبية النادي', '${gs.fans.round()}٪'),
          _row('الميزانية', gs.money1(u.budget)),
          const Divider(height: 24),
          Text(
            ok ? 'الإدارة راضية عن النتيجة وتتوقع مثلها أو أفضل.' : 'الإدارة غير راضية عن النتيجة وسترفع سقف التوقعات.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
        ]),
      ),
    ),
  );
}
