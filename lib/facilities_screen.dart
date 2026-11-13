import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'squad.dart';
import 'calendar.dart';
import 'widgets.dart';
import 'club_ui.dart';
import 'lineup_pages.dart';
import 'match_pages.dart';

const _info = {
  'stadium': (Icons.stadium_rounded, Color(0xFFE5533D), 'الملعب', 'السعة وإيراد التذاكر والضيافة'),
  'training': (Icons.adjust_rounded, Color(0xFF2F7BE6), 'ملعب التدريب', 'تطور اللاعبين وتعافٍ أسرع'),
  'academy': (Icons.school_rounded, Color(0xFF1FA58A), 'أكاديمية الشباب', 'مواهب جديدة كل موسم'),
  'medical': (Icons.add_rounded, Color(0xFFE5533D), 'المركز الطبي', 'تعافٍ أسرع من الإصابات'),
  'fans': (Icons.star_rounded, Color(0xFFF5A524), 'منطقة المشجعين', 'دخل المباراة والمتجر والرعاة'),
};

String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

/// وصف الأثر عند مستوى معيّن
String facEffect(String kind, int l) => switch (kind) {
      'stadium' => 'سعة ${_n(12000 + 8000 * l)} متفرج',
      'training' => 'نمو اللاعبين +${(2 + 3 * (l - 1)).round()}% • تعافٍ +${(1.5 * (l - 1)).toStringAsFixed(1)} لياقة',
      'academy' => 'نحو ${(0.5 + 0.1 * l).toStringAsFixed(1)}+ خريج/موسم • إمكانات +${4 * l}',
      'medical' => 'تعافٍ +${(0.8 * (l - 1)).toStringAsFixed(1)} • ${7 * (l - 1)}% احتمال تقليص أسبوع إصابة',
      _ => 'دخل التذاكر +${4 * (l - 1)}% • الرعاية +${3 * (l - 1)}%',
    };

String facWhen(GameState gs, Project p) => GameCalendar.fmtShort(GameCalendar.weekStart(gs.season, gs.week + p.left));
String weeksText(int w) => w == 1 ? 'أسبوع' : (w == 2 ? 'أسبوعان' : '$w أسابيع');

class FacilitiesScreen extends StatelessWidget {
  final GameState gs;
  const FacilitiesScreen({super.key, required this.gs});

  Widget _crews(BuildContext context) {
    final slots = <Widget>[];
    for (var i = 0; i < kMaxCrews; i++) {
      final p = i < gs.projects.length ? gs.projects[i] : null;
      slots.add(Expanded(
        child: GestureDetector(
          onTap: p == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(gs: gs, kind: p.kind))),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p == null ? Colors.transparent : const Color(0xFFF5A524).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p == null ? kMuted.withOpacity(0.5) : const Color(0xFFF5A524).withOpacity(0.6)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.construction_rounded, size: 16, color: p == null ? kMuted : const Color(0xFFF5A524)),
                const SizedBox(width: 4),
                Expanded(child: Text(p == null ? 'الفريق ${i + 1}' : _info[p.kind]!.$3, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
              ]),
              const SizedBox(height: 8),
              if (p == null)
                const Text('متاح الآن', style: TextStyle(color: Color(0xFF1FA58A), fontWeight: FontWeight.w900, fontSize: 12))
              else ...[
                Text(weeksText(p.left), style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Bar(p.progress, const Color(0xFFF5A524), h: 5),
              ],
            ]),
          ),
        ),
      ));
    }
    return CardBox(
      child: Column(children: [
        Row(children: [
          const Text('فرق البناء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('مشغولة ${gs.projects.length} / $kMaxCrews', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(children: slots),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'المنشآت'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final u = gs.user;
            final upkeep = 0.03 * (u.stadium + u.trainingLvl) + 0.02 * (u.academy + u.medical + u.fanZone) + 0.04 * gs.projects.length;
            return ListView(padding: const EdgeInsets.all(14), children: [
              _crews(context),
              CardBox(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final e in kFacilityKinds.indexed) ...[
                    if (e.$1 > 0) const Divider(height: 1, color: kLine),
                    _row(context, e.$2),
                  ],
                ]),
              ),
              CardBox(
                child: Row(children: [
                  const Icon(Icons.receipt_long_rounded, color: kMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text('صيانة المنشآت أسبوعياً: ${money(upkeep)}. تزيد مع كل مستوى وأثناء المشاريع.', style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5))),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String kind) {
    final i = _info[kind]!;
    final lvl = gs.facLevel(kind);
    final pr = gs.projectOf(kind);
    final Widget trail = pr != null
        ? Pill('مستوى ${pr.toLevel} • ${weeksText(pr.left)}', const Color(0xFFF5A524), icon: Icons.arrow_forward_rounded)
        : lvl >= 5
            ? const Pill('أقصى مستوى', Color(0xFF1FA58A))
            : Pill('ترقية ${money(gs.facCost(kind, lvl))}', const Color(0xFFE5533D));
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FacilityScreen(gs: gs, kind: kind))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconBox(i.$1, i.$2, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.$3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(facEffect(kind, lvl), style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              LevelDots(level: lvl, color: i.$2, building: pr != null),
            ]),
          ),
          const SizedBox(width: 8),
          trail,
        ]),
      ),
    );
  }
}

/// صفحة منشأة واحدة: مستوياتها، متطلبات الترقية، وتقدم المشروع
class FacilityScreen extends StatelessWidget {
  final GameState gs;
  final String kind;
  const FacilityScreen({super.key, required this.gs, required this.kind});

  @override
  Widget build(BuildContext context) {
    final i = _info[kind]!;
    return Scaffold(
      appBar: gameBar(context, gs, i.$3),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final lvl = gs.facLevel(kind);
            final pr = gs.projectOf(kind);
            final cost = lvl < 5 ? gs.facCost(kind, lvl) : 0.0;
            final weeks = lvl < 5 ? gs.facWeeks(kind, lvl) : 0;
            final budgetOk = cost <= gs.user.budget;
            final crewOk = gs.projects.length < kMaxCrews;
            return ListView(padding: const EdgeInsets.all(14), children: [
              CardBox(
                child: Column(children: [
                  Row(children: [
                    IconBox(i.$1, i.$2, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i.$3, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('المستوى $lvl من 5', style: const TextStyle(color: kMuted)),
                      ]),
                    ),
                    if (pr != null) const Pill('قيد الترقية', Color(0xFFF5A524)),
                  ]),
                  if (pr != null) ...[
                    const SizedBox(height: 14),
                    Bar(pr.progress, const Color(0xFFF5A524), h: 9),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('${(pr.progress * 100).round()}%', style: const TextStyle(color: kMuted, fontSize: 12)),
                      const Spacer(),
                      Text('ينتهي بعد ${weeksText(pr.left)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ]),
                  ],
                ]),
              ),
              const SectionTitle('مستويات المنشأة'),
              CardBox(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var l = 1; l <= 5; l++) ...[
                    if (l > 1) const Divider(height: 1, color: kLine),
                    Container(
                      color: l == lvl + 1 ? const Color(0xFFE5533D).withOpacity(0.08) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: l <= lvl ? const Color(0xFF1FA58A) : (l == lvl + 1 ? const Color(0xFFE5533D) : kCard2)),
                          child: Text('$l', style: TextStyle(fontWeight: FontWeight.w900, color: l <= lvl + 1 ? Colors.white : kMuted)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(facEffect(kind, l), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: l > lvl + 1 ? kMuted : null))),
                        if (l <= lvl) const Icon(Icons.check_rounded, color: Color(0xFF1FA58A)),
                      ]),
                    ),
                  ],
                ]),
              ),
              if (lvl < 5 && pr == null)
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('المستوى ${lvl + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _mini(money(cost), 'التكلفة')),
                      const SizedBox(width: 8),
                      Expanded(child: _mini(weeksText(weeks), 'المدة')),
                      const SizedBox(width: 8),
                      Expanded(child: _mini('${kMaxCrews - gs.projects.length}', 'فرق متاحة')),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      Req('ميزانية كافية', budgetOk),
                      Req('فريق بناء متاح', crewOk),
                      Req('المستوى $lvl', true),
                    ]),
                    if (kind == 'stadium') const Padding(padding: EdgeInsets.only(top: 8), child: Text('⚠️ تنخفض السعة 15% طوال الأشغال، وقد تتجاوز التكلفة المقدّرة.', style: TextStyle(color: Color(0xFFE5533D), fontSize: 12, height: 1.5))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'ابدأ الترقية',
                        icon: Icons.construction_rounded,
                        onPressed: () => snack(context, gs.startProject(kind) ?? 'بدأ المشروع 🏗️'),
                      ),
                    ),
                  ]),
                ),
              if (pr != null)
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'متابعة المشروع',
                    icon: Icons.timelapse_rounded,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(gs: gs, kind: kind))),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _mini(String v, String l) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
          Text(l, style: const TextStyle(color: kMuted, fontSize: 11.5)),
        ]),
      );
}

/// مشروع البناء الجاري: نسبة الإنجاز، المراحل، المقاول، التسريع
class ProjectScreen extends StatelessWidget {
  final GameState gs;
  final String kind;
  const ProjectScreen({super.key, required this.gs, required this.kind});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameBar(context, gs, 'مشروع البناء'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final p = gs.projectOf(kind);
            if (p == null) {
              return const EmptyState(icon: Icons.check_circle_outline_rounded, title: 'اكتمل المشروع', subtitle: 'تمت الترقية بنجاح. تحقّق من صفحة المنشأة.');
            }
            final name = FacilitiesLogic.facNames[kind] ?? kind;
            final ct = kContractors[p.contractor.clamp(0, kContractors.length - 1)];
            final done = p.total - p.left;
            Color stepColor(int idx) {
              final cur = kPhases.lastIndexWhere((e) => p.progress >= e.$2);
              return idx < cur ? const Color(0xFF1FA58A) : (idx == cur ? const Color(0xFFF5A524) : kCard2);
            }

            final cur = kPhases.lastIndexWhere((e) => p.progress >= e.$2);
            return ListView(padding: const EdgeInsets.all(14), children: [
              CardBox(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('ينتهي ${facWhen(gs, p)}', style: const TextStyle(color: kMuted)),
                      const SizedBox(height: 4),
                      Text('المتبقي ${weeksText(p.left)}', style: const TextStyle(color: Color(0xFFB07A00), fontWeight: FontWeight.w900)),
                      if (p.delays > 0) Text('تأخر ${p.delays}×', style: const TextStyle(color: Color(0xFFE5533D), fontSize: 12)),
                    ]),
                  ),
                  Ring(value: p.progress, big: '${(p.progress * 100).round()}%', small: 'مكتمل', color: const Color(0xFFF5A524), size: 112),
                ]),
              ),
              const SectionTitle('مراحل المشروع'),
              CardBox(
                child: Column(children: [
                  for (final e in kPhases.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: stepColor(e.$1)),
                          child: e.$1 < cur ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.$2.$1, style: TextStyle(fontWeight: e.$1 <= cur ? FontWeight.w900 : FontWeight.w500, color: e.$1 > cur ? kMuted : null))),
                        Text(GameCalendar.fmtShort(GameCalendar.weekStart(gs.season, gs.week - done + (p.total * e.$2.$2).round())), style: const TextStyle(color: kMuted, fontSize: 12)),
                      ]),
                    ),
                ]),
              ),
              const SectionTitle('المقاول'),
              CardBox(
                child: Column(children: [
                  Row(children: [
                    const IconBox(Icons.handyman_rounded, kMuted, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ct.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Text('السرعة ', style: TextStyle(color: kMuted, fontSize: 12)),
                          LevelDots(level: ct.$2, color: const Color(0xFFE5533D)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Text('الجودة ', style: TextStyle(color: kMuted, fontSize: 12)),
                          LevelDots(level: ct.$3, color: const Color(0xFFE5533D)),
                        ]),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: blueBtn(p.boosted ? 'عمّال مضافون ✓' : 'إضافة عمّال +20% • ${money(gs.boostCost(p))}', () => snack(context, p.boosted ? 'أضفت عمّالاً من قبل' : (gs.boostProject(kind) ?? 'أُضيف عمّال: المدة أقصر'))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GradientButton(
                        label: p.rushed ? 'تم التسريع ✓' : 'تسريع كبير • ${money(gs.rushCost(p))}',
                        icon: Icons.bolt_rounded,
                        onPressed: () => snack(context, p.rushed ? 'سبق تسريع هذا المشروع' : (gs.rushProject(kind) ?? 'تم تسريع المشروع ⚡')),
                      ),
                    ),
                  ]),
                ]),
              ),
              CardBox(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(children: [
                  KvRow('المدفوع', money(p.cost), vc: const Color(0xFF1FA58A)),
                  const Divider(height: 1, color: kLine),
                  KvRow('تكلفة الصيانة الأسبوعية للمشروع', money(0.04)),
                  if (kind == 'stadium') ...[
                    const Divider(height: 1, color: kLine),
                    KvRow('سعة الملعب الآن', _n(gs.stadiumCapacity), vc: const Color(0xFFE5533D), sub: '−15% حتى الانتهاء'),
                  ],
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
