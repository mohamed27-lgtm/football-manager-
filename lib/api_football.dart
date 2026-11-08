import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final bool quota;
  ApiException(this.message, {this.quota = false});
  @override
  String toString() => message;
}

class LeagueInfo {
  final int id;
  final String name;
  final String country;
  final int tier; // 1 قوي، 2 متوسط، 3 أضعف (يحدد مستوى تقييم اللاعبين)
  const LeagueInfo(this.id, this.name, this.country, this.tier);
}

/// معرّفات دوريات API-Football (يمكنك إضافة أي دوري آخر هنا)
const leagueCatalog = <LeagueInfo>[
  LeagueInfo(39, 'الدوري الإنجليزي الممتاز', 'إنجلترا', 1),
  LeagueInfo(140, 'الدوري الإسباني', 'إسبانيا', 1),
  LeagueInfo(135, 'الدوري الإيطالي', 'إيطاليا', 1),
  LeagueInfo(78, 'الدوري الألماني', 'ألمانيا', 1),
  LeagueInfo(61, 'الدوري الفرنسي', 'فرنسا', 1),
  LeagueInfo(307, 'الدوري السعودي', 'السعودية', 2),
  LeagueInfo(200, 'البطولة المغربية', 'المغرب', 3),
  LeagueInfo(233, 'الدوري المصري', 'مصر', 3),
  LeagueInfo(94, 'الدوري البرتغالي', 'البرتغال', 2),
  LeagueInfo(88, 'الدوري الهولندي', 'هولندا', 2),
  LeagueInfo(203, 'الدوري التركي', 'تركيا', 2),
  LeagueInfo(144, 'الدوري البلجيكي', 'بلجيكا', 2),
  LeagueInfo(40, 'تشامبيونشيب الإنجليزي', 'إنجلترا', 2),
  LeagueInfo(253, 'الدوري الأمريكي', 'أمريكا', 2),
  LeagueInfo(71, 'الدوري البرازيلي', 'البرازيل', 2),
  LeagueInfo(128, 'الدوري الأرجنتيني', 'الأرجنتين', 2),
  LeagueInfo(262, 'الدوري المكسيكي', 'المكسيك', 2),
  LeagueInfo(186, 'الدوري الجزائري', 'الجزائر', 3),
  LeagueInfo(202, 'الدوري التونسي', 'تونس', 3),
  LeagueInfo(301, 'الدوري الإماراتي', 'الإمارات', 3),
  LeagueInfo(305, 'دوري نجوم قطر', 'قطر', 3),
  LeagueInfo(179, 'الدوري الإسكتلندي', 'إسكتلندا', 3),
  LeagueInfo(218, 'الدوري النمساوي', 'النمسا', 3),
  LeagueInfo(207, 'الدوري السويسري', 'سويسرا', 3),
  LeagueInfo(119, 'الدوري الدنماركي', 'الدنمارك', 3),
  LeagueInfo(113, 'الدوري السويدي', 'السويد', 3),
  LeagueInfo(103, 'الدوري النرويجي', 'النرويج', 3),
  LeagueInfo(106, 'الدوري البولندي', 'بولندا', 3),
  LeagueInfo(197, 'الدوري اليوناني', 'اليونان', 3),
  LeagueInfo(235, 'الدوري الروسي', 'روسيا', 3),
  LeagueInfo(333, 'الدوري الأوكراني', 'أوكرانيا', 3),
  LeagueInfo(345, 'الدوري التشيكي', 'التشيك', 3),
  LeagueInfo(98, 'الدوري الياباني', 'اليابان', 3),
  LeagueInfo(292, 'الدوري الكوري', 'كوريا الجنوبية', 3),
  LeagueInfo(169, 'الدوري الصيني', 'الصين', 3),
];

class ApiPlayer {
  final int id;
  final String name;
  final int? age;
  final String position;
  final String? photo;
  final int? number;
  // بيانات Transfermarkt الحقيقية (اختيارية)
  final String? sub, nat, foot;
  final double? value; // مليون يورو
  final int? ov, pot, contract, height;
  const ApiPlayer({
    required this.id,
    required this.name,
    this.age,
    this.position = '',
    this.photo,
    this.number,
    this.sub,
    this.nat,
    this.foot,
    this.value,
    this.ov,
    this.pot,
    this.contract,
    this.height,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'n': name, 'a': age, 'p': position, 'ph': photo, 'no': number,
        'sub': sub, 'nat': nat, 'ft': foot, 'v': value, 'ov': ov, 'pot': pot, 'ct': contract, 'h': height,
      };

  factory ApiPlayer.fromJson(Map<String, dynamic> j) => ApiPlayer(
        id: j['id'] as int,
        name: j['n'] as String,
        age: j['a'] as int?,
        position: (j['p'] as String?) ?? '',
        photo: j['ph'] as String?,
        number: j['no'] as int?,
        sub: j['sub'] as String?,
        nat: j['nat'] as String?,
        foot: j['ft'] as String?,
        value: (j['v'] as num?)?.toDouble(),
        ov: (j['ov'] as num?)?.toInt(),
        pot: (j['pot'] as num?)?.toInt(),
        contract: (j['ct'] as num?)?.toInt(),
        height: (j['h'] as num?)?.toInt(),
      );
}

class ApiTeam {
  final int id;
  final String name;
  final String? logo;
  final String? venue;
  int rank;
  int points;
  List<ApiPlayer> players;
  bool squadLoaded;

  ApiTeam({
    required this.id,
    required this.name,
    this.logo,
    this.venue,
    this.rank = 99,
    this.points = 0,
    List<ApiPlayer>? players,
    this.squadLoaded = false,
  }) : players = players ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'venue': venue,
        'rank': rank,
        'pts': points,
        'loaded': squadLoaded,
        'players': [for (final p in players) p.toJson()],
      };

  factory ApiTeam.fromJson(Map<String, dynamic> j) => ApiTeam(
        id: j['id'] as int,
        name: j['name'] as String,
        logo: j['logo'] as String?,
        venue: j['venue'] as String?,
        rank: j['rank'] as int,
        points: j['pts'] as int,
        squadLoaded: j['loaded'] as bool,
        players: [
          for (final p in j['players'] as List)
            ApiPlayer.fromJson(p as Map<String, dynamic>)
        ],
      );
}

class LeagueData {
  final int id;
  final String name;
  final String country;
  final int tier;
  final int div; // 1 الأولى، 2 الثانية، 3 الثالثة
  final int season;
  final List<ApiTeam> teams;
  final DateTime fetchedAt;

  LeagueData({
    required this.id,
    required this.name,
    required this.country,
    required this.tier,
    this.div = 1,
    required this.season,
    required this.teams,
    required this.fetchedAt,
  });

  int get loaded => teams.where((t) => t.squadLoaded).length;
  bool get complete => teams.isNotEmpty && loaded == teams.length;
  int get playerCount => teams.fold(0, (a, t) => a + t.players.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'tier': tier,
        'div': div,
        'season': season,
        'at': fetchedAt.toIso8601String(),
        'teams': [for (final t in teams) t.toJson()],
      };

  factory LeagueData.fromJson(Map<String, dynamic> j) => LeagueData(
        id: j['id'] as int,
        name: j['name'] as String,
        country: j['country'] as String,
        tier: j['tier'] as int,
        div: (j['div'] as int?) ?? 1,
        season: j['season'] as int,
        fetchedAt: DateTime.tryParse((j['at'] as String?) ?? '') ?? DateTime.now(),
        teams: [
          for (final t in j['teams'] as List)
            ApiTeam.fromJson(t as Map<String, dynamic>)
        ],
      );
}

/// عميل API-Football v3 مع احترام حدّ 10 طلبات/دقيقة في الخطة المجانية
class ApiFootball {
  final String key;
  final http.Client _client = http.Client();
  int? dailyRemaining;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  ApiFootball(this.key);

  Future<List<dynamic>> _get(String path, Map<String, String> q, {int retry = 1}) async {
    const spacing = Duration(milliseconds: 6500);
    final gap = DateTime.now().difference(_last);
    if (gap < spacing) await Future.delayed(spacing - gap);
    _last = DateTime.now();

    final http.Response r;
    try {
      r = await _client
          .get(Uri.https('v3.football.api-sports.io', path, q),
              headers: {'x-apisports-key': key})
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال');
    } catch (_) {
      throw ApiException('تعذّر الاتصال بالإنترنت');
    }

    final rem = r.headers['x-ratelimit-requests-remaining'];
    if (rem != null) dailyRemaining = int.tryParse(rem);
    if (r.statusCode != 200) {
      throw ApiException('خطأ من الخادم (${r.statusCode})');
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final errs = j['errors'];
    String? err;
    if (errs is Map && errs.isNotEmpty) {
      err = errs.entries.map((e) => '${e.key}: ${e.value}').join(' • ');
    } else if (errs is List && errs.isNotEmpty) {
      err = errs.join(' • ');
    }
    if (err != null) {
      final low = err.toLowerCase();
      if (low.contains('ratelimit') && retry > 0) {
        await Future.delayed(const Duration(seconds: 62));
        return _get(path, q, retry: retry - 1);
      }
      throw ApiException(err, quota: low.contains('day') || low.contains('limit'));
    }
    return (j['response'] as List?) ?? [];
  }

  Future<List<ApiTeam>> teams(int league, int season) async {
    final r = await _get('/teams', {'league': '$league', 'season': '$season'});
    return [
      for (final e in r)
        ApiTeam(
          id: e['team']['id'] as int,
          name: e['team']['name'] as String,
          logo: e['team']['logo'] as String?,
          venue: (e['venue'] as Map?)?['name'] as String?,
        )
    ];
  }

  Future<Map<int, (int, int)>> standings(int league, int season) async {
    final r = await _get('/standings', {'league': '$league', 'season': '$season'});
    final out = <int, (int, int)>{};
    if (r.isEmpty) return out;
    final groups = (r[0]['league']['standings'] as List?) ?? [];
    for (final g in groups) {
      for (final row in g as List) {
        out[row['team']['id'] as int] =
            (row['rank'] as int, (row['points'] as num).toInt());
      }
    }
    return out;
  }

  Future<List<ApiPlayer>> squad(int team) async {
    final r = await _get('/players/squads', {'team': '$team'});
    if (r.isEmpty) return [];
    final ps = (r[0]['players'] as List?) ?? [];
    return [
      for (final p in ps)
        ApiPlayer(
          id: p['id'] as int,
          name: p['name'] as String,
          age: p['age'] as int?,
          position: (p['position'] as String?) ?? '',
          photo: p['photo'] as String?,
          number: p['number'] as int?,
        )
    ];
  }
}
