import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/calendar.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/engine.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';
import 'package:football_manager/importer.dart';
import 'package:football_manager/api_football.dart';

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
      expect(gs.ceremony, isNotNull);
      final cer = (gs.ceremony!['a'] as List).map((a) => a['id']).toList();
      // ignore: avoid_print
      print('DIAG s$s awards: $cer winners=${(gs.ceremony!['a'] as List).take(4).map((a) => (a['nom'] as List).first['n']).toList()} mine=${gs.myAwardWins().length}');
      gs.claimAwardRewards();
      gs.startNewSeason();
      expect(gs.ceremony, isNull);
    }
  });

  test('عروض التدريب والاستقالة وتغيير النادي', () {
    final r = Random(5);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 5, 'تجريبي');
    var seen = 0;
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
      seen += gs.jobOffers.length;
    }
    expect(gs.jobOffers.length, greaterThan(0), reason: 'عروض نهاية الموسم');
    // عرض داخل الدوري أثناء الموسم يُنفَّذ فوراً بعد الاستقالة
    gs.resign();
    expect(gs.resigned, true);
    expect(gs.fired, false, reason: "الاستقالة لا تجمّد اللعبة");
    final jobs = gs.availableJobs;
    expect(jobs.isNotEmpty, true);
    final target = jobs.first.club;
    final err = gs.acceptJob(jobs.first);
    expect(err, anyOf(isNull, isA<String>()));
    // ignore: avoid_print
    print('DIAG jobs: seen=$seen accept err=$err now=${gs.user.name} target=$target fired=${gs.fired} pending=${gs.pendingJob}');
    // موسم جديد بعد الاتفاق
    var g2 = 0;
    while (!gs.seasonOver && g2++ < 600) {
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
    gs.startNewSeason();
    expect(gs.teams.contains(gs.user), true);
  });

  test('المتابعة بلا نادٍ بعد الإقالة: موسم كامل ثم موسم جديد', () {
    final r = Random(9);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 3, 'تجريبي');
    gs.fired = true;
    var guard = 0;
    while (!gs.seasonOver && guard++ < 200) {
      gs.spectateRound();
    }
    expect(gs.seasonOver, true, reason: 'الموسم ينتهي رغم الإقالة');
    expect(gs.fired, true);
    expect(teams.every((t) => t.won + t.drawn + t.lost == 38), true, reason: 'كل الفرق لعبت كامل جولاتها');
    gs.startNewSeason();
    expect(gs.seasonOver, false);
    expect(gs.week, 0);
  });

  test('جوائز فرانس فوتبول/الفيفا/الولد الذهبي بمواعيدها الحقيقية', () {
    final r = Random(11);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 4, 'تجريبي');
    var guard = 0;
    while (!gs.seasonOver && guard++ < 800) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
    }
    expect(gs.seasonOver, true);
    final ids = [for (final a in (gs.ceremony!['a'] as List)) a['id']];
    expect(ids.contains('bd'), false, reason: 'الكرة الذهبية لا تُعلن نهاية الموسم');
    expect(gs.pendingAwards.any((a) => a['id'] == 'bd'), true);
    expect(gs.pendingAwards.any((a) => a['id'] == 'yashin'), true);
    gs.startNewSeason();
    final seen = <String>{};
    guard = 0;
    while (!gs.seasonOver && guard++ < 800) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
      final ev = gs.ceremony?['ev'];
      if (ev != null) seen.add('$ev@${GameCalendar.fmt(GameCalendar.weekStart(gs.season, gs.week - 1))}');
    }
    // ignore: avoid_print
    print('DIAG awards events: $seen pending=${gs.pendingAwards.length}');
    expect(seen.any((e) => e.startsWith('ballon')), true);
    expect(seen.any((e) => e.startsWith('fifa')), true);
  });

  test('معايرة إحصاءات المباراة (تسديدات، بطاقات، ركنيات...)', () {
    final r = Random(11);
    const n = 3000;
    var shots = 0, sot = 0, corners = 0, fouls = 0, off = 0, passes = 0, passOk = 0, goals = 0;
    var yel = 0, red = 0, inj = 0, pen = 0, penGoal = 0, vars = 0;
    double xg = 0, poss = 0;
    var maxPoss = 0;
    for (var k = 0; k < n; k++) {
      final h = createTeam(r, 0, 'H', 3 + r.nextInt(3));
      final a = createTeam(r, 1, 'A', 3 + r.nextInt(3));
      final m = MatchSim(h, a, random: r)..simulateAll();
      for (final s in [m.home, m.away]) {
        shots += s.shots;
        sot += s.onTarget;
        corners += s.corners;
        fouls += s.fouls;
        off += s.offsides;
        passes += s.passes;
        passOk += s.passOk;
        goals += s.goals;
        xg += s.xg;
      }
      poss += (m.homePoss - 50).abs();
      if (m.homePoss > maxPoss) maxPoss = m.homePoss;
      for (final e in m.events) {
        if (e.type == 'yellow') yel++;
        if (e.type == 'red') red++;
        if (e.type == 'injury') inj++;
        if (e.type == 'penalty') pen++;
        if (e.text.contains('VAR')) vars++;
      }
    }
    String f(num v) => (v / n).toStringAsFixed(2);
    // ignore: avoid_print
    print('CALIB per-match: goals=${f(goals)} xg=${f(xg)} shots=${f(shots)} onTarget=${f(sot)} corners=${f(corners)} fouls=${f(fouls)} offsides=${f(off)} yellows=${f(yel)} reds=${f(red)} injuries=${f(inj)} pens=${f(pen)} var=${f(vars)} passes=${f(passes)} passAcc=${(passOk * 100 / passes).toStringAsFixed(1)}% possGap=${f(poss)} maxPoss=$maxPoss');
    // مراجع واقعية تقريبية للمباراة الواحدة (الفريقان معاً)
    expect(goals / n, inInclusiveRange(2.3, 3.1));
    expect(shots / n, inInclusiveRange(18, 32));
    expect(yel / n, inInclusiveRange(2.5, 5.0));
    expect(red / n, inInclusiveRange(0.03, 0.22));
    expect(corners / n, inInclusiveRange(7, 13));
  });

  test('تقييمات الأداء من أحداث المباراة وطقس وحكم', () {
    final r = Random(61);
    final rs = <double>[];
    final w = <String>{};
    var var_ = 0;
    for (var i = 0; i < 120; i++) {
      final h = createTeam(r, 1, 'أ$i', 4), a = createTeam(r, 2, 'ب$i', 3);
      final sim = MatchSim(h, a, random: r)..simulateAll();
      w.add(sim.weather);
      var_ += sim.events.where((e) => e.text.contains('VAR')).length;
      for (final s in [sim.home, sim.away]) {
        rs.addAll(s.ratings.values);
      }
    }
    final m = rs.reduce((a, b) => a + b) / rs.length;
    final sd = sqrt(rs.fold<double>(0, (a, b) => a + (b - m) * (b - m)) / rs.length);
    // ignore: avoid_print
    print('DIAG ratings mean=${m.toStringAsFixed(2)} sd=${sd.toStringAsFixed(2)} weathers=$w var=$var_');
    expect(m > 5.8 && m < 7.3, true, reason: 'متوسط التقييم $m');
    expect(sd > 0.3, true, reason: 'تباين التقييمات $sd');
    expect(w.length >= 2, true);
  });

  test('مشاريع المنشآت: مدة وتسريع وحفظ', () {
    final r = Random(5);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 2, 'تجريبي');
    gs.user.budget = 500;
    final cap0 = gs.stadiumCapacity;
    expect(gs.startProject('stadium'), null);
    expect(gs.startProject('stadium') != null, true, reason: 'مشروع ثانٍ لنفس المنشأة مرفوض');
    expect(gs.startProject('medical'), null);
    expect(gs.startProject('training'), null);
    expect(gs.startProject('academy') != null, true, reason: 'حد 3 فرق بناء');
    expect(gs.stadiumCapacity < cap0, true, reason: 'السعة تنخفض أثناء البناء');
    final g2 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(gs.toJson())) as Map));
    expect(g2.projects.length, 3);
    expect(g2.projects.first.left, gs.projects.first.left);
    expect(gs.rushProject('medical'), null);
    var guard = 0;
    while (gs.projects.isNotEmpty && guard++ < 60) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
    }
    expect(gs.projects.isEmpty, true, reason: 'المشاريع تنتهي');
    expect(gs.user.stadium, 2);
    expect(gs.user.medical, 2);
    expect(gs.stadiumCapacity > cap0, true);
  });

  test('صعود وهبوط في دوريات العالم', () {
    final r = Random(33);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 2, 'تجريبي');
    final hi = [for (var i = 0; i < 18; i++) 'Hi $i'], lo = [for (var i = 0; i < 18; i++) 'Lo $i'];
    gs.wLeagues.add(WorldLeague(950, 'دوري أول', 'بلدx', 1, hi, [for (var i = 0; i < 18; i++) 80.0 - i]));
    gs.wLeagues.add(WorldLeague(951, 'الدرجة الثانية', 'بلدx', 2, lo, [for (var i = 0; i < 18; i++) 65.0 - i]));
    var guard = 0;
    while (!gs.seasonOver && guard++ < 800) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
    }
    final up = gs.wLeagues.firstWhere((l) => l.id == 950), low = gs.wLeagues.firstWhere((l) => l.id == 951);
    final loOrd = low.order, hiOrd = up.order;
    final goUp = [for (final i in loOrd.take(3)) low.names[i]], goDown = [for (final i in hiOrd.sublist(15)) up.names[i]];
    gs.startNewSeason();
    final up2 = gs.wLeagues.firstWhere((l) => l.id == 950), low2 = gs.wLeagues.firstWhere((l) => l.id == 951);
    expect(up2.n, 18);
    expect(low2.n, 18);
    for (final t in goUp) {
      expect(up2.names.contains(t), true, reason: '$t صعد');
    }
    for (final t in goDown) {
      expect(low2.names.contains(t), true, reason: '$t هبط');
      expect(up2.names.contains(t), false);
    }
    expect(gs.worldMoves['950|1']?.length, 6);
    final g2 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(gs.toJson())) as Map));
    expect(g2.worldMoves['950|1']?.length, 6);
  });

  test('دوريات العالم تُلعب آلياً وتُسجَّل الألقاب في خزائن الأندية', () {
    final r = Random(21);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 2, 'تجريبي');
    final names = [for (var i = 0; i < 18; i++) 'Club $i'];
    gs.wLeagues.add(WorldLeague(900, 'دوري تجريبي', 'بلد', 1, names, [for (var i = 0; i < 18; i++) 80.0 - i]));
    // الدوري التجريبي الأول يُلعب بالمحرك الكامل بلاعبين حقيقيين
    final rr = Random(5);
    final ld = LeagueData(id: 900, name: 'دوري تجريبي', country: 'بلد', tier: 1, season: 2023, fetchedAt: DateTime(2023), teams: [
      for (var i = 0; i < 18; i++)
        ApiTeam(id: i, name: 'Club $i', rank: i + 1, squadLoaded: true, players: [
          for (var k = 0; k < 20; k++)
            ApiPlayer(id: i * 100 + k, name: 'P$i-$k', age: 20 + k % 12, position: k < 2 ? 'Goalkeeper' : k < 8 ? 'Defender' : k < 15 ? 'Midfielder' : 'Attacker', ov: 78 - i + rr.nextInt(6), value: 20.0 - i),
        ]),
    ]);
    gs.wTeams[900] = worldTeamsOf(ld, rr);
    gs.wLeagues.add(WorldLeague(901, 'دوري فردي', 'بلد', 1, names.take(15).toList(), [for (var i = 0; i < 15; i++) 70.0 - i]));
    var guard = 0;
    while (!gs.seasonOver && guard++ < 800) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
    }
    final l = gs.wLeagues.first;
    expect(l.round > 0, true, reason: 'الدوري الآخر يتقدم أسبوعياً');
    final exp = (gs.week * l.totalRounds / gs.rounds.length).floor();
    expect((l.round - exp).abs() <= 3, true, reason: 'نفس رتم موسم المستخدم: round=${l.round} exp=$exp');
    final gp = l.st.fold<int>(0, (a, e) => a + e[0]) / 2, gf = l.st.fold<int>(0, (a, e) => a + e[4]);
    // ignore: avoid_print
    print('DIAG world engine: matches=$gp goals/match=${(gf / gp).toStringAsFixed(2)} top=${l.names[l.order.first]}');
    expect(gf / gp > 1.5 && gf / gp < 4.5, true, reason: 'معدل أهداف واقعي بالمحرك الكامل');
    // سلامة الجدول: لا يلعب فريق مرتين في جولة
    for (var rr = 0; rr < l.totalRounds; rr++) {
      final ps = l.pairs(rr);
      final seen = <int>{};
      for (final (a, b) in ps) {
        expect(seen.add(a) && seen.add(b), true);
      }
    }
    final champ0 = l.names[l.order.first];
    final ageB = gs.wTeams[900]!['Club 0']!.squad.fold<int>(0, (a, p) => a + p.age);
    gs.startNewSeason();
    expect(gs.wTeams[900]!['Club 0']!.squad.fold<int>(0, (a, p) => a + p.age) > ageB, true, reason: 'لاعبو العالم يكبرون');
    expect(gs.worldChamps.containsKey('900|1'), true);
    expect(gs.clubHonours[champ0]?.isNotEmpty ?? false, true, reason: 'بطل الدوري يُسجَّل في خزينته');
    expect(gs.wLeagues.first.round, 0);
    // حفظ وتحميل
    final j = gs.toJson();
    final g2 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(j)) as Map));
    expect(g2.wLeagues.length, 2);
    gs.sellOns['77'] = 0.1;
    final g3 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(gs.toJson())) as Map));
    expect(g3.sellOns['77'], 0.1);
    expect(g2.clubHonours.isNotEmpty, true);
  });

  test('تدريب المنتخب: استدعاء ومباراة بالمحرك الكامل وتسجيل النتيجة', () {
    final r = Random(33);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    for (final t in teams) {
      for (final p in t.squad) {
        p.nat = 'إسبانيا';
      }
    }
    final gs = GameState.fromData(teams, 2, 'تجريبي');
    final before = gs.user.squad.fold<int>(0, (a, p) => a + p.goals + p.apps);
    final off = JobOffer('إسبانيا', 'اختبار', 2, 5, 0, 0, 10);
    expect(gs.acceptNatOffer(off), null);
    expect(gs.fired, true, reason: 'تدريب المنتخب يعني ترك النادي');
    expect(gs.natCalled.length >= 14, true);
    expect(gs.acceptNatOffer(JobOffer('فرنسا', 'x', 2, 5, 0, 0, 10)) != null, true, reason: 'منتخب واحد فقط');
    for (var i = 0; i < 6 && gs.natJobLog.isEmpty; i++) {
      gs.playIntlBreak();
      gs.nat.winDone.clear();
    }
    gs.ensureNat();
    final opp = gs.nat.pts.keys.firstWhere((k) => k != 'إسبانيا');
    expect(gs.natFriendly(opp), null);
    expect(gs.natFriendly(opp) != null, true, reason: 'ودية واحدة بالأسبوع');
    expect(gs.natJobLog.isNotEmpty, true);
    // ignore: avoid_print
    print('DIAG natjob: log=${gs.natJobLog.length} first=${gs.natJobLog.isEmpty ? '-' : gs.natJobLog.first}');
    final after = gs.user.squad.fold<int>(0, (a, p) => a + p.goals + p.apps);
    expect(after, before, reason: 'مباريات المنتخب لا تغيّر إحصاءات النادي');
    final rec = gs.natRecord('إسبانيا');
    expect(rec.w + rec.d + rec.l >= 0, true);
    final j = gs.toJson();
    final g2 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(j)) as Map));
    expect(g2.natJob, 'إسبانيا');
    gs.leaveNatJob();
    expect(gs.natJob, null);
  });

  test('تذاكر المدرجات وبطاقات الموسم والحملات', () {
    final r = Random(7);
    final teams = [for (var i = 0; i < 20; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final gs = GameState.fromData(teams, 2, 'تجريبي');
    gs.user.budget = 200;
    final t0 = gs.ticketForecast();
    expect(t0.attendance <= t0.capacity, true);
    expect(t0.revenue > 0.05 && t0.revenue < 6, true, reason: 'إيراد ${t0.revenue}');
    for (final st in t0.stands) {
      expect(st.att >= st.subs && st.att <= st.cap, true);
    }
    gs.standMult[0] = 2.0;
    final t1 = gs.ticketForecast();
    expect(t1.stands[0].fill < t0.stands[0].fill, true, reason: 'السعر الأعلى يقلل الامتلاء');
    gs.standMult[0] = 1.0;
    final sug = gs.suggestedMults();
    expect(sug.every((m) => m >= 0.6 && m <= 1.5), true);
    gs.seasonMult = 1.3;
    final lowSubs = gs.ticketForecast().subs;
    gs.seasonMult = 1.0;
    expect(lowSubs < gs.ticketForecast().subs, true, reason: 'رفع سعر البطاقات يقلل المشتركين');
    gs.standMult[2] = 1.15;
    final g2 = GameState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(gs.toJson())) as Map));
    expect(g2.standMult[2], 1.15);
    expect(gs.startCampaign('membership'), null);
    expect(gs.startCampaign('membership') != null, true);
    final f0 = gs.fans;
    var guard = 0;
    while (gs.campaigns.isNotEmpty && guard++ < 30) {
      gs.confidence = 100;
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishMatchday();
    }
    expect(gs.campaigns.isEmpty, true);
    expect(gs.fans >= f0 - 3, true);
  });
}
