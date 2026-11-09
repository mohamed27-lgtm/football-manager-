import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'widgets.dart';

/// الرسائل: مهام وأخبار وعمليات مرتبة في تبويبات
class ActivityScreen extends StatefulWidget {
  final GameState gs;
  final void Function(GameTask) onOpen;
  const ActivityScreen({super.key, required this.gs, required this.onOpen});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int tab = 0;
  bool read = false;
  GameState get gs => widget.gs;

  Widget _row(IconData icon, Color c, String title, String body, {String? when, String? action, VoidCallback? onTap, bool dot = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: c, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                if (when != null) Text(when, style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 2),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4)),
            ]),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(58, 34), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: onTap,
              child: Text(action),
            ),
          ],
          if (dot && !read) ...[
            const SizedBox(width: 8),
            Container(width: 9, height: 9, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
          ],
        ]),
      ),
    );
  }

  List<Widget> _taskRows(Iterable<GameTask> ts) => [
        for (final t in ts)
          _row(
            switch (t.action) {
              TaskAction.offers => Icons.swap_horiz_rounded,
              TaskAction.injuries => Icons.medical_services_rounded,
              TaskAction.board => Icons.account_balance_rounded,
              TaskAction.contracts => Icons.description_rounded,
              TaskAction.match => Icons.sports_soccer_rounded,
            },
            switch (t.action) {
              TaskAction.offers => kBlue,
              TaskAction.injuries => const Color(0xFFE5533D),
              TaskAction.board => const Color(0xFF6A6FC4),
              _ => kGold,
            },
            t.title,
            t.body,
            when: t.due,
            action: switch (t.action) {
              TaskAction.injuries => 'علاج',
              TaskAction.board => 'رد',
              _ => 'عرض',
            },
            onTap: () => widget.onOpen(t),
            dot: t.urgent,
          ),
      ];

  List<Widget> _newsRows(Iterable<String> ns) => [
        for (final n in ns) _row(Icons.newspaper_rounded, kGold, n.split('\n').first, n, when: null),
      ];

  @override
  Widget build(BuildContext context) {
    final labels = ['الكل', 'الإدارة', 'الانتقالات', 'الإصابات', 'التحديات'];
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final tasks = gs.tasks;
          List<Widget> rows;
          switch (tab) {
            case 1:
              rows = _taskRows(tasks.where((t) => t.action == TaskAction.board || t.action == TaskAction.contracts));
              break;
            case 2:
              rows = [..._taskRows(tasks.where((t) => t.action == TaskAction.offers)), ..._newsRows(gs.oplog.take(30))];
              break;
            case 3:
              rows = _taskRows(tasks.where((t) => t.action == TaskAction.injuries));
              break;
            case 4:
              rows = [
                for (final c in _challenges(gs))
                  _row(c.$4 >= 1 ? Icons.emoji_events_rounded : Icons.flag_rounded, c.$4 >= 1 ? kGold : kBlue, c.$1, '${c.$2} • ${c.$3}'),
              ];
              break;
            default:
              rows = [..._taskRows(tasks), ..._newsRows(gs.news.take(40))];
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [for (var i = 0; i < labels.length; i++) ButtonSegment(value: i, label: Text(labels[i]))],
                  selected: {tab},
                  onSelectionChanged: (v) => setState(() => tab = v.first),
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const EmptyState(icon: Icons.task_alt, title: 'لا رسائل', subtitle: 'كل شيء تحت السيطرة.')
                  : ListView(children: rows),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA9D4F8), foregroundColor: const Color(0xFF15233D), minimumSize: const Size(0, 50)),
                    onPressed: () => setState(() => read = true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تحديد الكل كمقروءة'),
                  ),
                ),
              ),
            ),
          ]);
        },
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
