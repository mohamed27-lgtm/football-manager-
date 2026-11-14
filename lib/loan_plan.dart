import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';
import 'club_ui.dart';

/// اختيار وجهة إعارة مخططة: النادي والدور المتوقع والدقائق. يعيد true إذا تمت الإعارة.
Future<bool> showLoanPlan(BuildContext context, GameState gs, Player p) async {
  final opts = gs.loanOptions(p);
  final res = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBg,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('إعارة ${p.name} — اختر الوجهة', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('النمو يتبع الدقائق الفعلية: الشاب الذي يلعب كثيراً يتطور أكثر. الرسوم ${money(gs.loanOutFee(p))}.', style: const TextStyle(color: kMuted, fontSize: 12.5)),
          const SizedBox(height: 12),
          if (opts.isEmpty) const Text('لا توجد وجهات متاحة الآن', style: TextStyle(color: kMuted)),
          for (final o in opts)
            CardBox(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final err = gs.loanOut(p, opt: o);
                  Navigator.pop(sheet, err == null);
                  snack(context, err ?? 'تمت الإعارة ✅');
                },
                child: Row(children: [
                  teamBadge(o.club, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.club.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('${o.tier} • ${o.minutesLabel}', style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  Pill(o.roleLabel, o.role == 2 ? const Color(0xFF1FA58A) : (o.role == 1 ? const Color(0xFF2F7BE6) : const Color(0xFFF5A524))),
                ]),
              ),
            ),
        ]),
      ),
    ),
  );
  return res ?? false;
}
