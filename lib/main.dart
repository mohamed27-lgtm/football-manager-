import 'package:flutter/material.dart';
import 'logo_store.dart';
import 'package:flutter/services.dart';
import 'auth.dart';
import 'auth_screen.dart';
import 'game_state.dart';
import 'home.dart';
import 'models.dart';
import 'settings.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.i.load();
  await LogoStore.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ManagerApp());
}

/// نصوص بلون الحبر الكحلي (يظهر #15233D في الوضع الفاتح بعد المرشّح)
ThemeData _fixText(ThemeData t) {
  const c = Color(0xFFD0DEF8);
  return t.copyWith(textTheme: t.textTheme.apply(bodyColor: c, displayColor: c), colorScheme: t.colorScheme.copyWith(onSurface: c));
}

class ManagerApp extends StatefulWidget {
  const ManagerApp({super.key});
  @override
  State<ManagerApp> createState() => _ManagerAppState();
}

class _ManagerAppState extends State<ManagerApp> {
  GameState? gs;
  bool hasSave = false;
  List<SaveMeta> saves = [];
  bool loading = true;
  Account? acct;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _enter(Account a) async {
    GameState.slot = AuthService.slotFor(a.email);
    acct = a;
    await _refresh();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    GameState.slot = '';
    if (mounted) {
      setState(() {
        acct = null;
        gs = null;
        hasSave = false;
        saves = [];
      });
    }
  }

  Future<void> _refresh() async {
    if (acct == null) {
      final a = await AuthService.current();
      if (a != null) {
        GameState.slot = AuthService.slotFor(a.email);
        acct = a;
      }
    }
    final l = await GameState.listSaves();
    if (mounted) {
      setState(() {
        saves = l;
        hasSave = l.isNotEmpty;
        loading = false;
      });
    }
  }

  Future<void> _continue(SaveMeta m) async {
    final g = await GameState.load(m.id);
    if (g != null && mounted) setState(() => gs = g);
  }

  Future<void> _delete(SaveMeta m) async {
    await GameState.deleteSave(m.id);
    await _refresh();
  }

  void _menu() {
    setState(() => gs = null);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark).copyWith(
      surface: kBg,
      primary: kPrimary,
      onPrimary: Colors.white,
    );
    final light = AppSettings.i.lightFor(WidgetsBinding.instance.platformDispatcher.platformBrightness);
    Widget home;
    if (loading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (acct == null) {
      home = AuthScreen(onAuthed: _enter);
    } else if (gs == null) {
      home = StartScreen(
        coachName: acct!.name,
        email: acct!.email,
        onLogout: _logout,
        saves: saves,
        onOpen: _continue,
        onDelete: _delete,
        onStartReal: (List<Team> teams, int id, String name, {Pyramid? pyramid}) async {
          final sid = await GameState.newSaveId();
          GameState.activeId = sid;
          final g = GameState.fromData(teams, id, name, pyramid: pyramid)..saveId = sid;
          await g.save();
          if (mounted) setState(() => gs = g);
        },
      );
    } else {
      home = HomeShell(gs: gs!, onRestart: _menu, onLogout: _logout);
    }
    return ListenableBuilder(listenable: AppSettings.i, builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدرب كرة القدم',
      theme: _fixText(ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Tajawal',
        colorScheme: scheme,
        scaffoldBackgroundColor: kBg,
        appBarTheme: AppBarTheme(
          backgroundColor: lightPre(kNavy, light),
          foregroundColor: lightPre(Colors.white, light),
          iconTheme: IconThemeData(color: lightPre(Colors.white, light)),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w800, color: lightPre(Colors.white, light)),
        ),
        cardTheme: CardTheme(color: kCard, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            side: const WidgetStatePropertyAll(BorderSide(color: kPrimary, width: 1.5)),
            backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kPrimary : kCard),
            foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : kPrimary),
            textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kPrimary : kCard2),
          trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kPrimary : kLine),
        ),
        tabBarTheme: const TabBarTheme(
          indicatorColor: kPrimary,
          labelColor: kPrimary,
          unselectedLabelColor: kMuted,
          labelStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: kLine),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kCard2,
          selectedColor: kPrimary,
          checkmarkColor: Colors.white,
          secondaryLabelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontWeight: FontWeight.w800),
          side: const BorderSide(color: kLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(color: kLine, space: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          height: 68,
          indicatorColor: const Color(0x33F0593C),
          labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: st.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
                color: st.contains(WidgetState.selected) ? kPrimary : kMuted,
              )),
          iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(color: st.contains(WidgetState.selected) ? kPrimary : kMuted)),
        ),
      )),
      builder: (context, child) => ListenableBuilder(
        listenable: AppSettings.i,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(AppSettings.i.textScale)),
          child: Directionality(
          textDirection: AppSettings.i.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Builder(builder: (ctx) {
            final light = AppSettings.i.lightFor(MediaQuery.platformBrightnessOf(ctx));
            return light ? ColorFiltered(colorFilter: kLightFilter, child: child!) : child!;
          }),
        ),
        ),
      ),
      home: home,
    ));
  }
}
