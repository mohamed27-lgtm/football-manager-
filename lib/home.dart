import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'data_screen.dart';
import 'cups_screen.dart';
import 'game_state.dart';
import 'match_screen.dart';
import 'models.dart';
import 'finance_screen.dart';
import 'matches_screen.dart';
import 'leagues_screen.dart';
import 'more_screen.dart';
import 'squad.dart';
import 'business_screens.dart';
import 'club_screens.dart';
import 'activity_screen.dart';
import 'reports.dart';
import 'team_tab.dart';
import 'facilities_screen.dart';
import 'i18n.dart';
import 'images_screen.dart';
import 'lang_sheet.dart';
import 'settings.dart';
import 'widgets.dart';

class StartScreen extends StatefulWidget {
  final List<SaveMeta> saves;
  final ValueChanged<SaveMeta> onOpen;
  final ValueChanged<SaveMeta> onDelete;
  final StartReal onStartReal;
  final String coachName;
  final String email;
  final VoidCallback onLogout;
  const StartScreen({
    super.key,
    required this.saves,
    required this.onOpen,
    required this.onDelete,
    required this.onStartReal,
    required this.coachName,
    this.email = '',
    required this.onLogout,
  });
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int sel = 0;

  String _mb(int chars) => '${(chars / 1e6).toStringAsFixed(1)} MB';

  void _images() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImagesScreen()));

  void _newCareer() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeaguesScreen(onStart: widget.onStartReal)));

  Future<void> _share() async {
    await Clipboard.setData(const ClipboardData(text: 'https://github.com/mohamed27-lgtm/football-manager-/releases/latest'));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ رابط اللعبة')));
  }

  void _toggleTheme() {
    final st = AppSettings.i;
    final dark = !st.lightFor(MediaQuery.platformBrightnessOf(context));
    st.set(themeMode: dark ? 'light' : 'dark');
  }

  void _more() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('اللغة'),
            onTap: () {
              Navigator.pop(ctx);
              showLanguageSheet(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text('الوضع'),
            onTap: () {
              Navigator.pop(ctx);
              _toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text('تحميل الصور'),
            onTap: () {
              Navigator.pop(ctx);
              _images();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF8A65)),
            title: Text('تسجيل الخروج'),
            onTap: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saves = widget.saves;
    final name = widget.coachName;
    final initial = name.trim().isEmpty ? '⚽' : name.trim().characters.first.toUpperCase();
    final total = saves.fold<int>(0, (a, m) => a + m.bytes);
    final cur = saves.isEmpty ? 0 : sel.clamp(0, saves.length - 1);
    final dark = !AppSettings.i.lightFor(MediaQuery.platformBrightnessOf(context));
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), children: [
              Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kAccent,
                  child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('مرحباً بعودتك', style: TextStyle(color: kMuted, fontSize: 12.5)),
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.sd_storage_outlined, size: 18, color: kGold),
                    const SizedBox(width: 6),
                    Text(_mb(total), style: const TextStyle(fontWeight: FontWeight.w800, color: kGold)),
                  ]),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _more,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: kCard, shape: BoxShape.circle, border: Border.all(color: kLine)),
                    child: const Icon(Icons.menu),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              InkWell(
                onTap: _images,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x2200E676),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x5500E676)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('شعارات الأندية وصور اللاعبين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        const Text('اللعبة تعمل بدون الصور، وتنزيلها اختياري ويُحفظ على جهازك.', style: TextStyle(color: kMuted, fontSize: 11.5, height: 1.4)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_download_rounded, color: Colors.black),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _chip(Icons.language, 'اللغة', () => showLanguageSheet(context))),
                const SizedBox(width: 8),
                Expanded(child: _chip(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 'الوضع', _toggleTheme)),
                const SizedBox(width: 8),
                Expanded(child: _chip(Icons.share_outlined, 'مشاركة', _share)),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                const Text('ألعابك المحفوظة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (saves.isNotEmpty) Text('${cur + 1}/${saves.length}', style: const TextStyle(color: kMuted)),
              ]),
              const SizedBox(height: 10),
              if (saves.isEmpty)
                const EmptyState(icon: Icons.sports_soccer, title: 'لا توجد مسيرة بعد', subtitle: 'ابدأ لعبة جديدة واختر دولتك ونادي أحلامك.')
              else
                for (var i = 0; i < saves.length; i++) i == cur ? _expanded(saves[i]) : _collapsed(saves[i], i),
              const SizedBox(height: 12),
              InkWell(
                onTap: _newCareer,
                borderRadius: BorderRadius.circular(22),
                child: CustomPaint(
                  painter: _DashedRRect(const Color(0x8800E676)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('لعبة جديدة'), style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 17)),
                          const Text('ابدأ مسيرة جديدة', style: TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kLine))),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(child: _nav(Icons.home_rounded, 'الرئيسية', true, () {})),
              Expanded(child: _nav(Icons.cloud_download_outlined, 'التنزيلات', false, _images)),
              Expanded(child: _nav(Icons.more_horiz_rounded, 'المزيد', false, _more)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _nav(IconData i, String label, bool on, VoidCallback f) => InkWell(
        onTap: f,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 3, width: 28, margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: on ? kAccent : Colors.transparent, borderRadius: BorderRadius.circular(3))),
          Icon(i, color: on ? kAccent : kMuted),
          Text(label, style: TextStyle(fontSize: 11, color: on ? kAccent : kMuted, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
        ]),
      );

  Widget _chip(IconData i, String label, VoidCallback f) => InkWell(
        onTap: f,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 19),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _badge(SaveMeta m, double size) {
    final fb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF0B6B3A), borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Text(m.club.trim().isEmpty ? '⚽' : m.club.trim().characters.first, style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: Colors.white)),
    );
    if (m.badge == null) return fb;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Unfilter(child: CachedNetworkImage(imageUrl: m.badge!, errorWidget: (_, __, ___) => fb)),
    );
  }

  Future<void> _confirmDelete(SaveMeta m) async {
    final ok = await confirmDialog(context, title: 'حذف المسيرة', body: 'سيُحذف حفظ ${m.club} نهائياً.', confirm: 'حذف', danger: true);
    if (ok == true) widget.onDelete(m);
  }

  Widget _expanded(SaveMeta m) {
    final d = m.at == 0 ? null : DateTime.fromMillisecondsSinceEpoch(m.at);
    final date = d == null ? '' : '${d.day}/${d.month}/${d.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kLine)),
      child: Column(children: [
        Row(children: [
          _badge(m, 74),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.club, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              Text(widget.coachName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 13)),
              Text('${m.league} • ${tr('الأسبوع')} ${m.week}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
              if (date.isNotEmpty) Text(date, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x3300E676), borderRadius: BorderRadius.circular(10)),
              child: Text('${tr('الموسم')} ${m.season}', style: const TextStyle(color: kAccent, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),
            Text(_mb(m.bytes), style: const TextStyle(color: kMuted, fontSize: 12.5)),
            SizedBox(
              height: 30,
              width: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: tr('حذف'),
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF8A65)),
                onPressed: () => _confirmDelete(m),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => widget.onOpen(m),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: const Text('تحميل'),
          ),
        ),
      ]),
    );
  }

  Widget _collapsed(SaveMeta m, int i) => InkWell(
        onTap: () => setState(() => sel = i),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
          child: Row(children: [
            _badge(m, 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.club, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('${tr('الموسم')} ${m.season} • ${_mb(m.bytes)}', style: const TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kAccent.withOpacity(0.6), width: 1.5)),
              child: const Icon(Icons.expand_more_rounded, color: kAccent),
            ),
          ]),
        ),
      );
}

class _DashedRRect extends CustomPainter {
  final Color color;
  _DashedRRect(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRect old) => old.color != color;
}

class HomeShell extends StatefulWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.gs, required this.onRestart, required this.onLogout});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.gs.introSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showOpeningReport(context, widget.gs);
      });
    }
  }

  /// تنفيذ مهمة: ينقل المستخدم مباشرة إلى مكان القرار
  void _openTask(GameTask t) {
    switch (t.action) {
      case TaskAction.offers:
        setState(() => tab = 2);
        break;
      case TaskAction.board:
      case TaskAction.match:
        setState(() => tab = 0);
        break;
      case TaskAction.injuries:
        setState(() => tab = 1);
        break;
      case TaskAction.contracts:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(appBar: AppBar(title: const Text('العقود')), body: ContractsView(gs: widget.gs))));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gs,
      builder: (context, _) {
        final gs = widget.gs;
        if (gs.celebration != null) {
          final name = gs.celebration!;
          gs.celebration = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (c) => Dialog(
                backgroundColor: kCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: kGold)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.2, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                      child: const Text('🏆', style: TextStyle(fontSize: 84)),
                    ),
                    const SizedBox(height: 8),
                    const Text('مبروك! بطل', style: TextStyle(color: kMuted)),
                    Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kGold)),
                    const SizedBox(height: 6),
                    Text('أُضيف اللقب إلى خزانة البطولات', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                    const SizedBox(height: 16),
                    GradientButton(label: 'رائع!', onPressed: () => Navigator.pop(c)),
                  ]),
                ),
              ),
            );
          });
        }
        final pages = <Widget>[
          DashboardTab(gs: gs, onRestart: widget.onRestart, onNavigate: (i) => setState(() => tab = i), onTask: _openTask),
          TeamTab(gs: gs),
          TransfersTab(gs: gs),
          MatchesTab(gs: gs),
          MoreTab(gs: gs, onRestart: widget.onRestart, onLogout: widget.onLogout),
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBg,
            titleSpacing: 14,
            title: Row(children: [
              teamBadge(gs.user, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(gs.user.name, overflow: TextOverflow.ellipsis)),
            ]),
            actions: [
              Builder(builder: (ctx) {
                final n = gs.tasks.length;
                return IconButton(
                  tooltip: tr('مركز الإدارة'),
                  onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                      builder: (_) => ActivityScreen(gs: gs, onOpen: (t) {
                            Navigator.of(ctx).pop();
                            _openTask(t);
                          }))),
                  icon: Badge(
                    isLabelVisible: n > 0,
                    label: Text('$n'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs))),
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(children: [
                    const Text('💰 ', style: TextStyle(fontSize: 13)),
                    AnimatedMoney(gs.user.budget,
                        style: TextStyle(fontWeight: FontWeight.w900, color: gs.user.budget < 0 ? const Color(0xFFFF7043) : kAccent)),
                  ]),
                ),
              ),
            ],
          ),
          body: SafeArea(child: pages[tab]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr('الرئيسية')),
              NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: tr('الفريق')),
              NavigationDestination(icon: const Icon(Icons.swap_horiz), selectedIcon: const Icon(Icons.swap_horiz), label: tr('الانتقالات')),
              NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: const Icon(Icons.emoji_events), label: tr('المسابقات')),
              NavigationDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield), label: tr('النادي')),
            ],
          ),
        );
      },
    );
  }
}

class DashboardTab extends StatelessWidget {
  final GameState gs;
  final VoidCallback onRestart;
  final void Function(int) onNavigate;
  final void Function(GameTask) onTask;
  const DashboardTab({super.key, required this.gs, required this.onRestart, required this.onNavigate, required this.onTask});

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  Widget _hero() {
    final u = gs.user;
    final c = teamColor(u.id);
    final dark = HSLColor.fromColor(c).withLightness(0.16).toColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.withOpacity(0.85), dark]),
        boxShadow: [BoxShadow(color: c.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        teamBadge(u, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${gs.leagueName} • الموسم ${gs.season}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('الأسبوع ${(gs.week + 1).clamp(1, gs.rounds.length)} من ${gs.rounds.length}${u.venue != null ? ' • ${u.venue}' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text('${gs.position}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kGold)),
            const Text('المركز', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }

  Widget _tile(IconData i, String label, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLine),
          ),
          child: Column(children: [
            Icon(i, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
      );

  Widget _board(BuildContext context) {
    final b = GameState.boardTitles[gs.boardKind!]!;
    return Panel(
      color: const Color(0xFF1E1A10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance, color: kGold, size: 20),
          const SizedBox(width: 8),
          Text(b.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: kGold)),
        ]),
        const SizedBox(height: 8),
        Text(b.$2, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => gs.answerBoard(true), child: Text(b.$3))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => gs.answerBoard(false), child: Text(b.$4))),
        ]),
      ]),
    );
  }

  Widget _resources(BuildContext context) {
    Widget chip(IconData i, String v, String l, Color c, VoidCallback f) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
              child: Column(children: [
                Icon(i, color: c, size: 18),
                const SizedBox(height: 4),
                Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
                Text(l, style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        chip(Icons.account_balance_wallet_outlined, money(gs.user.budget), 'الميزانية', gs.user.budget < 0 ? const Color(0xFFFF7043) : kAccent, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs)))),
        const SizedBox(width: 8),
        chip(Icons.payments_outlined, money(gs.weeklyWages), 'رواتب/أسبوع', kGold, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs)))),
        const SizedBox(width: 8),
        chip(Icons.groups_outlined, '${gs.user.squad.length}', 'لاعباً', kBlue, () => onNavigate(1)),
      ]),
    );
  }

  /// تنبيه عاجل بزر ينقل المستخدم مباشرة إلى الحدث
  Widget _urgent(BuildContext context) {
    final u = gs.tasks.where((t) => t.urgent).toList();
    if (u.isEmpty) return const SizedBox.shrink();
    final t = u.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.6)),
        ),
        child: Row(children: [
          const Icon(Icons.priority_high, color: Color(0xFFFF5252)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(t.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5252), foregroundColor: Colors.white, minimumSize: const Size(64, 40)),
            onPressed: () => onTask(t),
            child: const Text('افتح'),
          ),
        ]),
      ),
    );
  }

  Widget _tasksPanel(BuildContext context) {
    final t = gs.tasks;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('المهام', trailing: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ActivityScreen(gs: gs, onOpen: (x) {
                  Navigator.of(context).pop();
                  onTask(x);
                }))),
        child: Text(t.isEmpty ? 'مركز الإدارة' : 'عرض الكل (${t.length})'),
      )),
      if (t.isEmpty)
        const Panel(child: EmptyState(icon: Icons.task_alt, title: 'لا مهام مفتوحة', subtitle: 'لا قرارات تنتظرك الآن.'))
      else
        for (final x in t.take(3)) TaskCard(task: x, onOpen: () => onTask(x)),
    ]);
  }

  Widget _offersCard() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onNavigate(2),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kGold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGold.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_active, color: kGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('لديك ${gs.offers.length} عرض لشراء لاعبيك', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${gs.offers.first.club} يعرض ${money(gs.offers.first.amount)} على ${gs.offers.first.player.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_left, color: kGold),
            ]),
          ),
        ),
      );

  Widget _recent() {
    final r = gs.recentResults();
    if (r.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('آخر النتائج'),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final e in r.reversed)
            () {
              final f = e.$1, home = e.$2;
              final my = home ? f.hg! : f.ag!, op = home ? f.ag! : f.hg!;
              final c = my > op ? kAccent : (my < op ? const Color(0xFFFF5252) : const Color(0xFFFFB300));
              final l = my > op ? 'ف' : (my < op ? 'خ' : 'ت');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(children: [
                  teamBadge(gs.team(f.home), size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gs.team(f.home).name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(8)),
                    child: Text('${f.hg} - ${f.ag}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(child: Text(gs.team(f.away).name, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  const SizedBox(width: 8),
                  teamBadge(gs.team(f.away), size: 24),
                  const SizedBox(width: 8),
                  CircleAvatar(radius: 11, backgroundColor: c, child: Text(l, style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w900))),
                ]),
              );
            }(),
        ]),
      ),
    ]);
  }

  Widget _stats() {
    final u = gs.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        _tile(Icons.account_balance_wallet_outlined, 'الرصيد', money(u.budget), u.budget < 0 ? const Color(0xFFFF7043) : kAccent),
        _tile(Icons.diamond_outlined, 'قيمة التشكيلة', money(gs.squadValue), kBlue),
        _tile(Icons.flag_outlined, 'النقاط', '${u.points}', kGold),
        _tile(Icons.trending_up, 'فارق الأهداف', '${u.gd >= 0 ? '+' : ''}${u.gd}', Colors.white),
      ]),
    );
  }

  Widget _actions(BuildContext context) {
    Widget a(IconData i, String t, Color c, VoidCallback f) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: f,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.withOpacity(0.35), c.withOpacity(0.12)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.withOpacity(0.5)),
                  ),
                  child: Icon(i, color: c, size: 26),
                ),
                const SizedBox(height: 6),
                Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        );
    Widget tile(IconData i, String t, String sub, Color c, VoidCallback f) => InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: f,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(i, color: c, size: 25),
              ),
              const SizedBox(height: 8),
              Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kMuted)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          tile(Icons.account_balance_wallet_outlined, 'المالية', money(gs.user.budget), kGold, () => _push(context, FinanceScreen(gs: gs))),
          tile(Icons.groups_outlined, 'التشكيلة', 'الفريق والتكتيك', kAccent, () => onNavigate(1)),
          tile(Icons.swap_horiz, 'الانتقالات', gs.offers.isEmpty ? 'سوق اللاعبين' : '${gs.offers.length} عرض جديد', kBlue, () => onNavigate(2)),
          tile(Icons.stadium_outlined, 'الملعب', 'المنشآت والأكاديمية', const Color(0xFF26C6DA), () => _push(context, FacilitiesScreen(gs: gs))),
          tile(Icons.handshake_outlined, 'الرعاة', 'دخل ${wageK(gs.dealsIncome)}', kGold, () => _push(context, SponsorsScreen(gs: gs))),
          tile(Icons.badge_outlined, 'الطاقم', 'مدربون وكشافة', const Color(0xFFBA68C8), () => _push(context, StaffScreen(gs: gs))),
          tile(Icons.emoji_events_outlined, 'المسابقات', gs.leagueName, kAccent, () => onNavigate(3)),
          tile(Icons.shield_outlined, 'النادي', 'الإرث والإعدادات', const Color(0xFFFF8A65), () => onNavigate(4)),
        ],
      ),
    );
  }

  Widget _miniTable() {
    final t = gs.table;
    final i = t.indexOf(gs.user);
    var from = (i - 2).clamp(0, t.length - 1);
    final to = (from + 5).clamp(0, t.length);
    from = (to - 5).clamp(0, t.length);
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        for (var k = from; k < to; k++)
          Container(
            decoration: BoxDecoration(
              color: t[k] == gs.user ? const Color(0x2200E676) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            child: Row(children: [
              SizedBox(width: 26, child: Text('${k + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: k < 4 ? kAccent : (k >= t.length - 3 ? const Color(0xFFFF5252) : kMuted)))),
              teamBadge(t[k], size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(t[k].name, style: TextStyle(fontWeight: t[k] == gs.user ? FontWeight.w800 : FontWeight.w600))),
              Text('${t[k].played} لعب', style: const TextStyle(color: kMuted, fontSize: 11)),
              const SizedBox(width: 12),
              SizedBox(width: 30, child: Text('${t[k].points}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = gs.user;
    final exp = gs.expiring;
    final showExp = exp.isNotEmpty && !gs.seasonOver && !gs.fired && gs.rounds.length - gs.week <= 8;
    return ListView(padding: const EdgeInsets.all(14), children: [
      _hero(),
      _resources(context),
      _urgent(context),
      if (gs.fired)
        Panel(
          color: const Color(0xFF2A1414),
          child: Column(children: [
            const Text('🚫 تمت إقالتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('فقدت ثقة مجلس الإدارة.', style: TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            GradientButton(
              label: 'ابدأ مسيرة جديدة',
              onPressed: () async {
                await GameState.clearSave();
                onRestart();
              },
            ),
          ]),
        )
      else if (gs.seasonOver)
        Panel(
          child: Column(children: [
            Text('🏁 انتهى الموسم ${gs.season}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('أنهيت الدوري في المركز ${gs.position} (الهدف: ${gs.objective})', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showSeasonReport(context, gs),
              icon: const Icon(Icons.assessment),
              label: const Text('تقرير نهاية الموسم'),
            ),
            const SizedBox(height: 8),
            GradientButton(label: 'ابدأ موسماً جديداً', icon: Icons.play_arrow, onPressed: gs.startNewSeason),
          ]),
        )
      else
        _nextMatch(context),
      _recent(),
      sectionTitle('الترتيب', trailing: TextButton(onPressed: () => onNavigate(3), child: const Text('الجدول كاملاً'))),
      _miniTable(),
      _tasksPanel(context),
      _actions(context),
      if (gs.boardKind != null) _board(context),
      Panel(
        child: Column(children: [
          Row(children: [
            const Icon(Icons.verified_user_outlined, size: 18, color: kMuted),
            const SizedBox(width: 8),
            const Text('ثقة الإدارة', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${gs.confidence.round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: ratingColor(gs.confidence))),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: gs.confidence / 100,
              minHeight: 10,
              color: ratingColor(gs.confidence),
              backgroundColor: kCard2,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('🎯 هدف الموسم: المركز ${gs.objective} أو أفضل',
                style: TextStyle(color: gs.position <= gs.objective ? kAccent : kGold, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      if (showExp) ...[
        sectionTitle('عقود تنتهي هذا الموسم'),
        Panel(
          child: Column(children: [
            for (final p in exp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  RatingBadge(p.overall, size: 30),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name)),
                  TextButton(
                    onPressed: () {
                      final err = gs.renew(p);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم تجديد العقد ✅')));
                    },
                    child: Text('جدّد ${money(gs.renewCost(p))}'),
                  ),
                ]),
              ),
          ]),
        ),
      ],
      sectionTitle('التدريب الأسبوعي'),
      Panel(
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in trainingModes.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: gs.training == e.key,
              onSelected: (_) => gs.setTraining(e.key),
            ),
        ]),
      ),
      sectionTitle('آخر الأخبار'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final n in gs.news.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 7, left: 8), decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle)),
                Expanded(child: Text(n, style: const TextStyle(height: 1.4))),
              ]),
            ),
        ]),
      ),
      SizedBox(height: u.budget < 0 ? 0 : 6),
    ]);
  }

  Widget _nextMatch(BuildContext context) {
    final pc = gs.pendingCup;
    if (pc != null) return CupMatchCard(gs: gs, cup: pc);
    final f = gs.userFixture!;
    final u = gs.user;
    final isHome = f.home == u.id;
    final opp = gs.team(isHome ? f.away : f.home);
    final lineupFit = u.lineup.isEmpty ? 100 : u.lineup.fold(0.0, (a, p) => a + p.fitness) / u.lineup.length;
    final absent = u.squad.where((p) => !p.available).length;
    final my = u.strength, op = opp.strength;
    final share = (my / (my + op)).clamp(0.2, 0.8).toDouble();
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(20)),
          child: Text('الجولة ${gs.week + 1} من ${gs.rounds.length} • ${isHome ? 'على أرضك' : 'خارج أرضك'}',
              style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _teamBox(isHome ? u : opp, strong: isHome)),
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGold)),
          ),
          Expanded(child: _teamBox(isHome ? opp : u, strong: !isHome)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text(my.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: kAccent)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Expanded(flex: (share * 100).round(), child: Container(height: 8, color: kAccent)),
                Expanded(flex: 100 - (share * 100).round(), child: Container(height: 8, color: const Color(0xFFFF5252))),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Text(op.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5252))),
        ]),
        const SizedBox(height: 4),
        const Text('القوة: أنت (أخضر) / الخصم (أحمر)', style: TextStyle(color: kMuted, fontSize: 11)),
        if (lineupFit < 80) ...[
          const SizedBox(height: 8),
          Text('⚠️ متوسط لياقة التشكيلة ${lineupFit.round()}% — فكّر في التدوير', style: const TextStyle(color: kGold, fontSize: 12)),
        ],
        if (absent > 0) ...[
          const SizedBox(height: 4),
          Text('🚑 $absent لاعبين غائبين (إصابة/إيقاف)', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: GradientButton(label: 'ادخل المباراة', icon: Icons.play_arrow_rounded, onPressed: () => playMatch(context, gs)),
        ),
      ]),
    );
  }

  Widget _teamBox(Team t, {bool strong = false}) => Column(children: [
        teamBadge(t, size: 58),
        const SizedBox(height: 8),
        Text(t.name, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
        const SizedBox(height: 6),
        FormDots(t.form),
      ]);
}
