import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/api_football.dart';
import 'package:football_manager/bundled.dart';
import 'package:football_manager/data.dart';
import 'package:football_manager/game_state.dart';
import 'package:football_manager/models.dart';

ApiTeam _team(int id, String name, int rank, int pid) {
  const pos = ['Goalkeeper', 'Goalkeeper', 'Defender', 'Defender', 'Defender', 'Defender', 'Defender', 'Midfielder', 'Midfielder', 'Midfielder', 'Midfielder', 'Midfielder', 'Attacker', 'Attacker', 'Attacker', 'Defender', 'Midfielder', 'Attacker'];
  return ApiTeam(
    id: id,
    name: name,
    rank: rank,
    squadLoaded: true,
    players: [for (var i = 0; i < pos.length; i++) ApiPlayer(id: pid + i, name: '$name لاعب $i', age: 20 + i % 12, position: pos[i])],
  );
}

LeagueData _league(int id, String name, String country, int div, int n) => LeagueData(
      id: id,
      name: name,
      country: country,
      tier: div,
      div: div,
      season: 2025,
      fetchedAt: DateTime(2025),
      teams: [for (var i = 0; i < n; i++) _team(id * 100 + i, '$name فريق ${i + 1}', i + 1, id * 10000 + i * 100)],
    );

List<Team> _pool(Random r, int base, int n, String tag) => [for (var i = 0; i < n; i++) createTeam(r, base + i, '$tag ${i + 1}', 3 + i % 5)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('الانتقال لتدريب نادٍ في دولة أخرى يبدّل الدوري كاملاً ويستمر الموسم التالي', () {
    Bundled.debugCache = [
      _league(2, 'الدوري المغربي', 'المغرب', 1, 16),
      _league(140, 'الدوري الإسباني', 'إسبانيا', 1, 20),
      _league(141, 'الدرجة الثانية الإسبانية', 'إسبانيا', 2, 20),
      _league(39, 'الدوري الإنجليزي', 'إنجلترا', 1, 20),
      _league(135, 'الدوري الإيطالي', 'إيطاليا', 1, 20),
    ];
    addTearDown(() => Bundled.debugCache = null);
    final r = Random(7);
    final teams = [for (var i = 0; i < 16; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final py = Pyramid(
      div: 1,
      world: _pool(r, 1000, 36, 'أوروبي'),
      worldEl: _pool(r, 1100, 36, 'يوروبا'),
      worldCo: _pool(r, 1200, 36, 'مؤتمر'),
      userSlots: 2,
      userSlotsEl: 1,
      userSlotsCo: 1,
      country: 'المغرب',
      leagueId: 2,
    );
    final gs = GameState.fromData(teams, 2, 'الدوري المغربي', pyramid: py);

    void play() {
      var guard = 0;
      while (!gs.seasonOver && guard++ < 600) {
        gs.confidence = 100;
        if (gs.user.budget < 5) gs.user.budget += 20;
        final c = gs.pendingCup;
        if (c != null) {
          gs.startCupMatch(c);
          gs.finishCurrent();
          continue;
        }
        gs.startMatch();
        gs.finishCurrent();
      }
      expect(gs.seasonOver, isTrue);
    }

    play();
    expect(gs.wLeagues.where((l) => l.country == 'إسبانيا'), isNotEmpty);
    final target = gs.wTeams[140]!.keys.first;
    gs.mgrRep = 80;
    final offer = JobOffer(target, 'اختبار', 3, 5, 1, 50, 99, lid: 140, lname: 'إسبانيا • الدوري الإسباني');
    expect(gs.acceptJob(offer), isNull);
    expect(gs.pendingAbroad, 140);
    // الحفظ والتحميل وسط الاتفاق لا يفقدان الوجهة
    final mid = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(mid.pendingAbroad, 140);
    gs.startNewSeason();

    expect(gs.country, 'إسبانيا');
    expect(gs.user.name, target);
    expect(gs.teams.contains(gs.user), isTrue);
    expect(gs.teams.length, greaterThanOrEqualTo(18));
    expect(gs.wLeagues.where((l) => l.country == 'إسبانيا'), isEmpty);
    expect(gs.wLeagues.where((l) => l.country == 'المغرب'), isNotEmpty);
    expect(gs.foreign.keys.where((k) => k >= 1000 && k < 1300), isNotEmpty);
    expect(gs.pendingAbroad, isNull);

    play();
    expect(gs.user.squad.length, greaterThanOrEqualTo(11));
    gs.startNewSeason();
    final g2 = GameState.fromJson(jsonDecode(jsonEncode(gs.toJson())) as Map<String, dynamic>);
    expect(g2.country, 'إسبانيا');
    expect(g2.user.name, target);
  });

  test('الترتيب العالمي يضم لاعبي وأندية ودوريات كل العالم المحاكى', () {
    Bundled.debugCache = [
      _league(2, 'الدوري المغربي', 'المغرب', 1, 16),
      _league(140, 'الدوري الإسباني', 'إسبانيا', 1, 20),
      _league(39, 'الدوري الإنجليزي', 'إنجلترا', 1, 20),
    ];
    addTearDown(() => Bundled.debugCache = null);
    final r = Random(3);
    final teams = [for (var i = 0; i < 16; i++) createTeam(r, i, 'نادي ${i + 1}', 3 + i % 3)];
    final py = Pyramid(
      world: _pool(r, 1000, 36, 'أوروبي'),
      worldEl: _pool(r, 1100, 36, 'يوروبا'),
      worldCo: _pool(r, 1200, 36, 'مؤتمر'),
      userSlots: 2,
      userSlotsEl: 1,
      userSlotsCo: 1,
      country: 'المغرب',
      leagueId: 2,
    );
    final gs = GameState.fromData(teams, 2, 'الدوري المغربي', pyramid: py);
    for (var i = 0; i < 6; i++) {
      final c = gs.pendingCup;
      if (c != null) {
        gs.startCupMatch(c);
        gs.finishCurrent();
        continue;
      }
      gs.startMatch();
      gs.finishCurrent();
    }
    final ps = gs.worldPlayers();
    expect(ps.where((w) => w.country == 'إسبانيا'), isNotEmpty);
    expect(ps.where((w) => w.country == 'إنجلترا'), isNotEmpty);
    expect(ps.where((w) => w.team == gs.user), isNotEmpty);
    expect(ps.where((w) => w.p.goals > 0), isNotEmpty);
    final lg = gs.worldLeagueTable();
    expect(lg.length, greaterThanOrEqualTo(3));
    final info = gs.worldClubInfo();
    expect(info[gs.user.name]!.pos, greaterThan(0));
    expect(info.values.where((i) => i.country == 'إسبانيا'), isNotEmpty);
  });
}
