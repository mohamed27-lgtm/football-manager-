import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('واقعية المباراة: أهداف، أفضلية الأرض، قوة', () {
    final r = Random(3);
    var n = 0, goals = 0, hw = 0, dr = 0, aw = 0, o25 = 0, btts = 0, cs = 0;
    for (var i = 0; i < 3000; i++) {
      final h = createTeam(r, 0, 'H', 3 + r.nextInt(3));
      final a = createTeam(r, 1, 'A', 3 + r.nextInt(3));
      final m = MatchSim(h, a, random: r)..simulateAll();
      final hg = m.home.goals, ag = m.away.goals;
      n++;
      goals += hg + ag;
      if (hg > ag) hw++; else if (hg == ag) dr++; else aw++;
      if (hg + ag > 2) o25++;
      if (hg > 0 && ag > 0) btts++;
      if (hg == 0 || ag == 0) cs++;
    }
    // ignore: avoid_print
    print('DIAG match: goals/match=${(goals / n).toStringAsFixed(2)} home=${(hw * 100 / n).toStringAsFixed(1)}% draw=${(dr * 100 / n).toStringAsFixed(1)}% away=${(aw * 100 / n).toStringAsFixed(1)}% over2.5=${(o25 * 100 / n).toStringAsFixed(1)}% btts=${(btts * 100 / n).toStringAsFixed(1)}% cleansheet=${(cs * 100 / n).toStringAsFixed(1)}%');
    // قوة أعلى تفوز أكثر
    var strongWins = 0, strongDraw = 0;
    for (var i = 0; i < 2000; i++) {
      final h = createTeam(r, 0, 'H', 7);
      final a = createTeam(r, 1, 'A', 3);
      final m = MatchSim(h, a, random: r)..simulateAll();
      if (m.home.goals > m.away.goals) strongWins++;
      if (m.home.goals == m.away.goals) strongDraw++;
    }
    // ignore: avoid_print
    print('DIAG strong(rep7) vs weak(rep3) at home: win=${(strongWins * 100 / 2000).toStringAsFixed(1)}% draw=${(strongDraw * 100 / 2000).toStringAsFixed(1)}%');
  });

  test('الدوري والاقتصاد عبر 8 مواسم', () {
    final r = Random(11);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 5, 'تجريبي');
    for (var s = 1; s <= 8; s++) {
      var guard = 0;
      while (!gs.seasonOver && guard++ < 600) {
        gs.confidence = 100;
        final c = gs.pendingCup;
        if (c != null) {
          gs.startCupMatch(c);
          gs.finishCurrent();
          continue;
        }
        gs.startMatch();
        gs.finishCurrent();
      }
      final tb = gs.table;
      final totalGoals = gs.teams.fold<int>(0, (a, t) => a + t.gf);
      final played = gs.teams.fold<int>(0, (a, t) => a + t.played) ~/ 2;
      final draws = gs.teams.fold<int>(0, (a, t) => a + t.drawn) ~/ 2;
      // ignore: avoid_print
      print('DIAG s$s: champ=${tb.first.name} pts=${tb.first.points} last=${tb.last.points} spread=${tb.first.points - tb.last.points} goals/match=${(totalGoals / played).toStringAsFixed(2)} draw%=${(draws * 100 / played).toStringAsFixed(1)} userPos=${gs.position} budget=${gs.user.budget.toStringAsFixed(1)} wages=${gs.weeklyWages.toStringAsFixed(2)} str=${gs.user.strength.toStringAsFixed(1)} topStr=${tb.first.strength.toStringAsFixed(1)}');
      final all = gs.teams.expand((t) => t.squad).toList();
      final avgOv = all.fold<int>(0, (a, p) => a + p.overall) / all.length;
      final avgAge = all.fold<int>(0, (a, p) => a + p.age) / all.length;
      final f = gs.fin;
      // ignore: avoid_print
      print('DIAG s$s econ: income=${f.totalIncome.toStringAsFixed(1)} expense=${f.totalExpense.toStringAsFixed(1)} tickets=${(f.season['tickets'] ?? 0).toStringAsFixed(1)} broadcast=${(f.season['broadcast'] ?? 0).toStringAsFixed(1)} sponsor=${(f.season['sponsor'] ?? 0).toStringAsFixed(1)} prize=${(f.season['prize'] ?? 0).toStringAsFixed(1)} wages=${(f.season['wages'] ?? 0).toStringAsFixed(1)} | avgOv=${avgOv.toStringAsFixed(1)} avgAge=${avgAge.toStringAsFixed(1)} userSquad=${gs.user.squad.length} maxOv=${all.map((p) => p.overall).reduce(max)} p99=${(all.map((p) => p.overall).toList()..sort())[(all.length * 0.99).floor()]}');
      // ignore: avoid_print
      print('DIAG s$s market: free=${gs.freeAgents.length} marketSize=${gs.market.length} fillersInMarket=${gs.market.where((p) => p.filler).length} fakeFree=${gs.market.where((p) => p.free && !gs.freeAgents.any((x) => x.id == p.id)).length} avgAgeFA=${gs.freeAgents.isEmpty ? 0 : (gs.freeAgents.fold<int>(0, (a, p) => a + p.age) / gs.freeAgents.length).toStringAsFixed(1)} young<=20=${all.where((p) => p.age <= 20).length}');
      expect(gs.market.where((p) => p.filler).length, 0);
      expect(gs.teams.every((t) => t.squad.length >= 16), true);
      gs.startNewSeason();
    }
  });
}
