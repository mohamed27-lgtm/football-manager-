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
import 'tactics.dart';
import 'facilities_screen.dart';
import 'i18n.dart';
import 'images_screen.dart';
import 'sections_page.dart';
import 'lang_sheet.dart';
import 'settings.dart';
import 'widgets.dart';
import 'scouting_screen.dart';
import 'loans_screen.dart';
import 'stadium_screen.dart';
import 'match_pages.dart';
import 'countries.dart';

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
  int tab = 0; // 0 الرئيسية، 1 التنزيلات، 2 الأقسام

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
            child: tab == 1
                ? const ImagesScreen()
                : tab == 2
                    ? SectionsPage(name: name, email: widget.email, saves: saves, onLogout: widget.onLogout)
                    : _homeList(saves, name, initial, total, cur, dark),
          ),
          Container(
            decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kLine))),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(child: _nav(Icons.home_rounded, 'الرئيسية', tab == 0, () => setState(() => tab = 0))),
              Expanded(child: _nav(Icons.cloud_download_outlined, 'التنزيلات', tab == 1, () => setState(() => tab = 1))),
              Expanded(child: _nav(Icons.grid_view_rounded, 'الأقسام', tab == 2, () => setState(() => tab = 2))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _homeList(List<SaveMeta> saves, String name, String initial, int total, int cur, bool dark) =>
      ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), children: [
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
                    color: const Color(0x221FA58A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x551FA58A)),
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
                  painter: _DashedRRect(const Color(0x881FA58A)),
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
            ]);

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
              decoration: BoxDecoration(color: const Color(0x331FA58A), borderRadius: BorderRadius.circular(10)),
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
          MoreTab(gs: gs, onRestart: widget.onRestart, onLogout: widget.onLogout, onNavigate: (i) => setState(() => tab = i)),
        ];
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Unfilter(
              child: Container(
                color: kNavy,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      if (tab == 0) ...[
                        teamBadge(gs.user, size: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(gs.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                            Text('${gs.leagueName} • المركز ${gs.position}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
                          ]),
                        ),
                      ],
                      if (tab != 0) const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FinanceScreen(gs: gs))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.circle, size: 11, color: Color(0xFFFFC857)),
                            const SizedBox(width: 7),
                            AnimatedMoney(gs.user.budget,
                                style: TextStyle(fontWeight: FontWeight.w900, color: gs.user.budget < 0 ? const Color(0xFFFF8A65) : Colors.white)),
                          ]),
                        ),
                      ),
                      if (tab == 0) const SizedBox(width: 4),
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
                            backgroundColor: const Color(0xFFF0583A),
                            label: Text('$n'),
                            child: const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 26),
                          ),
                        );
                      }),
                    ]),
                  ),
                ),
              ),
            ),
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
              NavigationDestination(icon: const Icon(Icons.grid_view_rounded), selectedIcon: const Icon(Icons.grid_view_rounded), label: tr('المزيد')),
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
          tile(Icons.stadium_outlined, 'الملعب', 'التذاكر والحضور', const Color(0xFF26C6DA), () => _push(context, StadiumScreen(gs: gs))),
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
              color: t[k] == gs.user ? const Color(0x221FA58A) : null,
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

  Widget _card({required Widget child, EdgeInsets pad = const EdgeInsets.all(14), Color? color}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: pad,
        decoration: BoxDecoration(color: color ?? kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
        child: child,
      );

  Widget _clubHeader() {
    final u = gs.user;
    return _card(
      child: Row(children: [
        teamBadge(u, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${gs.leagueName} • المركز ${gs.position}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text('${gs.position}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
            const Text('المركز', style: TextStyle(fontSize: 10.5, color: kMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _formUnder(Team t) {
    final f = gs.formOf(t);
    return f.isEmpty ? const SizedBox(height: 26) : formChips(f, size: 24);
  }

  Widget _matchCard(BuildContext context) {
    final pc = gs.pendingCup;
    if (pc != null) return CupMatchCard(gs: gs, cup: pc);
    final f = gs.userFixture;
    if (f == null) return const SizedBox.shrink();
    final u = gs.user;
    final isHome = f.home == u.id;
    final home = gs.team(f.home), away = gs.team(f.away);
    Widget side(Team t) => Expanded(
          flex: 3,
          child: Column(children: [
            teamBadge(t, size: 70),
            const SizedBox(height: 8),
            Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            _formUnder(t),
          ]),
        );
    return GestureDetector(
      onTap: () => _push(context, NextMatchScreen(gs: gs)),
      child: Unfilter(
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF15233D), borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0xFF0B1426), offset: Offset(0, 4))]),
          child: Column(children: [
            Row(children: [
              Text('الجولة ${gs.week + 1} • ${gs.leagueName}', style: const TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF1FA58A).withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                child: Text(isHome ? 'على أرضك' : 'خارج أرضك', style: const TextStyle(color: Color(0xFF7FE0C8), fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              side(home),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(children: [
                    const Text('VS', style: TextStyle(color: Color(0xFF9FB0CC), fontWeight: FontWeight.w900)),
                    Text(NextMatchScreen.dayOf(gs), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    Text(NextMatchScreen.timeOf(gs), style: const TextStyle(color: Color(0xFFFFC857), fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('بعد ${gs.daysUntilMatch()} أيام', style: const TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
                  ]),
                ),
              ),
              side(away),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _push(context, Scaffold(appBar: gameBar(context, gs, 'التشكيلة'), body: TacticsTab(gs: gs))),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2))]),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('التشكيلة', style: TextStyle(color: Color(0xFF15233D), fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.groups_2_outlined, color: Color(0xFF15233D)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: GradientButton(label: 'العب المباراة', icon: Icons.sports_soccer_rounded, onPressed: gs.fired ? null : () => playMatch(context, gs))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _ring(String label, double v, Color c, String text) => Expanded(
        child: Column(children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: (v / 100).clamp(0, 1).toDouble(), strokeWidth: 7, color: c, backgroundColor: kCard2)),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      );

  Widget _teamStatus() {
    final u = gs.user;
    final xi = u.lineup.isEmpty ? u.squad.take(11).toList() : u.lineup;
    final fit = xi.isEmpty ? 0.0 : xi.fold<double>(0, (a, p) => a + p.fitness) / xi.length;
    final mor = xi.isEmpty ? 0.0 : xi.fold<double>(0, (a, p) => a + p.morale) / xi.length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      child: Row(children: [
        _ring('التقييم', u.strength, const Color(0xFF2F7BE6), '${u.strength.round()}'),
        _ring('اللياقة', fit, const Color(0xFF1FA58A), '${fit.round()}%'),
        _ring('المعنويات', mor, const Color(0xFF1FA58A), '${mor.round()}%'),
        _ring('الانسجام', u.cohesion, const Color(0xFFF5A524), '${u.cohesion.round()}%'),
      ]),
    );
  }

  Widget _lastMatchCard(BuildContext context) {
    final m = gs.lastMatch;
    if (m == null) return const SizedBox.shrink();
    Team? t(int id) {
      try {
        return gs.team(id);
      } catch (_) {
        return null;
      }
    }

    final h = t(m.homeId), a = t(m.awayId);
    final res = m.result;
    final label = res == 'W' ? 'فوز' : (res == 'L' ? 'خسارة' : 'تعادل');
    final lc = res == 'W' ? const Color(0xFF1FA58A) : (res == 'L' ? const Color(0xFFE5533D) : const Color(0xFF9AA3B2));
    final goals = [
      for (final e in m.events)
        if (e['t'] == 'goal' && (e['h'] as bool) == m.userHome) "${e['a']} '${e['m']}"
    ];
    Widget side(Team? tm, String name) => Expanded(
          child: Row(children: [
            if (tm != null) teamBadge(tm, size: 44),
            const SizedBox(width: 8),
            Flexible(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          const Text('آخر مباراة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const Spacer(),
          Text('الجولة ${m.round}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                side(h, m.homeName),
                Column(children: [
                  Text('${m.hg} - ${m.ag}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(color: lc.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                    child: Text(label, style: TextStyle(color: lc, fontWeight: FontWeight.w900)),
                  ),
                ]),
                Expanded(
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Flexible(child: Text(m.awayName, maxLines: 2, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                    const SizedBox(width: 8),
                    if (a != null) teamBadge(a, size: 44),
                  ]),
                ),
              ]),
              if (goals.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(goals.join('  •  '), textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ],
            ]),
          ),
          Container(height: 1, color: kLine),
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _push(context, MatchSummaryScreen(gs: gs, m: m, onContinue: () => Navigator.of(context).pop())),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('ملخص المباراة', style: TextStyle(color: Color(0xFFF0583A), fontWeight: FontWeight.w900, fontSize: 15)))),
              ),
            ),
            Container(width: 1, height: 44, color: kLine),
            Expanded(
              child: InkWell(
                onTap: () => _push(context, MatchSummaryScreen(gs: gs, m: m, initialTab: 1, onContinue: () => Navigator.of(context).pop())),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('الإحصائيات', style: TextStyle(color: Color(0xFFF0583A), fontWeight: FontWeight.w900, fontSize: 15)))),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }

  Widget _weekPlayers(BuildContext context) {
    final m = gs.lastMatch;
    final all = {for (final p in gs.user.squad) p.id: p};
    final tops = <(Player, double)>[];
    if (m != null) {
      for (final r in m.ratings) {
        if ((r['h'] as bool) == m.userHome && all.containsKey(r['id'])) tops.add((all[r['id']]!, (r['r'] as num).toDouble()));
      }
    } else {
      for (final p in gs.user.squad) {
        if (p.rated > 0) tops.add((p, p.avgRating));
      }
    }
    tops.sort((a, b) => b.$2.compareTo(a.$2));
    final top = tops.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          const Text('لاعبو الأسبوع', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const Spacer(),
          const Text('الأفضل أداءً', style: TextStyle(color: kMuted, fontWeight: FontWeight.w800)),
        ]),
      ),
      Row(children: [
        for (final e in top)
          Expanded(
            child: GestureDetector(
              onTap: () => showPlayerSheet(context, gs, e.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xFFE6E9F2), shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: e.$1.photo != null ? appImage(e.$1.photo!, w: 64, h: 64, fit: BoxFit.cover, fallback: const Icon(Icons.person, size: 38, color: Color(0xFF6A6FC4))) : const Icon(Icons.person, size: 38, color: Color(0xFF6A6FC4)),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(child: Text(e.$1.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (countryByName(e.$1.nat) != null) ...[const SizedBox(width: 5), FlagRect(countryByName(e.$1.nat)!.iso, w: 22)],
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: ratingColor(e.$2 * 10 + 15).withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                    child: Text(e.$2.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    ]);
  }

  Widget _quickGrid(BuildContext context) {
    final u = gs.user;
    final injured = u.squad.where((p) => p.injuredWeeks > 0).length;
    final offers = gs.offers.length;
    final items = <(IconData, String, int, VoidCallback)>[
      (Icons.groups_rounded, 'الفريق', injured, () => onNavigate(1)),
      (Icons.account_tree_rounded, 'التكتيك', 0, () => _push(context, Scaffold(appBar: AppBar(title: const Text('التشكيلة والتكتيك')), body: TacticsTab(gs: gs)))),
      (Icons.bolt_rounded, 'التدريب', 0, () => _training(context)),
      (Icons.swap_horiz_rounded, 'الانتقالات', offers, () => onNavigate(2)),
      (Icons.search_rounded, 'الكشافة', 0, () => _push(context, ScoutingScreen(gs: gs))),
      (Icons.compare_arrows_rounded, 'الإعارات', 0, () => _push(context, LoansScreen(gs: gs))),
      (Icons.account_balance_wallet_rounded, 'المالية', 0, () => _push(context, FinanceScreen(gs: gs))),
      (Icons.stadium_rounded, 'المنشآت', 0, () => _push(context, FacilitiesScreen(gs: gs))),
      (Icons.emoji_events_rounded, 'المسابقات', 0, () => onNavigate(3)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(bottom: 8, top: 2), child: Text('الوصول السريع', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
        children: [
          for (final it in items)
            InkWell(
              onTap: it.$4,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
                child: Stack(children: [
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(it.$1, size: 28, color: kPrimary),
                      const SizedBox(height: 6),
                      Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ]),
                  ),
                  if (it.$3 > 0)
                    Positioned(
                      top: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFFF3D3D), borderRadius: BorderRadius.circular(10)),
                        child: Text('${it.$3}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
              ),
            ),
        ],
      ),
    ]);
  }

  Widget _attention(BuildContext context) {
    final t = gs.tasks;
    if (t.isEmpty) return const SizedBox.shrink();
    String btn(GameTask x) => switch (x.action) {
          TaskAction.injuries => 'علاج',
          TaskAction.match => 'لعب',
          _ => 'عرض',
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text('يحتاج انتباهك', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
      for (final x in t.take(5))
        _card(
          pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: (x.urgent ? const Color(0xFFFF3D3D) : kGold).withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(x.urgent ? Icons.priority_high_rounded : Icons.info_outline_rounded, color: x.urgent ? const Color(0xFFFF3D3D) : kGold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(x.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, minimumSize: const Size(64, 38)),
              onPressed: () => onTask(x),
              child: Text(btn(x)),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 20), children: [
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
            const SizedBox(height: 10),
            GradientButton(label: 'ابدأ موسماً جديداً', icon: Icons.play_arrow_rounded, onPressed: gs.startNewSeason),
          ]),
        )
      else
        _matchCard(context),
      if (!gs.fired && !gs.seasonOver) ...[
        const Padding(padding: EdgeInsets.fromLTRB(2, 4, 2, 8), child: Text('حالة الفريق', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
        _teamStatus(),
        _lastMatchCard(context),
        _weekPlayers(context),
      ],
      if (gs.boardKind != null) _board(context),
      _attention(context),
    ]);
  }

  Widget _header(BuildContext context) {
    final u = gs.user;
    final n = gs.tasks.length;
    return Row(children: [
      teamBadge(u, size: 46),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(gs.leagueName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        child: Text(gs.seasonOver ? '🏁' : '${tr('الجولة')} ${gs.week + 1}', style: const TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: 12.5)),
      ),
      const SizedBox(width: 8),
      InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ActivityScreen(gs: gs, onOpen: (t) {
                  Navigator.of(context).pop();
                  onTask(t);
                }))),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: kCard, shape: BoxShape.circle, border: Border.all(color: kLine)),
          child: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.notifications_outlined)),
        ),
      ),
    ]);
  }

  Widget _playerRow(BuildContext context, Player p) {
    final st = statusOf(p);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showPlayerSheet(context, gs, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        child: Row(children: [
          PlayerAvatar(p),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                PosChip(p.pos),
                const SizedBox(width: 8),
                if (st != null)
                  Text(st, style: const TextStyle(color: Color(0xFFFF7043), fontSize: 11.5))
                else
                  Text('${p.fitness.round()}%', style: TextStyle(color: p.fitness < 70 ? const Color(0xFFFF8A65) : kMuted, fontSize: 11.5)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${p.age}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text('العمر', style: TextStyle(color: kMuted, fontSize: 10.5)),
          ]),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(p.value), style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text('القيمة', style: TextStyle(color: kMuted, fontSize: 10.5)),
          ]),
          const SizedBox(width: 12),
          RatingBadge(p.overall, size: 48),
        ]),
      ),
    );
  }

  Widget _actionBar(BuildContext context) {
    Widget sq(IconData i, String label, VoidCallback f) => InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
              child: Icon(i, size: 26),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        );
    final over = gs.seasonOver && !gs.fired;
    return Container(
      decoration: const BoxDecoration(color: kBg, border: Border(top: BorderSide(color: kLine))),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sq(Icons.view_list_rounded, 'القائمة', () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('التشكيلة والتكتيك')), body: TacticsTab(gs: gs))));
        }),
        const SizedBox(width: 10),
        sq(Icons.bolt_rounded, 'تدريب', () => _training(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: SizedBox(
              height: 56,
              child: GradientButton(
                label: over ? 'ابدأ موسماً جديداً' : 'العب',
                icon: Icons.play_arrow_rounded,
                onPressed: gs.fired ? null : (over ? gs.startNewSeason : () => playMatch(context, gs)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _training(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: gs,
        builder: (ctx, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('التدريب الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in trainingModes.entries)
                  ChoiceChip(label: Text(e.value), selected: gs.training == e.key, onSelected: (_) => gs.setTraining(e.key)),
              ]),
            ]),
          ),
        ),
      ),
    );
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1F1FA58A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x551FA58A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('المباراة القادمة', style: TextStyle(color: kMuted, fontSize: 12.5)),
          const Spacer(),
          Text('${gs.week + 1}/${gs.rounds.length} • ${isHome ? 'على أرضك' : 'خارج أرضك'}', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Text('ضد', style: TextStyle(color: kMuted)),
          const SizedBox(width: 10),
          teamBadge(opp, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Text(opp.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          FormDots(opp.form),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(my.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: kAccent)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Expanded(flex: (share * 100).round(), child: Container(height: 7, color: kAccent)),
                Expanded(flex: 100 - (share * 100).round(), child: Container(height: 7, color: const Color(0xFFFF5252))),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Text(op.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF5252))),
        ]),
        if (lineupFit < 80) ...[
          const SizedBox(height: 8),
          Text('⚠️ متوسط لياقة التشكيلة ${lineupFit.round()}% — فكّر في التدوير', style: const TextStyle(color: kGold, fontSize: 12)),
        ],
        if (absent > 0) ...[
          const SizedBox(height: 4),
          Text('🚑 $absent لاعبين غائبين (إصابة/إيقاف)', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
        ],
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
