import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'squad.dart';
import 'widgets.dart';

class FacilitiesScreen extends StatelessWidget {
  final GameState gs;
  const FacilitiesScreen({super.key, required this.gs});

  Widget _fac(BuildContext context, String kind, String title, String desc, int lvl) {
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
            child: FilledButton(
              onPressed: () {
                final err = gs.upgrade(kind);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الترقية ✅')));
              },
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
    return Scaffold(
      appBar: AppBar(title: const Text('🏗️ المنشآت')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
            Panel(
              child: Row(children: [
                const Text('💰 الميزانية', style: TextStyle(color: kMuted)),
                const Spacer(),
                Text(money(gs.user.budget), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAccent)),
              ]),
            ),
            _fac(context, 'stadium', '🏟️ الملعب', 'يرفع دخل التذاكر في المباريات على أرضك.', gs.user.stadium),
            _fac(context, 'training', '🏋️ مركز التدريب', 'يسرّع تطور اللاعبين ويحسّن التعافي الأسبوعي.', gs.user.trainingLvl),
            _fac(context, 'academy', '🌱 الأكاديمية', 'تنتج مواهب شابة بإمكانات عالية في نهاية كل موسم.', gs.user.academy),
            const Text('كل مستوى يزيد مصاريف الصيانة الأسبوعية قليلاً.', style: TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class AcademyScreen extends StatelessWidget {
  final GameState gs;
  const AcademyScreen({super.key, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌱 الأكاديمية')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final a = gs.user.academy;
            final intake = 1 + (a - 1) ~/ 2;
            final youths = gs.user.squad.where((p) => p.age <= 21).toList()
              ..sort((x, y) => y.potential.compareTo(x.potential));
            return ListView(padding: const EdgeInsets.all(14), children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('مستوى الأكاديمية', style: TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('$a/5', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 8),
                  Text('في نهاية الموسم ينضم $intake ${intake == 1 ? 'موهبة' : 'مواهب'} جديدة، بإمكانات متوقعة بين ${56 + 6 * a} و${71 + 6 * a} تقريباً.',
                      style: const TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: a >= 5
                          ? null
                          : () {
                              final err = gs.upgrade('academy');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت الترقية ✅')));
                            },
                      child: Text(a >= 5 ? 'أقصى مستوى ✅' : 'ترقية مقابل ${money(gs.upgradeCost(a))}'),
                    ),
                  ),
                ]),
              ),
              sectionTitle('المواهب الشابة (21 سنة فما دون)'),
              Panel(
                padding: EdgeInsets.zero,
                child: youths.isEmpty
                    ? const Padding(padding: EdgeInsets.all(14), child: Text('لا يوجد لاعبون شباب حالياً', style: TextStyle(color: kMuted)))
                    : Column(children: [
                        for (final p in youths)
                          PlayerTile(
                            p: p,
                            onTap: () => showPlayerSheet(context, gs, p),
                            trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('إمكانات ${p.potential}', style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${p.age} سنة', style: const TextStyle(color: kMuted, fontSize: 12)),
                            ]),
                          ),
                      ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
