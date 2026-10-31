import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

/// شاشة التفاوض: عرضك ← قبول أو عرض مضاد أو انسحاب (3 جولات كحد أقصى)
void showNegotiation(BuildContext context, GameState gs, Player p) {
  final ask = gs.buyPrice(p);
  final lo = max(0.1, ask * 0.5);
  final hi = ask * 1.2;
  var offer = max(lo, (ask * 0.85 * 10).round() / 10).toDouble();
  var round = 1;
  var done = false;
  var msg = 'السعر المطلوب ${money(ask)}. قدّم عرضك؛ البائع قد يقبل أو يطلب أكثر.';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final fee = gs.agentFee(offer);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PlayerAvatar(p, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('${p.pos.label} • ${p.age} سنة • تقييم ${p.overall}', style: const TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Panel(
              color: kCard2,
              child: Text(msg, style: const TextStyle(height: 1.5)),
            ),
            Row(children: [
              Text('عرضك: ${money(offer)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAccent)),
              const Spacer(),
              Text('عمولة الوكيل ${money(fee)}', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
            Slider(
              value: offer.clamp(lo, hi).toDouble(),
              min: lo,
              max: hi,
              divisions: max(1, ((hi - lo) * 10).round()),
              label: money(offer),
              onChanged: done ? null : (v) => set(() => offer = (v * 10).round() / 10),
            ),
            Text('الإجمالي مع العمولة: ${money(offer + fee)} • ميزانيتك ${money(gs.user.budget)}',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: done
                  ? OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))
                  : FilledButton(
                      onPressed: () {
                        final r = gs.evaluateOffer(p, offer, round);
                        if (r.status == 'accept') {
                          final err = gs.completeSigning(p, min(offer, ask));
                          gs.endNegotiation(p);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الصفقة ✅')));
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
                      },
                      child: Text('قدّم العرض (الجولة $round/3)'),
                    ),
            ),
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
            Row(children: [
              PlayerAvatar(p, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('${p.pos.label} • ${p.age} سنة • تقييم ${p.overall}', style: const TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Panel(color: kCard2, child: Text(msg, style: const TextStyle(height: 1.5))),
            const Text('مدة العقد', style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (var y = 1; y <= 5; y++)
                ChoiceChip(
                  label: Text('$y ${y == 1 ? 'سنة' : 'سنوات'}'),
                  selected: years == y,
                  onSelected: done ? null : (_) => set(() => years = y),
                ),
            ]),
            const SizedBox(height: 8),
            Text('الراتب المعروض: ${wageK(wage)} / أسبوع', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kAccent)),
            Slider(
              value: wage.clamp(lo, hi).toDouble(),
              min: lo,
              max: hi,
              divisions: max(1, ((hi - lo) * 1000).round()),
              label: wageK(wage),
              onChanged: done ? null : (v) => set(() => wage = (v * 1000).round() / 1000),
            ),
            Text('مكافأة التوقيع ${money2(bonus)} + عمولة الوكيل ${money2(gs.agentFee(bonus))}',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: done
                  ? OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))
                  : FilledButton(
                      onPressed: () {
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
                      },
                      child: const Text('قدّم عرض التجديد'),
                    ),
            ),
          ]),
        ),
      );
    }),
  );
}
