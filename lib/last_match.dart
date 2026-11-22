import 'engine.dart';
import 'models.dart';

/// ملخص مباراة منتهية: يُحفظ مع اللعبة لعرضه في الرئيسية وصفحة «ملخص المباراة»
class LastMatch {
  final String comp; // اسم البطولة
  final int round; // رقم الجولة (من 1)
  final String label; // وصف الجولة أو الدور (الجولة 9، ربع النهائي…)
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
    this.label = '',
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

  num _st(String k, bool user) {
    final v = stats[k];
    if (v == null || v.length < 2) return 0;
    return userHome == user ? v[0] : v[1];
  }

  /// تحليل المباراة من وجهة نظر مدرب المستخدم: جمل قصيرة مبنية على الأرقام الفعلية
  List<String> analysis() {
    final out = <String>[];
    final g = userGoals, og = oppGoals;
    final xu = _st('xg', true), xo = _st('xg', false);
    final poss = _st('poss', true).round();
    final su = _st('shots', true).round(), so = _st('shots', false).round();
    final tu = _st('target', true).round();
    if (g > og && xu + 0.8 <= xo) {
      out.add('فوز محظوظ: الفرص الأخطر كانت لخصمك (xG ${xu.toStringAsFixed(1)} مقابل ${xo.toStringAsFixed(1)})');
    } else if (g < og && xu >= xo + 0.8) {
      out.add('خسارة قاسية: كنت الأخطر (xG ${xu.toStringAsFixed(1)} مقابل ${xo.toStringAsFixed(1)}) لكن الكرة لم تدخل');
    } else if (g > og) {
      out.add('فوز مستحق: صنعت فرصاً أكثر وسجّلت منها');
    } else if (g < og) {
      out.add('خسارة منطقية: خصمك صنع فرصاً أخطر (xG ${xo.toStringAsFixed(1)} مقابل ${xu.toStringAsFixed(1)})');
    } else {
      out.add('تعادل عادل: الفرص متقاربة بين الفريقين');
    }
    if (poss >= 58 && su <= so) {
      out.add('سيطرة بلا أنياب: استحواذ $poss% لكن تسديداتك $su مقابل $so');
    } else if (poss <= 42 && g > og) {
      out.add('فوز بالمرتدات: استحواذ $poss% فقط لكنك كنت أخطر في الفرص');
    } else if (poss >= 58) {
      out.add('فرضت سيطرتك على الكرة باستحواذ $poss%');
    }
    if (su >= 8 && tu * 3 < su) {
      out.add('التسديد غير دقيق: $tu على المرمى من أصل $su');
    }
    final reds = events.where((e) => e['t'] == 'red').toList();
    final myRed = reds.where((e) => (e['h'] as bool) == userHome).length;
    final oppRed = reds.length - myRed;
    if (myRed > 0) out.add('اللعب بنقص عددي أثّر في المباراة بعد الطرد');
    if (oppRed > 0) out.add('تفوّق عددي بعد طرد لاعب من الخصم');
    final mine = ratings.where((r) => (r['h'] as bool) == userHome).toList();
    if (mine.isNotEmpty) {
      final best = mine.first, worst = mine.last;
      out.add('أفضل لاعبيك: ${best['n']} (${best['r']})');
      if ((worst['r'] as num) <= 5.8 && worst != best) out.add('الأضعف أداءً: ${worst['n']} (${worst['r']})');
    }
    return out.take(5).toList();
  }

  int get userGoals => userHome ? hg : ag;
  int get oppGoals => userHome ? ag : hg;
  String get result => userGoals > oppGoals ? 'W' : (userGoals < oppGoals ? 'L' : 'D');

  /// كل الأرقام من تتبّع المحرك لحظة بلحظة (الاستحواذ، التسديدات، التمريرات، التسلل، xG)
  static LastMatch fromSim(MatchSim s, {required String comp, required int round, String label = '', required bool userHome}) {
    final hp = s.homePoss;
    final ev = <Map<String, dynamic>>[];
    var hs = 0, as = 0;
    for (final e in s.events) {
      if (e.type == 'goal') {
        final m = RegExp(r'^⚽ هدف(?: من ركلة جزاء| من ركنية| من ركلة حرة مباشرة)?! (.+?)(?: \(تمريرة (.+)\))?$').firstMatch(e.text);
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
      'big': [s.home.bigChances, s.away.bigChances],
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
      label: label,
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
        'rl': label,
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
        label: (j['rl'] as String?) ?? '',
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
