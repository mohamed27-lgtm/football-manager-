import 'package:flutter/material.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';

String? statusOf(Player p) => p.injuredWeeks > 0
    ? 'مصاب (${p.injuredWeeks} أسبوع)'
    : p.suspendedMatches > 0
        ? 'موقوف'
        : null;

class PlayerTile extends StatelessWidget {
  final Player p;
  final VoidCallback onTap;
  final Widget? trailing;
  const PlayerTile({super.key, required this.p, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final st = statusOf(p);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          PlayerAvatar(p),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                PosChip(p.pos),
                const SizedBox(width: 8),
                Text('${p.age} سنة', style: const TextStyle(color: kMuted, fontSize: 12)),
                if (st != null) ...[
                  const SizedBox(width: 8),
                  Text(st, style: const TextStyle(color: Color(0xFFFF7043), fontSize: 12)),
                ],
              ]),
            ]),
          ),
          trailing ??
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('لياقة ${p.fitness.round()}%',
                    style: TextStyle(fontSize: 12, color: p.fitness < 70 ? const Color(0xFFFF8A65) : kMuted)),
                Text(p.morale >= 75 ? '😄' : p.morale >= 50 ? '🙂' : '😟'),
              ]),
        ]),
      ),
    );
  }
}

void showPlayerSheet(BuildContext context, GameState gs, Player p, {bool market = false}) {
  Widget chip(String l, String v) => Expanded(
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
      );
  void snack(String? err, String ok) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(err ?? ok)));
  showModalBottomSheet(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            PlayerAvatar(p, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${p.pos.label} • ${p.age} سنة', style: const TextStyle(color: kMuted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          if (p.pos == Pos.gk)
            StatBar('حراسة', p.gk)
          else ...[
            StatBar('هجوم', p.atk),
            StatBar('دفاع', p.def),
            StatBar('تمرير', p.pas),
          ],
          StatBar('الإمكانات', p.potential, color: const Color(0xFF7C4DFF)),
          StatBar('اللياقة', p.fitness, color: const Color(0xFF29B6F6)),
          StatBar('المعنويات', p.morale, color: const Color(0xFFFFCA28)),
          const SizedBox(height: 10),
          Row(children: [
            chip('مباريات', '${p.apps}'),
            chip('أهداف', '${p.goals}'),
            chip('صناعة', '${p.assists}'),
            chip('إنذارات', '${p.yellows}'),
          ]),
          const SizedBox(height: 10),
          Text('القيمة السوقية: ${money(p.value)}   •   الراتب الأسبوعي: ${money(p.wage)}',
              style: const TextStyle(color: kMuted, fontSize: 13)),
          if (!market)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('العقد: ${p.contract} ${p.contract <= 1 ? 'سنة (ينتهي هذا الموسم!)' : 'سنوات متبقية'}',
                  style: TextStyle(
                      fontSize: 13, color: p.contract <= 1 ? const Color(0xFFFFCA28) : kMuted)),
            ),
          const SizedBox(height: 14),
          if (market)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final err = gs.buy(p);
                  Navigator.pop(ctx);
                  snack(err, 'تمت الصفقة ✅');
                },
                child: Text('شراء مقابل ${money(gs.buyPrice(p))}'),
              ),
            )
          else
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final err = gs.sell(p);
                    Navigator.pop(ctx);
                    snack(err, 'تم البيع ✅');
                  },
                  child: Text('بيع ${money(gs.sellPrice(p))}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final err = gs.renew(p);
                    Navigator.pop(ctx);
                    snack(err, 'تم تجديد العقد ✅');
                  },
                  child: Text('تجديد ${money(gs.renewCost(p))}'),
                ),
              ),
            ]),
        ]),
      ),
    ),
  );
}

class SquadTab extends StatelessWidget {
  final GameState gs;
  const SquadTab({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    final sq = gs.user.squad;
    final inj = sq.where((p) => !p.available).length;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _kv('اللاعبون', '${sq.length}'),
          _kv('التقييم', gs.user.strength.toStringAsFixed(1)),
          _kv('غائبون', '$inj'),
          _kv('الرواتب/أسبوع', money(gs.weeklyWages)),
        ]),
      ),
      for (final pos in Pos.values) ...[
        sectionTitle(pos.plural),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final p in (sq.where((x) => x.pos == pos).toList()
              ..sort((a, b) => b.overall.compareTo(a.overall))))
              PlayerTile(p: p, onTap: () => showPlayerSheet(context, gs, p)),
          ]),
        ),
      ],
    ]);
  }

  Widget _kv(String k, String v) => Column(children: [
        Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(k, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);
}

class TransfersTab extends StatefulWidget {
  final GameState gs;
  const TransfersTab({super.key, required this.gs});
  @override
  State<TransfersTab> createState() => _TransfersTabState();
}

class _TransfersTabState extends State<TransfersTab> {
  int mode = 0; // 0 شراء 1 بيع 2 منشآت
  Pos? filter;

  void _upgrade(String kind) {
    final err = widget.gs.upgrade(kind);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'تمت الترقية ✅')));
  }

  Widget _fac(String kind, String title, String desc, int lvl) {
    final gs = widget.gs;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('المستوى $lvl/5', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: lvl / 5, minHeight: 8, color: kAccent, backgroundColor: kCard2),
        ),
        const SizedBox(height: 10),
        if (lvl < 5)
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => _upgrade(kind),
              child: Text('ترقية مقابل ${money(gs.upgradeCost(lvl))}'),
            ),
          )
        else
          const Text('أقصى مستوى ✅', style: TextStyle(color: kMuted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final list = (mode == 0 ? gs.market : gs.user.squad)
        .where((p) => filter == null || p.pos == filter)
        .toList()
      ..sort((a, b) => b.overall.compareTo(a.overall));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Panel(
        child: Row(children: [
          const Text('💰 الميزانية', style: TextStyle(color: kMuted)),
          const Spacer(),
          Text(money(gs.user.budget),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: gs.user.budget < 0 ? const Color(0xFFFF7043) : kAccent)),
        ]),
      ),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 0, label: Text('السوق')),
          ButtonSegment(value: 1, label: Text('بيع')),
          ButtonSegment(value: 2, label: Text('المنشآت')),
        ],
        selected: {mode},
        onSelectionChanged: (s) => setState(() => mode = s.first),
      ),
      const SizedBox(height: 10),
      if (mode == 2) ...[
        _fac('stadium', '🏟️ الملعب', 'يرفع دخل المباريات على أرضك.', gs.user.stadium),
        _fac('training', '🏋️ مركز التدريب', 'يسرّع تطور اللاعبين ويحسّن التعافي الأسبوعي.', gs.user.trainingLvl),
        _fac('academy', '🌱 الأكاديمية', 'تنتج مواهب شابة بإمكانات عالية في نهاية كل موسم.', gs.user.academy),
      ] else ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(label: const Text('الكل'), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
            ),
            for (final p in Pos.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ChoiceChip(label: Text(p.label), selected: filter == p, onSelected: (_) => setState(() => filter = p)),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        if (mode == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('يتجدد السوق كل 4 أسابيع ومع بداية كل موسم.', style: TextStyle(color: kMuted, fontSize: 12)),
          ),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final p in list)
              PlayerTile(
                p: p,
                onTap: () => showPlayerSheet(context, gs, p, market: mode == 0),
                trailing: Text(
                  money(mode == 0 ? gs.buyPrice(p) : gs.sellPrice(p)),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kAccent),
                ),
              ),
          ]),
        ),
      ],
    ]);
  }
}
