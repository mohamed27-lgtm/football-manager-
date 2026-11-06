import 'package:flutter/material.dart';
import 'game_state.dart';
import 'widgets.dart';

/// مركز الإشعارات: المهام المفتوحة، الأخبار، وسجل العمليات
class ActivityScreen extends StatelessWidget {
  final GameState gs;
  final void Function(GameTask) onOpen;
  const ActivityScreen({super.key, required this.gs, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز الإدارة'),
          bottom: const TabBar(tabs: [Tab(text: 'المهام'), Tab(text: 'الأخبار'), Tab(text: 'سجل العمليات'), Tab(text: 'التحديات')]),
        ),
        body: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final tasks = gs.tasks;
            return TabBarView(children: [
              tasks.isEmpty
                  ? const EmptyState(icon: Icons.task_alt, title: 'لا مهام مفتوحة', subtitle: 'كل القرارات المطلوبة منك أُنجزت.')
                  : ListView(padding: const EdgeInsets.all(14), children: [for (final t in tasks) TaskCard(task: t, onOpen: () => onOpen(t))]),
              gs.news.isEmpty
                  ? const EmptyState(icon: Icons.newspaper, title: 'لا أخبار بعد')
                  : ListView(padding: const EdgeInsets.all(14), children: [
                      for (final n in gs.news.take(60))
                        Panel(padding: const EdgeInsets.all(12), child: Text(n, style: const TextStyle(height: 1.5))),
                    ]),
              gs.oplog.isEmpty
                  ? const EmptyState(icon: Icons.history, title: 'لا عمليات مسجّلة', subtitle: 'ستظهر هنا الصفقات والتجديدات والبيع.')
                  : ListView(padding: const EdgeInsets.all(14), children: [
                      for (final n in gs.oplog)
                        Panel(padding: const EdgeInsets.all(12), child: Row(children: [
                          const Icon(Icons.check_circle, color: kAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(n, style: const TextStyle(height: 1.4))),
                        ])),
                    ]),
              ListView(padding: const EdgeInsets.all(14), children: [
                for (final c in _challenges(gs))
                  Panel(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(c.$4 >= 1 ? Icons.emoji_events : Icons.flag, color: c.$4 >= 1 ? kGold : kBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w800))),
                        Text(c.$3, style: const TextStyle(color: kMuted, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: c.$4.clamp(0.0, 1.0), minHeight: 6, borderRadius: BorderRadius.circular(4)),
                    ]),
                  ),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final GameTask task;
  final VoidCallback onOpen;
  const TaskCard({super.key, required this.task, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = task.urgent ? const Color(0xFFFF5252) : kBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: task.urgent ? c.withOpacity(0.6) : kLine),
          ),
          child: Row(children: [
            Container(
              width: 6,
              height: 52,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  if (task.urgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                      child: Text('عاجل', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(task.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 3),
                Text('${task.reason} • ${task.due}', style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.chevron_left, color: kMuted),
          ]),
        ),
      ),
    );
  }
}

/// تحديات طويلة المدى مشتقة من حالة اللعبة: (العنوان، الوصف، التقدم نصاً، النسبة)
List<(String, String, String, double)> _challenges(GameState gs) {
  final titles = gs.history.where((h) => h['pos'] == 1).length;
  final seasons = gs.history.length;
  final young = gs.user.squad.where((p) => p.age <= 21 && p.overall >= 70).length;
  final cups = gs.honours.where((h) => !h.contains('الدوري')).length;
  return [
    ('بطل الدوري', 'افز بلقب الدوري مرة واحدة', '${titles.clamp(0, 1)}/1', titles / 1),
    ('هيمنة محلية', 'افز بالدوري 3 مرات', '${titles.clamp(0, 3)}/3', titles / 3),
    ('مسيرة طويلة', 'أكمل 5 مواسم مع النادي', '${seasons.clamp(0, 5)}/5', seasons / 5),
    ('بطولة كأس', 'افز بأي كأس', '${cups.clamp(0, 1)}/1', cups / 1.0),
    ('جيل المستقبل', 'امتلك 3 لاعبين تحت 22 بتقييم 70+', '${young.clamp(0, 3)}/3', young / 3),
    ('خزينة آمنة', 'ارفع الميزانية إلى 100M', '${gs.money1(gs.user.budget)}/100M', gs.user.budget / 100),
  ];
}
