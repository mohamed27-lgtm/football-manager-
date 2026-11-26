import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'models.dart';
import 'wallet.dart';
import 'widgets.dart';

/// متجر الكوينز: مزايا نادرة لا تُشترى إلا بكوينز اللعبة
void showCoinStore(BuildContext context, GameState gs) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CoinStore(gs: gs),
  );
}

class _CoinStore extends StatelessWidget {
  final GameState gs;
  const _CoinStore({required this.gs});

  void _say(BuildContext c, String? err, String ok) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? ok)));

  Widget _item(BuildContext c, {required IconData icon, required String title, required String sub, required int cost, required VoidCallback? on, String? note}) {
    final can = Wallet.i.coins >= cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: const Color(0x33FFC857), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: kMuted, fontSize: 12, height: 1.4)),
            if (note != null) Text(note, style: const TextStyle(color: kAccent, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: on == null || !can ? null : on,
          style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$cost', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 3),
            const Icon(Icons.monetization_on, size: 17),
          ]),
        ),
      ]),
    );
  }

  Future<Player?> _pickInjured(BuildContext c, {int min = 3}) {
    final inj = gs.user.squad.where((p) => p.injuredWeeks >= min).toList();
    if (inj.isEmpty) {
      _say(c, min == 1 ? 'لا يوجد لاعب مصاب' : 'لا يوجد لاعب مصاب إصابة طويلة (3 أسابيع فأكثر)', '');
      return Future.value(null);
    }
    return showDialog<Player>(
      context: c,
      builder: (d) => SimpleDialog(
        title: const Text('اختر المصاب'),
        children: [
          for (final p in inj)
            SimpleDialogOption(onPressed: () => Navigator.pop(d, p), child: Text('${p.name} — ${p.injuredWeeks} أسابيع')),
        ],
      ),
    );
  }

  Future<Player?> _pickTalent(BuildContext c) {
    final ts = gs.drawTalents();
    return showDialog<Player>(
      context: c,
      builder: (d) => SimpleDialog(
        title: const Text('اختر موهبة'),
        children: [
          for (final p in ts)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(d, p),
              child: Row(children: [
                PosChip(p.pos),
                const SizedBox(width: 8),
                Expanded(child: Text('${p.name} (${p.age} سنة)', style: const TextStyle(fontWeight: FontWeight.w800))),
                Text('${p.overall} ← ${p.potential}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
        ],
      ),
    );
  }

  Future<String?> _askName(BuildContext c) {
    final ctl = TextEditingController(text: gs.user.venue ?? '');
    return showDialog<String>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('اسم الملعب'),
        content: TextField(controller: ctl, maxLength: 30, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, ctl.text), child: const Text('تأكيد')),
        ],
      ),
    );
  }

  Future<int?> _pickLegend(BuildContext c) => showDialog<int>(
        context: c,
        builder: (d) => SimpleDialog(
          title: const Text('اختر أسطورة'),
          children: [
            for (final e in kLegends.indexed)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(d, e.$1),
                child: Row(children: [
                  PosChip(e.$2.$2),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.$2.$1, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text('${e.$2.$3}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([gs, Wallet.i]),
      builder: (c, _) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(c).size.height * 0.82,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), children: [
            Row(children: [
              const Icon(Icons.monetization_on, color: kGold, size: 28),
              const SizedBox(width: 8),
              Text('${Wallet.i.coins}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kGold)),
              const SizedBox(width: 10),
              const Expanded(child: Text('متجر الكوينز — مزايا لا تُشترى بمال النادي', style: TextStyle(fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 12),
            _item(c,
                icon: Icons.travel_explore,
                title: 'كشّاف مميز',
                sub: '5 مواهب شابة عالية الإمكانية من أنحاء العالم تدخل سوقك فوراً.',
                cost: CoinPerks.costScout,
                on: () => _say(c, gs.premiumScout(), 'أُضيفت 5 مواهب إلى السوق')),
            _item(c,
                icon: Icons.more_time,
                title: 'تمديد نافذة الانتقالات',
                sub: 'جولتان إضافيتان بعد الإغلاق. مرة في الموسم، وتُشترى والنافذة مفتوحة.',
                cost: CoinPerks.costWindow,
                note: gs.windowExtended ? 'مفعّل هذا الموسم' : (gs.windowOpen ? null : 'النافذة مغلقة الآن'),
                on: () => _say(c, gs.extendWindow(), 'مُدّدت النافذة جولتين')),
            _item(c,
                icon: Icons.flag_circle,
                title: 'أولوية في المفاوضات',
                sub: 'لن يخطف نادٍ منافس صفقاتك لأربع جولات.',
                cost: CoinPerks.costPriority,
                note: gs.priorityActive ? 'مفعّلة حتى الجولة ${gs.priorityUntil}' : null,
                on: () => _say(c, gs.buyPriority(), 'فُعّلت الأولوية')),
            _item(c,
                icon: Icons.replay_circle_filled,
                title: 'إعادة التفاوض',
                sub: 'بعد انسحاب البائع أو اللاعب، يظهر زر إعادة المحاولة داخل شاشة التفاوض (الجولات الثلاث من جديد).',
                cost: CoinPerks.costRetry,
                on: null),
            _item(c,
                icon: Icons.healing,
                title: 'علاج متقدم',
                sub: 'يختصر نصف مدة إصابة طويلة (3 أسابيع فأكثر). مرة في الموسم.',
                cost: CoinPerks.costHeal,
                note: gs.healSeason == gs.season ? 'استُخدم هذا الموسم' : null,
                on: () async {
                  final p = await _pickInjured(c);
                  if (p != null && c.mounted) _say(c, gs.healInjury(p), 'تم العلاج');
                }),
            _item(c,
                icon: Icons.star_rounded,
                title: 'لاعب أسطوري',
                sub: 'استقدم أسطورة متقاعدة بتقييم عالٍ إلى فريقك فوراً. واحد في الموسم.',
                cost: CoinPerks.costLegend,
                note: gs.legendSeason == gs.season ? 'استُخدم هذا الموسم' : null,
                on: () async {
                  final i = await _pickLegend(c);
                  if (i != null && c.mounted) _say(c, gs.signLegend(i), 'انضم الأسطورة إلى فريقك');
                }),
            _item(c,
                icon: Icons.shield,
                title: 'درع الإقالة',
                sub: 'يمنع إقالتك مرة واحدة إذا نزلت ثقة الإدارة إلى الصفر، ويعيدها إلى 40%. تحمل درعين كحد أقصى.',
                cost: CoinPerks.costShield,
                note: gs.sackShield > 0 ? 'لديك ${gs.sackShield}' : null,
                on: () => _say(c, gs.buyShield(), 'اشتريت درع إقالة')),
            _item(c,
                icon: Icons.undo,
                title: 'التراجع عن آخر صفقة',
                sub: 'يلغي آخر تعاقد ويستردّ كامل ما دفعته، خلال أسبوع من التعاقد.',
                cost: CoinPerks.costUndo,
                note: gs.undoableDeal == null ? 'لا توجد صفقة متاحة' : 'الصفقة: ${gs.undoableDeal!.name}',
                on: gs.undoableDeal == null ? null : () => _say(c, gs.undoLastDeal(), 'تم التراجع عن الصفقة')),
            _item(c,
                icon: Icons.medical_services,
                title: 'شفاء فوري',
                sub: 'ينهي إصابة لاعب بالكامل الآن. مرة في الموسم.',
                cost: CoinPerks.costFullHeal,
                note: gs.fullHealSeason == gs.season ? 'استُخدم هذا الموسم' : null,
                on: () async {
                  final p = await _pickInjured(c, min: 1);
                  if (p != null && c.mounted) _say(c, gs.healInjuryFull(p), 'شُفي اللاعب');
                }),
            _item(c,
                icon: Icons.auto_awesome,
                title: 'موهبة مضمونة',
                sub: 'اختر شاباً من 3 مواهب بإمكانية عالية جداً. واحدة في الموسم.',
                cost: CoinPerks.costTalent,
                note: gs.talentSeason == gs.season ? 'استُخدمت هذا الموسم' : null,
                on: () async {
                  final p = await _pickTalent(c);
                  if (p != null && c.mounted) _say(c, gs.signTalent(p), 'انضمت الموهبة إلى فريقك');
                }),
            _item(c,
                icon: Icons.stadium,
                title: 'اسم الملعب',
                sub: 'سمِّ ملعبك بما تشاء، ويظهر في صفحة الملعب.',
                cost: CoinPerks.costStadiumName,
                on: () async {
                  final n = await _askName(c);
                  if (n != null && c.mounted) _say(c, gs.renameStadium(n), 'تغيّر اسم الملعب');
                }),
            const SizedBox(height: 4),
            const Text('تسريع البناء فوراً', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            if (gs.projects.isEmpty) const Text('لا توجد مشاريع بناء جارية', style: TextStyle(color: kMuted, fontSize: 12.5)),
            for (final p in gs.projects)
              _item(c,
                  icon: Icons.bolt,
                  title: '${FacilitiesLogic.facNames[p.kind]} → المستوى ${p.toLevel}',
                  sub: 'يتبقى ${p.left} أسبوعاً. يكتمل الآن.',
                  cost: gs.instantBuildCost(p),
                  on: () => _say(c, gs.instantBuild(p.kind), 'اكتمل المشروع فوراً')),
          ]),
        ),
      ),
    );
  }
}
