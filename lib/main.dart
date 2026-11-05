import 'package:flutter/material.dart';
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
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ManagerApp());
}

class ManagerApp extends StatefulWidget {
  const ManagerApp({super.key});
  @override
  State<ManagerApp> createState() => _ManagerAppState();
}

class _ManagerAppState extends State<ManagerApp> {
  GameState? gs;
  bool hasSave = false;
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
    final h = await GameState.hasSave();
    if (mounted) {
      setState(() {
        hasSave = h;
        loading = false;
      });
    }
  }

  Future<void> _continue() async {
    final g = await GameState.load();
    if (g != null && mounted) setState(() => gs = g);
  }

  void _menu() {
    setState(() => gs = null);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark).copyWith(
      surface: kBg,
      primary: kAccent,
      onPrimary: Colors.black,
    );
    Widget home;
    if (loading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (acct == null) {
      home = AuthScreen(onAuthed: _enter);
    } else if (gs == null) {
      home = StartScreen(
        coachName: acct!.name,
        onLogout: _logout,
        hasSave: hasSave,
        onContinue: _continue,
        onStartReal: (List<Team> teams, int id, String name, {Pyramid? pyramid}) {
          final g = GameState.fromData(teams, id, name, pyramid: pyramid);
          g.save();
          setState(() => gs = g);
        },
      );
    } else {
      home = HomeShell(gs: gs!, onRestart: _menu, onLogout: _logout);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدرب كرة القدم',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Tajawal',
        colorScheme: scheme,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        cardTheme: CardTheme(color: kCard, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
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
          side: const BorderSide(color: kLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(color: kLine, space: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          height: 68,
          indicatorColor: const Color(0x3300E676),
          labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: st.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
                color: st.contains(WidgetState.selected) ? kAccent : kMuted,
              )),
          iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(color: st.contains(WidgetState.selected) ? kAccent : kMuted)),
        ),
      ),
      builder: (context, child) => ListenableBuilder(
        listenable: AppSettings.i,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(AppSettings.i.textScale)),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        ),
      ),
      home: home,
    );
  }
}
