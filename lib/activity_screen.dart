import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'transfers.dart';
import 'match_pages.dart';
import 'lineup_pages.dart';
import 'game_state.dart';
import 'jobs_screens.dart';
import 'widgets.dart';

/// رسالة في صندوق الوارد
class _Msg {
  final String key, title, body, sender, time;
  final int cat; // 0 انتقالات، 1 إدارة، 2 مباريات، 3 إصابات
  final DateTime day;
  final bool reply;
  final GameTask? task;
  const _Msg(this.key, this.title, this.body, this.sender, this.time, this.cat, this.day, {this.reply = false, this.task});
}

/// الرسائل: صندوق وارد مجمّع بالأيام مع شرائح تصنيف وشاشة تفاصيل
class ActivityScreen extends StatefulWidget {
  final GameState gs;
  final void Function(GameTask) onOpen;
  const ActivityScreen({super.key, required this.gs, required this.onOpen});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int tab = 0; // 0 الكل، 1 انتقالات، 2 إدارة، 3 مباريات، 4 إصابات، 5 تحديات
  GameState get gs => widget.gs;

  static const _catIcons = [Icons.swap_horiz_rounded, Icons.account_balance_rounded, Icons.sports_soccer_rounded, Icons.medical_services_rounded];
  static const _catColors = [Color(0xFF2F7BE6), Color(0xFF6A6FC4), Color(0xFF1FA58A), Color(0xFFE5533D)];
  static const _catNames = ['الانتقالات', 'الإدارة', 'المباريات', 'الطاقم الطبي'];

  int _catOfNews(String n) {
    if (RegExp(r'عرض|انتقال|صفقة|بعت|اشتريت|أعرت|تعاقد|إعارة|كشاف|سوق').hasMatch(n)) return 0;
    if (RegExp(r'الإدارة|المجلس|رعاية|هدف الإدارة|ميزانية|غرامة|اللعب المالي|مرافق|ترقية').hasMatch(n)) return 1;
    if (RegExp(r'أصيب|إصابة|🚑|تعافى').hasMatch(n)) return 3;
    return 2;
  }

  DateTime _parseDay(String? stamp) {
    if (stamp == null) return gs.today;
    final p = stamp.split('|').first.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  String _time(String? stamp) => stamp == null ? '' : stamp.split('|').last;

  List<_Msg> _messages() {
    final out = <_Msg>[];
    for (final t in gs.tasks) {
      final cat = switch (t.action) { TaskAction.offers => 0, TaskAction.injuries => 3, TaskAction.match => 2, _ => 1 };
      out.add(_Msg('t:${t.id}', t.title, t.body, switch (t.action) { TaskAction.offers => 'الانتقالات', TaskAction.injuries => 'الطاقم الطبي', TaskAction.job => 'عرض تدريب', _ => 'الإدارة' }, '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', cat, gs.today,
          reply: t.action == TaskAction.offers || t.action == TaskAction.board || t.action == TaskAction.job, task: t));
    }
    for (final n in gs.news.take(60)) {
      final st = gs.newsStamp[n];
      final c = _catOfNews(n);
      out.add(_Msg('n:$n', n.split('\n').first, n, _catNames[c], _time(st), c, _parseDay(st)));
    }
    return out;
  }

  String _group(DateTime d) {
    final t = gs.today;
    final days = DateTime(t.year, t.month, t.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'اليوم';
    if (days == 1) return 'أمس';
    if (days <= 7) return 'هذا الأسبوع';
    return 'أقدم';
  }

  Widget _chip(String label, int n, int i) {
    final sel = tab == i;
    final box = Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: sel ? kNavy : kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: sel ? kNavy : kLine)),
      child: Row(children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: sel ? Colors.white : kMuted)),
        if (n > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ]),
    );
    return GestureDetector(
      onTap: () => setState(() => tab = i),
      child: sel ? Unfilter(child: box) : box,
    );
  }

  Widget _row(_Msg m) {
    final unread = !gs.readMsgs.contains(m.key);
    final c = _catColors[m.cat];
    return InkWell(
      onTap: () {
        gs.readMsgs.add(m.key);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MessageDetailScreen(gs: gs, msg: m, onOpen: widget.onOpen))).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: m.reply ? kPrimary.withOpacity(0.5) : kLine)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(_catIcons[m.cat], color: c)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w700, fontSize: 14.5))),
                Text(m.time, style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 2),
              Text(m.sender, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(m.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4)),
              if (m.reply)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF5A524).withOpacity(0.25), borderRadius: BorderRadius.circular(6)),
                  child: const Text('يتطلب رداً', style: TextStyle(color: Color(0xFFA06A00), fontSize: 11, fontWeight: FontWeight.w900)),
                ),
            ]),
          ),
          if (unread) Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 6, right: 6), decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: gameBar(context, gs, 'الرسائل'),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: blueBtn('تحديد الكل كمقروءة', () {
              for (final m in _messages()) {
                gs.readMsgs.add(m.key);
              }
              setState(() {});
            }, icon: Icons.done_all_rounded),
          ),
        ),
        body: ListenableBuilder(
          listenable: gs,
          builder: (context, _) {
            final all = _messages();
            int count(int c) => all.where((m) => m.cat == c).length;
            final shown = tab == 0 ? all : (tab >= 1 && tab <= 4 ? all.where((m) => m.cat == const [0, 1, 2, 3][tab - 1]).toList() : <_Msg>[]);
            final groups = <String, List<_Msg>>{};
            for (final m in shown) {
              groups.putIfAbsent(_group(m.day), () => []).add(m);
            }
            const order = ['اليوم', 'أمس', 'هذا الأسبوع', 'أقدم'];
            final unreadN = all.where((m) => !gs.readMsgs.contains(m.key)).length;
            return Column(children: [
              SizedBox(
                height: 54,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(14, 10, 6, 6), children: [
                  _chip('الكل', all.length, 0),
                  _chip('الانتقالات', count(0), 1),
                  _chip('الإدارة', count(1), 2),
                  _chip('المباريات', count(2), 3),
                  _chip('الإصابات', count(3), 4),
                  _chip('التحديات', 0, 5),
                ]),
              ),
              if (tab != 5) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 6), child: Row(children: [Text('$unreadN غير مقروءة', style: const TextStyle(color: kMuted, fontSize: 12))])),
              Expanded(
                child: tab == 5
                    ? ListView(padding: const EdgeInsets.only(top: 8), children: [
                        for (final c in _challenges(gs))
                          Container(
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                            child: Row(children: [
                              Icon(c.$4 >= 1 ? Icons.emoji_events_rounded : Icons.flag_rounded, color: c.$4 >= 1 ? kGold : kBlue),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${c.$2} • ${c.$3}', style: const TextStyle(color: kMuted, fontSize: 12))])),
                            ]),
                          ),
                      ])
                    : shown.isEmpty
                        ? const EmptyState(icon: Icons.task_alt, title: 'لا رسائل', subtitle: 'كل شيء تحت السيطرة.')
                        : ListView(children: [
                            for (final g in order)
                              if (groups[g] != null) ...[
                                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text(g, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 13))),
                                for (final m in groups[g]!) _row(m),
                              ],
                          ]),
              ),
            ]);
          },
        ),
      );
}

/// تفاصيل الرسالة: عرض انتقال (قبول/تفاوض/رفض)، طلب إدارة، أو خبر
class MessageDetailScreen extends StatelessWidget {
  final GameState gs;
  final _Msg msg;
  final void Function(GameTask) onOpen;
  const MessageDetailScreen({super.key, required this.gs, required this.msg, required this.onOpen});

  Offer? get _offer {
    final t = msg.task;
    if (t == null || t.action != TaskAction.offers) return null;
    for (final o in gs.offers) {
      if ('offer-${o.player.id}' == t.id) return o;
    }
    return null;
  }

  Widget _kv(String k, String v, {Color? c}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: kMuted, fontSize: 13.5))),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final c = _ActivityScreenState._catColors[msg.cat];
    final o = _offer;
    final t = msg.task;
    Widget? bar;
    if (o != null) {
      bar = twoButtons(
        secondary: Row(children: [
          Expanded(child: blueBtn('تفاوض', () {
            Navigator.of(context).pop();
            onOpen(t!);
          })),
          const SizedBox(width: 8),
          Expanded(child: whiteBtn('رفض', () {
            gs.rejectOffer(o);
            Navigator.of(context).pop();
          })),
        ]),
        primary: GradientButton(
          label: 'قبول العرض',
          icon: Icons.check_rounded,
          onPressed: () {
            final err = gs.acceptOffer(o);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم قبول العرض ✅')));
          },
        ),
      );
    } else if (t != null && t.action == TaskAction.job) {
      bar = SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: GradientButton(label: 'مراجعة العرض', icon: Icons.work_outline_rounded, onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JobsScreen(gs: gs)));
          })));
    } else if (t != null && t.action == TaskAction.board) {
      bar = SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: GradientButton(label: 'ردّ على الإدارة', icon: Icons.reply_rounded, onPressed: () {
            Navigator.of(context).pop();
            onOpen(t);
          })));
    } else if (t != null) {
      bar = SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10), child: GradientButton(label: 'فتح', icon: Icons.open_in_new_rounded, onPressed: () {
            Navigator.of(context).pop();
            onOpen(t);
          })));
    }
    return Scaffold(
      appBar: gameBar(context, gs, 'الرسالة'),
      bottomNavigationBar: bar,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(_ActivityScreenState._catIcons[msg.cat], color: c)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), Text('${msg.cat == 0 ? 'الانتقالات' : msg.sender}', style: const TextStyle(color: kMuted, fontSize: 12))])),
          Text(msg.time, style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        Text(msg.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(msg.body, style: const TextStyle(color: kMuted, fontSize: 14.5, height: 1.6)),
        if (o != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
            child: Column(children: [
              _kv('اللاعب', '${o.player.name} • ${o.player.overall}'),
              _kv('النادي العارض', o.club),
              _kv('قيمة العرض', gs.money1(o.amount), c: const Color(0xFF1FA58A)),
              _kv('القيمة السوقية', gs.money1(o.player.value)),
              _kv('الفرق عن القيمة', '${o.amount >= o.player.value ? '+' : '-'}${gs.money1((o.amount - o.player.value).abs())}', c: o.amount >= o.player.value ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
              _kv('ينتهي العرض بعد', '${o.weeksLeft * 7} يوماً', c: o.weeksLeft <= 1 ? const Color(0xFFE5533D) : null),
            ]),
          ),
        ],
        if (t != null && t.action == TaskAction.board) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
            child: Column(children: [
              _kv('ثقة الإدارة', '${gs.confidence.round()}%', c: gs.confidence >= 50 ? const Color(0xFF1FA58A) : const Color(0xFFE5533D)),
              _kv('هدف الموسم', 'المركز ${gs.objective} أو أفضل'),
              _kv('مركزك الحالي', '${gs.position}'),
            ]),
          ),
        ],
      ]),
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
