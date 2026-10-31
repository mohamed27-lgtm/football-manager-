import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'home.dart';
import 'models.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
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
    } else if (gs == null) {
      home = StartScreen(
        hasSave: hasSave,
        onContinue: _continue,
        onStartReal: (List<Team> teams, int id, String name) {
          final g = GameState.fromData(teams, id, name);
          g.save();
          setState(() => gs = g);
        },
        onStart: (id) {
          final g = GameState(id);
          g.save();
          setState(() => gs = g);
        },
      );
    } else {
      home = HomeShell(gs: gs!, onRestart: _menu);
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
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: home,
    );
  }
}
