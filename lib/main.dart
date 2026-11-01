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
        onStartReal: (List<Team> teams, int id, String name) {
          final g = GameState.fromData(teams, id, name);
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
        colorScheme: scheme,
        scaffoldBackgroundColor: kBg,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: kCard,
          indicatorColor: Color(0x3300E676),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
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
