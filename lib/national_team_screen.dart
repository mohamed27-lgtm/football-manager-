import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'flags.dart';
import 'game_state.dart';
import 'models.dart';
import 'world.dart';
import 'lineup_pages.dart';
import 'match_pages.dart' show whiteBtn, gameBar;
import 'widgets.dart';

/// صفحة منتخب: ترتيب فيفا، سجل حقيقي من المباريات والبطولات، أفضل تشكيلة، الهدّافون، وتدريب المنتخب
class NationScreen extends StatelessWidget {
  final GameState gs;
  final String nation;
  const NationScreen({super.key, required this.gs, required this.nation});

  Widget _box(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: child,
      );

  Widget _kpi(String v, String l, {Color? c}) => Expanded(
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(color: kMuted, fontSize: 11.5)),
        ]),
      );

  /// 4-3-3 من أفضل لاعبي الأمة
  List<Player> _xi(List<Player> pool) {
    final out = <Player>[];
    void take(Pos p, int n) => out.addAll(pool.where((x) => x.pos == p && !out.contains(x)).take(n));
    take(Pos.gk, 1);
    take(Pos.def, 4);
    take(Pos.mid, 3);
    take(Pos.att, 3);
    return out;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          gs.ensureNat();
          final rank = gs.nat.pubRanking;
          final pos = rank.indexOf(nation) + 1;
          final pts = gs.nat.pub[nation] ?? gs.nat.rating(nation);
          final r = gs.natRecord(nation);
          final pool = gs.natPlayers(nation);
          final all = [for (final e in pool) e.$1];
          final clubOf = {for (final e in pool) e.$1.id: e.$2.name};
          final xi = _xi(all);
          final avg = xi.isEmpty ? 0 : xi.fold<int>(0, (a, p) => a + p.overall) / xi.length;
          final scorers = gs.natScorers(nation);
          final mine = gs.natJob == nation;
          return Scaffold(
            appBar: gameBar(context, gs, 'منتخب $nation'),
            body: ListView(padding: const EdgeInsets.all(14), children: [
              _box(Row(children: [
                FlagBadge(nation, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nation, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    Text(kConfNames[gs.nat.conf[nation]] ?? '', style: const TextStyle(color: kMuted)),
                    if (mine) const Text('★ أنت مدرب هذا المنتخب', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 12.5)),
                  ]),
                ),
                Column(children: [
                  Text(pos > 0 ? '#$pos' : '—', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: kPrimary)),
                  Text('${pts.toStringAsFixed(1)} نقطة', style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ])),
              _box(Column(children: [
                Row(children: [
                  _kpi('${r.w + r.d + r.l}', 'مباريات'),
                  _kpi('${r.w}-${r.d}-${r.l}', 'ف-ت-خ', c: const Color(0xFF1FA58A)),
                  _kpi('${r.gf}:${r.ga}', 'الأهداف'),
                  _kpi('${r.titles}', 'ألقاب', c: kGold),
                ]),
                const SizedBox(height: 8),
                Text('السجل من المباريات الدولية والبطولات المُلعبة داخل اللعبة (من تاريخ بدء مسيرتك). نقاط التصنيف تبدأ من تصنيف فيفا الحقيقي.', style: const TextStyle(color: kMuted, fontSize: 11.5, height: 1.4)),
              ])),
              if (mine)
                _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('تدريب المنتخب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('تُلعب مباريات المنتخب في النوافذ الدولية بنفس محرك مبارياتك، بالتشكيلة التي تستدعيها (${gs.natCalled.length} لاعباً).', style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: blueBtn('الاستدعاءات', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CallupScreen(gs: gs))), icon: Icons.groups_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: whiteBtn('استقالة', () async {
                      final ok = await confirmDialog(context, title: 'مغادرة المنتخب', body: 'هل تريد التوقف عن تدريب منتخب $nation؟', confirm: 'استقالة', danger: true);
                      if (ok) gs.leaveNatJob();
                    })),
                  ]),
                  if (gs.natJobLog.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('نتائج منتخبك', style: TextStyle(fontWeight: FontWeight.w800)),
                    for (final l in gs.natJobLog.take(6))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          Expanded(child: Text('م${l[0]} • ${(l[5] as int) == 1 ? 'على أرضك' : 'خارج الأرض'} أمام ${l[1]} (${(l[4] as int) == 0 ? 'رسمية' : 'ودية'})', style: const TextStyle(fontSize: 12.5))),
                          Text('${l[2]}-${l[3]}', style: TextStyle(fontWeight: FontWeight.w900, color: (l[2] as int) > (l[3] as int) ? const Color(0xFF1FA58A) : ((l[2] as int) < (l[3] as int) ? const Color(0xFFE5533D) : kMuted))),
                        ]),
                      ),
                  ],
                ]))
              else if (gs.natJob != null)
                _box(Row(children: [
                  const Icon(Icons.sports_soccer_rounded, color: kPrimary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('مباراة ودية بمنتخب ${gs.natJob} أمام $nation (مرة كل أسبوع)', style: const TextStyle(fontSize: 12.5, height: 1.4))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: blueBtn('العب', () {
                      final err = gs.natFriendly(nation);
                      final l = gs.natJobLog.isEmpty ? null : gs.natJobLog.first;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'انتهت المباراة: ${l![2]}-${l[3]} أمام $nation')));
                    }),
                  ),
                ]))
              else if (gs.natJob == null)
                _box(Row(children: [
                  const Icon(Icons.flag_rounded, color: kPrimary),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('تولَّ تدريب هذا المنتخب إلى جانب ناديك: تستدعي اللاعبين وتلعب مبارياته الدولية بالمحرك الكامل.', style: TextStyle(fontSize: 12.5, height: 1.4))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: blueBtn('تولّي', () {
                      final err = gs.takeNatJob(nation);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'أصبحت مدرباً لمنتخب $nation ✅')));
                    }),
                  ),
                ])),
              sectionTitle('أفضل تشكيلة (4-3-3) • متوسط ${avg.toStringAsFixed(1)}'),
              if (xi.isEmpty)
                const EmptyState(icon: Icons.groups_outlined, title: 'لا لاعبين كافيين', subtitle: 'لا يتوفر لاعبو هذا المنتخب في عالم اللعبة.')
              else
                for (final p in xi)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
                    child: Row(children: [
                      playerFace(p, 38),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${p.pos.short} • ${clubOf[p.id] ?? ''}', style: const TextStyle(color: kMuted, fontSize: 11.5))])),
                      ratingRing(p.overall, size: 36),
                    ]),
                  ),
              if (scorers.isNotEmpty) ...[
                sectionTitle('هدّافو المنتخب في البطولات'),
                _box(Column(children: [for (final s in scorers.take(8)) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(s.$1)), Text('${s.$2}', style: const TextStyle(fontWeight: FontWeight.w900))]))])),
              ],
            ]),
          );
        },
      );
}

/// استدعاء لاعبي المنتخب (حتى 26) مع تعبئة تلقائية بأفضل اللاعبين
class CallupScreen extends StatelessWidget {
  final GameState gs;
  const CallupScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final job = gs.natJob;
          if (job == null) return Scaffold(appBar: gameBar(context, gs, 'الاستدعاءات'), body: const EmptyState(icon: Icons.flag_outlined, title: 'لا تدرّب منتخباً'));
          final pool = gs.natPlayers(job);
          final sel = gs.natCall.toSet();
          return Scaffold(
            appBar: gameBar(context, gs, 'استدعاءات $job'),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(children: [
                  Expanded(child: blueBtn('تعبئة تلقائية', gs.autoCall, icon: Icons.auto_fix_high_rounded)),
                  const SizedBox(width: 10),
                  Text('${sel.length}/26', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
              ),
            ),
            body: ListView(padding: const EdgeInsets.all(14), children: [
              const Text('اختر من 14 إلى 26 لاعباً. غير المتاحين (مصابون/موقوفون) لا يلعبون.', style: TextStyle(color: kMuted, fontSize: 12.5)),
              const SizedBox(height: 8),
              for (final e in pool.take(80))
                InkWell(
                  onTap: () => gs.toggleCall(e.$1),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel.contains(e.$1.id) ? kPrimary : kLine, width: sel.contains(e.$1.id) ? 2 : 1)),
                    child: Row(children: [
                      playerFace(e.$1, 38),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.$1.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${e.$1.pos.short} • ${e.$2.name}${e.$1.available ? '' : ' • غير متاح'}', style: TextStyle(color: e.$1.available ? kMuted : const Color(0xFFE5533D), fontSize: 11.5))])),
                      ratingRing(e.$1.overall, size: 34),
                      const SizedBox(width: 6),
                      Icon(sel.contains(e.$1.id) ? Icons.check_circle_rounded : Icons.circle_outlined, color: sel.contains(e.$1.id) ? kPrimary : kMuted),
                    ]),
                  ),
                ),
            ]),
          );
        },
      );
}
