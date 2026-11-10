import 'engine.dart';
import 'models.dart';

/// ملخص مباراة منتهية: يُحفظ مع اللعبة لعرضه في الرئيسية وصفحة «ملخص المباراة»
class LastMatch {
  final String comp; // اسم البطولة
  final int round; // رقم الجولة (من 1)
  final int homeId, awayId;
  final String homeName, awayName;
  final int hg, ag;
  final bool userHome;
  final List<Map<String, dynamic>> events; // {m, t, h, a, b, s}
  final Map<String, List<num>> stats; // key → [home, away]
  final List<Map<String, dynamic>> ratings; // {id, n, r, h, p}
  final Map<String, dynamic>? mom; // {id, n, r, nat, g, a, h}

  LastMatch({
    required this.comp,
    required this.round,
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
    required this.hg,
    required this.ag,
    required this.userHome,
    required this.events,
    required this.stats,
    required this.ratings,
    this.mom,
  });

  int get userGoals => userHome ? hg : ag;
  int get oppGoals => userHome ? ag : hg;
  String get result => userGoals > oppGoals ? 'W' : (userGoals < oppGoals ? 'L' : 'D');

  /// كل الأرقام من تتبّع المحرك لحظة بلحظة (الاستحواذ، التسديدات، التمريرات، التسلل، xG)
  static LastMatch fromSim(MatchSim s, {required String comp, required int round, required bool userHome}) {
    final hp = s.homePoss;
    final ev = <Map<String, dynamic>>[];
    var hs = 0, as = 0;
    for (final e in s.events) {
      if (e.type == 'goal') {
        final m = RegExp(r'^⚽ هدف(?: من ركلة جزاء)?! (.+?)(?: \(تمريرة (.+)\))?$').firstMatch(e.text);
        if (e.home) {
          hs++;
        } else {
          as++;
        }
        ev.add({'m': e.minute, 't': 'goal', 'h': e.home, 'a': m?.group(1) ?? e.text, 'b': m?.group(2), 's': '$hs - $as'});
      } else if (e.type == 'yellow') {
        ev.add({'m': e.minute, 't': 'yellow', 'h': e.home, 'a': e.text.replaceFirst('🟨 إنذار للاعب ', '')});
      } else if (e.type == 'red') {
        final m = RegExp(r': (.+?)!').firstMatch(e.text);
        ev.add({'m': e.minute, 't': 'red', 'h': e.home, 'a': m?.group(1) ?? e.text});
      } else if (e.type == 'sub') {
        final m = RegExp(r'يدخل (.+) بدلاً من (.+)$').firstMatch(e.text);
        ev.add({'m': e.minute, 't': 'sub', 'h': e.home, 'a': m?.group(1) ?? e.text, 'b': m?.group(2)});
      }
    }
    num acc(Side x) => x.passes == 0 ? 0 : (100 * x.passOk / x.passes).round();
    num xg(Side x) => (x.xg * 10).round() / 10;
    final stats = <String, List<num>>{
      'poss': [hp, 100 - hp],
      'shots': [s.home.shots, s.away.shots],
      'target': [s.home.onTarget, s.away.onTarget],
      'passes': [s.home.passes, s.away.passes],
      'acc': [acc(s.home), acc(s.away)],
      'corners': [s.home.corners, s.away.corners],
      'fouls': [s.home.fouls, s.away.fouls],
      'offside': [s.home.offsides, s.away.offsides],
      'xg': [xg(s.home), xg(s.away)],
    };

    final rt = <Map<String, dynamic>>[];
    for (final side in [s.home, s.away]) {
      side.ratings.forEach((p, r) => rt.add({'id': p.id, 'n': p.name, 'r': (r * 10).round() / 10, 'h': side.isHome, 'p': p.pos.index}));
    }
    rt.sort((a, b) => (b['r'] as num).compareTo(a['r'] as num));
    Map<String, dynamic>? mom;
    final mm = s.manOfMatch;
    if (mm != null) {
      final p = mm.$1;
      final g = ev.where((e) => e['t'] == 'goal' && e['a'] == p.name).length;
      final a = ev.where((e) => e['t'] == 'goal' && e['b'] == p.name).length;
      mom = {'id': p.id, 'n': p.name, 'r': (mm.$3 * 10).round() / 10, 'nat': p.nat, 'g': g, 'a': a, 'h': mm.$2.isHome};
    }
    return LastMatch(
      comp: comp,
      round: round,
      homeId: s.home.team.id,
      awayId: s.away.team.id,
      homeName: s.home.team.name,
      awayName: s.away.team.name,
      hg: s.home.goals,
      ag: s.away.goals,
      userHome: userHome,
      events: ev,
      stats: stats,
      ratings: rt,
      mom: mom,
    );
  }

  Map<String, dynamic> toJson() => {
        'c': comp,
        'r': round,
        'hi': homeId,
        'ai': awayId,
        'hn': homeName,
        'an': awayName,
        'hg': hg,
        'ag': ag,
        'uh': userHome,
        'ev': events,
        'st': stats,
        'rt': ratings,
        'mom': mom,
      };

  factory LastMatch.fromJson(Map<String, dynamic> j) => LastMatch(
        comp: j['c'] as String,
        round: j['r'] as int,
        homeId: j['hi'] as int,
        awayId: j['ai'] as int,
        homeName: j['hn'] as String,
        awayName: j['an'] as String,
        hg: j['hg'] as int,
        ag: j['ag'] as int,
        userHome: j['uh'] as bool,
        events: [for (final e in j['ev'] as List) Map<String, dynamic>.from(e as Map)],
        stats: {for (final e in (j['st'] as Map).entries) e.key as String: (e.value as List).cast<num>()},
        ratings: [for (final e in j['rt'] as List) Map<String, dynamic>.from(e as Map)],
        mom: j['mom'] == null ? null : Map<String, dynamic>.from(j['mom'] as Map),
      );
}
