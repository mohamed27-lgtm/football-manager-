import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';


Widget _stepper(String label, String value, String sub, VoidCallback? minus, VoidCallback? plus) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
      child: Row(children: [
        _sq(Icons.add_rounded, plus, true),
        Expanded(
          child: Column(children: [
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(sub, style: const TextStyle(color: kMuted, fontSize: 11.5)),
          ]),
        ),
        _sq(Icons.remove_rounded, minus, false),
      ]),
    );

Widget _sq(IconData i, VoidCallback? on, bool primary) => GestureDetector(
      onTap: on,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: primary ? kPrimary : const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10)),
        child: Icon(i, color: primary ? Colors.white : const Color(0xFF15233D)),
      ),
    );

Widget _prob(String label, double v) {
  final c = v >= 0.7 ? const Color(0xFF1FA58A) : (v >= 0.4 ? const Color(0xFFF5A524) : const Color(0xFFE5533D));
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
    child: Column(children: [
      Row(children: [
        Text('${(v * 100).round()}%', style: TextStyle(color: c, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: v.clamp(0, 1).toDouble(), minHeight: 8, color: c, backgroundColor: kCard2)),
    ]),
  );
}

Widget _negoHead(Player p, List<(String, String)> tiles) => Column(children: [
      Row(children: [
        PlayerAvatar(p, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('${p.club ?? ''} • ${p.age} سنة', style: const TextStyle(color: kMuted, fontSize: 12.5)),
          ]),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: ratingColor(p.overall), shape: BoxShape.circle),
          child: Text('${p.overall}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        for (final t in tiles)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
              child: Column(children: [
                Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(t.$2, style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ),
          ),
      ]),
    ]);

Widget _negoButtons(BuildContext ctx, String primaryLabel, VoidCallback? on, {String secondary = 'إلغاء'}) => Row(children: [
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x4400A0FF), offset: Offset(0, 3))]),
            child: Text(secondary, style: const TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(flex: 3, child: GradientButton(label: primaryLabel, onPressed: on ?? () {})),
    ]);

/// تفاوض بمرحلتين: (1) اتفاق السعر مع النادي (3 جولات) ثم (2) الشروط الشخصية للاعب (راتب ومدة)
void showNegotiation(BuildContext context, GameState gs, Player p) {
  final ask = gs.buyPrice(p);
  final lo = max(0.1, ask * 0.5);
  final hi = ask * 1.2;
  var offer = max(lo, (ask * 0.85 * 10).round() / 10).toDouble();
  var round = 1;
  var done = false;
  var stage = 1; // 1 النادي، 2 اللاعب
  var agreed = ask;
  final dem0 = gs.signDemand(p);
  final wLo = (dem0 * 600).round() / 1000, wHi = (dem0 * 1900).round() / 1000;
  var wage = (dem0 * 1000).round() / 1000;
  var years = 4;
  var tries = 0;
  var msg = 'السعر المطلوب ${money(ask)}${p.club != null ? ' من ${p.club}' : ''}. قدّم عرضك؛ البائع قد يقبل أو يطلب أكثر.';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final fee = gs.agentFee(stage == 1 ? offer : agreed);
      final bonus = stage == 2 ? gs.renewBonus(wage) : 0.0;
      Widget stageBody;
      if (stage == 1) {
        final prob = ((offer / ask - 0.78) / 0.22).clamp(0.02, 1.0).toDouble();
        stageBody = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepper('عرضك للنادي', money(offer), 'طلب النادي ${money(ask)} • عمولة الوكيل ${money(fee)}', done || offer <= lo ? null : () => set(() => offer = max(lo, ((offer - 0.5) * 10).round() / 10)), done || offer >= hi ? null : () => set(() => offer = min(hi, ((offer + 0.5) * 10).round() / 10))),
          _prob('احتمال قبول النادي', prob),
          Text('الإجمالي مع العمولة ${money(offer + fee)} • ميزانيتك ${money(gs.user.budget)}', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]);
      } else {
        final dem = gs.signDemand(p);
        final prob = ((wage / dem - 0.8) / 0.2).clamp(0.02, 1.0).toDouble();
        stageBody = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepper('الراتب الأسبوعي', wageK(wage), 'اللاعب يطلب ${wageK(dem)}', done || wage <= wLo ? null : () => set(() => wage = max(wLo, ((wage - 0.005) * 1000).round() / 1000)), done || wage >= wHi ? null : () => set(() => wage = min(wHi, ((wage + 0.005) * 1000).round() / 1000))),
          _stepper('مدة العقد', '$years ${years == 1 ? 'سنة' : 'سنوات'}', 'من 5 سنوات', done || years <= 1 ? null : () => set(() => years--), done || years >= 5 ? null : () => set(() => years++)),
          _stepper('مكافأة التوقيع', money2(bonus), 'عمولة الوكيل ${money2(gs.agentFee(bonus))}', null, null),
          _prob('احتمال موافقة اللاعب', prob),
          Text('الصفقة ${money(agreed)} + عمولة ${money(fee)}', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]);
      }
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _negoHead(p, [(money(gs.buyPrice(p)), 'طلب النادي'), (money(p.value), 'القيمة السوقية'), ('${p.contract} ${p.contract == 1 ? 'سنة' : 'سنوات'}', 'العقد')]),
            const SizedBox(height: 10),
            Row(children: [
              for (final e in [(1, 'اتفاق النادي'), (2, 'شروط اللاعب')])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: stage == e.$1 ? kAccent.withOpacity(0.2) : kCard2, borderRadius: BorderRadius.circular(10), border: Border.all(color: stage == e.$1 ? kAccent : kLine)),
                    child: Text(e.$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: stage == e.$1 ? kAccent : kMuted)),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Panel(color: kCard2, child: Text(msg, style: const TextStyle(height: 1.5))),
            stageBody,
            const SizedBox(height: 12),
            done ? _negoButtons(ctx, 'إغلاق', () => Navigator.pop(ctx), secondary: 'رجوع') : _negoButtons(ctx, stage == 1 ? 'تقديم العرض (الجولة $round/3)' : 'عرض الشروط', () {
                        if (stage == 1) {
                          final r = gs.evaluateOffer(p, offer, round);
                          if (r.status == 'accept') {
                            agreed = min(offer, ask);
                            set(() {
                              stage = 2;
                              msg = 'اتفق النادي على ${money(agreed)}. الآن شروط اللاعب: يطلب نحو ${wageK(dem0)} أسبوعياً.';
                            });
                          } else if (r.status == 'counter') {
                            set(() {
                              round++;
                              msg = '${r.msg}\nالجولة $round من 3.';
                              offer = r.counter!;
                            });
                          } else {
                            gs.endNegotiation(p);
                            set(() {
                              done = true;
                              msg = r.msg;
                            });
                          }
                        } else {
                          tries++;
                          final r = gs.playerSignOffer(p, wage, years, tries);
                          if (r.status == 'accept') {
                            final err = gs.completeSigning(p, agreed, wage: wage, years: years, bonus: bonus);
                            gs.endNegotiation(p);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الصفقة ✅')));
                          } else if (r.status == 'counter') {
                            set(() {
                              msg = r.msg;
                              wage = r.counter!.clamp(wLo, wHi).toDouble();
                            });
                          } else {
                            gs.endNegotiation(p);
                            set(() {
                              done = true;
                              msg = r.msg;
                            });
                          }
                        }
                      }),
          ]),
        ),
      );
    }),
  );
}

/// تجديد عقد بالتفاوض: اختر عدد السنوات والراتب
void showRenewal(BuildContext context, GameState gs, Player p) {
  final cur = p.wage;
  final lo = (cur * 700).round() / 1000;
  final hi = (cur * 2600).round() / 1000;
  var wage = (gs.renewDemand(p) * 1000).round() / 1000;
  wage = wage.clamp(lo, hi).toDouble();
  var years = 3;
  var done = false;
  var msg = 'راتبه الحالي ${wageK(cur)} أسبوعياً، وعقده ${p.contract} ${p.contract == 1 ? 'سنة' : 'سنوات'}.';
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final bonus = gs.renewBonus(wage);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _negoHead(p, [(wageK(cur), 'الراتب الحالي'), (money(p.value), 'القيمة السوقية'), ('${p.contract} ${p.contract == 1 ? 'سنة' : 'سنوات'}', 'العقد')]),
            const SizedBox(height: 12),
            Panel(color: kCard2, child: Text(msg, style: const TextStyle(height: 1.5))),
            _stepper('الراتب الأسبوعي', wageK(wage), 'الحالي ${wageK(cur)} • يطلب ${wageK(gs.renewDemand(p))}', done || wage <= lo ? null : () => set(() => wage = max(lo, ((wage - 0.005) * 1000).round() / 1000)), done || wage >= hi ? null : () => set(() => wage = min(hi, ((wage + 0.005) * 1000).round() / 1000))),
            _stepper('مدة العقد', '$years ${years == 1 ? 'سنة' : 'سنوات'}', 'من 5 سنوات', done || years <= 1 ? null : () => set(() => years--), done || years >= 5 ? null : () => set(() => years++)),
            _stepper('مكافأة التوقيع', money2(bonus), 'عمولة الوكيل ${money2(gs.agentFee(bonus))}', null, null),
            _prob('احتمال موافقة اللاعب', ((wage / gs.renewDemand(p) - 0.8) / 0.2).clamp(0.02, 1.0).toDouble()),
            const SizedBox(height: 12),
            done ? _negoButtons(ctx, 'إغلاق', () => Navigator.pop(ctx), secondary: 'رجوع') : _negoButtons(ctx, 'تقديم العرض', () {
                        final r = gs.renewOffer(p, wage, years);
                        if (r.status == 'accept') {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجديد العقد ✅')));
                        } else {
                          set(() {
                            msg = r.msg;
                            if (r.counter != null) wage = r.counter!.clamp(lo, hi).toDouble();
                            if (r.status == 'reject') done = true;
                          });
                        }
                      
                      }),
          ]),
        ),
      );
    }),
  );
}
