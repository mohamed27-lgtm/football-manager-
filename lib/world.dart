import 'dart:math';

/// ───────── الأندية العالمية (خارج اتحاد المستخدم القاري) ─────────
class WorldClub {
  final String name, conf;
  final int elo;
  const WorldClub(this.name, this.conf, this.elo);
}

/// الاسم الإنجليزي في بيانات الدوريات المضمّنة: يربط نادي السجل بتشكيلته الحقيقية
const kClubAlias = <String, String>{
  'مانشستر سيتي': 'Manchester City',
  'ريال مدريد': 'Real Madrid',
  'أرسنال': 'Arsenal',
  'بايرن ميونخ': 'Bayern München',
  'ليفربول': 'Liverpool',
  'برشلونة': 'Barcelona',
  'إنتر ميلان': 'Inter',
  'باريس سان جيرمان': 'Paris Saint Germain',
  'باير ليفركوزن': 'Bayer Leverkusen',
  'أتلتيكو مدريد': 'Atletico Madrid',
  'تشيلسي': 'Chelsea',
  'أتالانتا': 'Atalanta',
  'بوروسيا دورتموند': 'Borussia Dortmund',
  'نابولي': 'Napoli',
  'يوفنتوس': 'Juventus',
  'ميلان': 'AC Milan',
  'سبورتينغ لشبونة': 'Sporting CP',
  'بنفيكا': 'Benfica',
  'بورتو': 'FC Porto',
  'بي إس في أيندهوفن': 'PSV Eindhoven',
  'فينورد': 'Feyenoord',
  'غلطة سراي': 'Galatasaray',
  'فنربخشة': 'Fenerbahçe',
  'سيلتيك': 'Celtic',
  'فلامنغو': 'Flamengo',
  'بالميراس': 'Palmeiras',
  'ريفر بليت': 'River Plate',
  'بوتافوغو': 'Botafogo',
  'بوكا جونيورز': 'Boca Juniors',
  'أتلتيكو مينيرو': 'Atletico-MG',
  'فلومينينسي': 'Fluminense',
  'راسينغ كلوب': 'Racing Club',
  'إنترناسيونال': 'Internacional',
  'ساو باولو': 'Sao Paulo',
  'إندبندينتي': 'Independiente',
  'الأهلي المصري': 'Al Ahly',
  'الوداد': 'Wydad AC',
  'بيراميدز': 'Pyramids FC',
  'الترجي': 'ES Tunis',
  'الزمالك': 'Zamalek SC',
  'نهضة بركان': 'Renaissance Berkane',
  'الرجاء': 'Raja Casablanca',
  'الجيش الملكي': 'FAR Rabat',
  'اتحاد العاصمة': 'USM Alger',
  'الهلال': 'Al-Hilal Saudi FC',
  'النصر': 'Al-Nassr',
  'الاتحاد': 'Al-Ittihad FC',
  'الأهلي السعودي': 'Al-Ahli Jeddah',
  'العين': 'Al Ain',
  'السد': 'Al Sadd',
  'الوحدة': 'Al Wahda FC',
  'أوراوا ريدز': 'Urawa',
  'شباب الأهلي': 'Shabab Al Ahli Dubai',
  'الدحيل': 'Al-Duhail SC',
  'كاواساكي فرونتال': 'Kawasaki Frontale',
  'يوكوهاما إف مارينوس': 'Yokohama F. Marinos',
  'أولسان هيونداي': 'Ulsan Hyundai FC',
  'فيسل كوبي': 'Vissel Kobe',
  'بوهانغ ستيلرز': 'Pohang Steelers',
  'شنغهاي بورت': 'SHANGHAI SIPG',
  'إف سي سيول': 'FC Seoul',
  'كلوب أمريكا': 'Club America',
  'مونتيري': 'Monterrey',
  'تيغريس': 'Tigres UANL',
  'باتشوكا': 'CF Pachuca',
  'كروز أزول': 'Cruz Azul',
  'إنتر ميامي': 'Inter Miami',
  'ليون': 'Leon',
  'لوس أنجلوس إف سي': 'Los Angeles FC',
  'جوادالاخارا': 'Guadalajara Chivas',
  'سياتل ساوندرز': 'Seattle Sounders',
  'كولومبوس كرو': 'Columbus Crew',
  'فيلادلفيا يونيون': 'Philadelphia Union',
  'أتلانتا يونايتد': 'Atlanta United FC',
  'تورنتو إف سي': 'Toronto FC',
};

const kWorldClubs = <WorldClub>[
  // أوروبا
  WorldClub('مانشستر سيتي', 'uefa', 2040),
  WorldClub('ريال مدريد', 'uefa', 2030),
  WorldClub('أرسنال', 'uefa', 2010),
  WorldClub('بايرن ميونخ', 'uefa', 2010),
  WorldClub('ليفربول', 'uefa', 1990),
  WorldClub('برشلونة', 'uefa', 1960),
  WorldClub('إنتر ميلان', 'uefa', 1960),
  WorldClub('باريس سان جيرمان', 'uefa', 1950),
  WorldClub('باير ليفركوزن', 'uefa', 1940),
  WorldClub('أتلتيكو مدريد', 'uefa', 1900),
  WorldClub('تشيلسي', 'uefa', 1900),
  WorldClub('أتالانتا', 'uefa', 1880),
  WorldClub('بوروسيا دورتموند', 'uefa', 1860),
  WorldClub('نابولي', 'uefa', 1850),
  WorldClub('يوفنتوس', 'uefa', 1850),
  WorldClub('ميلان', 'uefa', 1840),
  WorldClub('سبورتينغ لشبونة', 'uefa', 1840),
  WorldClub('بنفيكا', 'uefa', 1830),
  WorldClub('بورتو', 'uefa', 1810),
  WorldClub('بي إس في أيندهوفن', 'uefa', 1810),
  WorldClub('فينورد', 'uefa', 1760),
  WorldClub('غلطة سراي', 'uefa', 1740),
  WorldClub('فنربخشة', 'uefa', 1730),
  WorldClub('سيلتيك', 'uefa', 1700),
  // أمريكا الجنوبية
  WorldClub('فلامنغو', 'conmebol', 1800),
  WorldClub('بالميراس', 'conmebol', 1790),
  WorldClub('ريفر بليت', 'conmebol', 1780),
  WorldClub('بوتافوغو', 'conmebol', 1740),
  WorldClub('بوكا جونيورز', 'conmebol', 1740),
  WorldClub('أتلتيكو مينيرو', 'conmebol', 1720),
  WorldClub('فلومينينسي', 'conmebol', 1720),
  WorldClub('راسينغ كلوب', 'conmebol', 1710),
  WorldClub('إنترناسيونال', 'conmebol', 1700),
  WorldClub('ساو باولو', 'conmebol', 1690),
  WorldClub('إندبندينتي', 'conmebol', 1690),
  WorldClub('بينيارول', 'conmebol', 1680),
  WorldClub('ناسيونال', 'conmebol', 1660),
  WorldClub('إنديبندينتي ديل فاييه', 'conmebol', 1650),
  WorldClub('أتلتيكو ناسيونال', 'conmebol', 1640),
  WorldClub('ليغا دي كيتو', 'conmebol', 1630),
  WorldClub('كولو كولو', 'conmebol', 1620),
  // أفريقيا
  WorldClub('الأهلي المصري', 'caf', 1730),
  WorldClub('ماميلودي صنداونز', 'caf', 1700),
  WorldClub('الوداد', 'caf', 1670),
  WorldClub('بيراميدز', 'caf', 1670),
  WorldClub('الترجي', 'caf', 1660),
  WorldClub('الزمالك', 'caf', 1650),
  WorldClub('نهضة بركان', 'caf', 1640),
  WorldClub('الرجاء', 'caf', 1640),
  WorldClub('الجيش الملكي', 'caf', 1610),
  WorldClub('اتحاد العاصمة', 'caf', 1600),
  WorldClub('تي بي مازيمبي', 'caf', 1600),
  WorldClub('يانغ أفريكانز', 'caf', 1580),
  WorldClub('أورلاندو بيراتس', 'caf', 1580),
  WorldClub('بترو أتلتيكو', 'caf', 1560),
  WorldClub('سيمبا', 'caf', 1550),
  // آسيا
  WorldClub('الهلال', 'afc', 1820),
  WorldClub('النصر', 'afc', 1790),
  WorldClub('الاتحاد', 'afc', 1770),
  WorldClub('الأهلي السعودي', 'afc', 1760),
  WorldClub('العين', 'afc', 1690),
  WorldClub('السد', 'afc', 1650),
  WorldClub('الوحدة', 'afc', 1640),
  WorldClub('أوراوا ريدز', 'afc', 1640),
  WorldClub('شباب الأهلي', 'afc', 1630),
  WorldClub('الدحيل', 'afc', 1620),
  WorldClub('كاواساكي فرونتال', 'afc', 1620),
  WorldClub('يوكوهاما إف مارينوس', 'afc', 1620),
  WorldClub('أولسان هيونداي', 'afc', 1620),
  WorldClub('فيسل كوبي', 'afc', 1610),
  WorldClub('بوهانغ ستيلرز', 'afc', 1590),
  WorldClub('برسبوليس', 'afc', 1580),
  WorldClub('شنغهاي بورت', 'afc', 1570),
  WorldClub('إف سي سيول', 'afc', 1560),
  WorldClub('سباهان', 'afc', 1550),
  WorldClub('ملبورن سيتي', 'afc', 1540),
  // أمريكا الشمالية والوسطى
  WorldClub('كلوب أمريكا', 'concacaf', 1710),
  WorldClub('مونتيري', 'concacaf', 1700),
  WorldClub('تيغريس', 'concacaf', 1700),
  WorldClub('باتشوكا', 'concacaf', 1670),
  WorldClub('كروز أزول', 'concacaf', 1650),
  WorldClub('إنتر ميامي', 'concacaf', 1650),
  WorldClub('ليون', 'concacaf', 1620),
  WorldClub('لوس أنجلوس إف سي', 'concacaf', 1620),
  WorldClub('جوادالاخارا', 'concacaf', 1610),
  WorldClub('سياتل ساوندرز', 'concacaf', 1600),
  WorldClub('كولومبوس كرو', 'concacaf', 1600),
  WorldClub('فيلادلفيا يونيون', 'concacaf', 1590),
  WorldClub('أتلانتا يونايتد', 'concacaf', 1560),
  WorldClub('تورنتو إف سي', 'concacaf', 1520),
  // أوقيانوسيا
  WorldClub('أوكلاند سيتي', 'ofc', 1380),
  WorldClub('ويلينغتون أوليمبيك', 'ofc', 1300),
  WorldClub('هيكاري سبورتس', 'ofc', 1300),
  WorldClub('ماغنيت', 'ofc', 1290),
];

const kConfNames = {
  'uefa': 'أوروبا',
  'conmebol': 'أمريكا الجنوبية',
  'caf': 'أفريقيا',
  'afc': 'آسيا',
  'concacaf': 'أمريكا الشمالية والوسطى',
  'ofc': 'أوقيانوسيا',
};

/// أبطال كأس القارات: اسم بطل الاتحاد كل موسم (لا يحمل بيانات أخرى)
String champKey(int season, String conf) => '$season|$conf';

/// ───────── المنتخبات الوطنية ─────────
class NatMatch {
  final String a, b, stage;
  final int ag, bg;
  final int? pa, pb;
  const NatMatch(this.a, this.b, this.ag, this.bg, this.stage, {this.pa, this.pb});

  String? get winner => ag > bg ? a : (bg > ag ? b : (pa != null && pb != null ? (pa! > pb! ? a : b) : null));

  List<dynamic> toJson() => [a, b, ag, bg, stage, pa ?? -1, pb ?? -1];
  static NatMatch fromJson(List<dynamic> j) => NatMatch(j[0] as String, j[1] as String, j[2] as int, j[3] as int, j[4] as String,
      pa: (j[5] as int) < 0 ? null : j[5] as int, pb: (j[6] as int) < 0 ? null : j[6] as int);
}

class NatTour {
  final String key, name;
  final int season;
  List<String> teams;
  List<List<String>> groups;
  List<NatMatch> matches = [];
  String? champion, runnerUp;
  Map<String, int> scorers = {}; // اللاعب|المنتخب|النادي ← الأهداف
  Map<String, String> awards = {}; // جوائز البطولة: المفتاح ← اللاعب|المنتخب|النادي
  List<String> hosts;
  NatTour(this.key, this.name, this.season, this.teams, this.groups, this.hosts);

  Map<String, dynamic> toJson() => {
        'k': key,
        'n': name,
        's': season,
        't': teams,
        'g': groups,
        'm': [for (final m in matches) m.toJson()],
        'c': champion,
        'r': runnerUp,
        'sc': scorers,
        'aw': awards,
        'h': hosts,
      };

  static NatTour fromJson(Map<String, dynamic> j) => NatTour(
        j['k'] as String,
        j['n'] as String,
        j['s'] as int,
        (j['t'] as List).cast<String>(),
        [for (final g in j['g'] as List) (g as List).cast<String>()],
        ((j['h'] as List?) ?? const []).cast<String>(),
      )
        ..matches = [for (final m in j['m'] as List) NatMatch.fromJson(m as List)]
        ..champion = j['c'] as String?
        ..runnerUp = j['r'] as String?
        ..scorers = {for (final e in ((j['sc'] as Map?) ?? const {}).entries) e.key as String: e.value as int}
        ..awards = {for (final e in ((j['aw'] as Map?) ?? const {}).entries) e.key as String: e.value as String};
}

/// معلومات بطولة منتخبات: المفتاح، الاسم، دورية الموسم، شكل البطولة
class NatTourDef {
  final String key, name;
  final int cycle, offset; // تُقام عند نهاية الموسم s إذا s % cycle == offset
  final int groups, thirds;
  final double imp, impKo;
  const NatTourDef(this.key, this.name, this.cycle, this.offset, this.groups, this.thirds, this.imp, this.impKo);
  int get teams => groups * 4;
}

const kNatTours = <NatTourDef>[
  NatTourDef('wc', 'كأس العالم', 4, 0, 12, 8, 50, 60),
  NatTourDef('euro', 'أمم أوروبا (اليورو)', 4, 2, 6, 4, 35, 40),
  NatTourDef('afcon', 'كأس أمم أفريقيا', 2, 1, 6, 4, 35, 40),
  NatTourDef('asia', 'كأس آسيا', 4, 1, 6, 4, 35, 40),
  NatTourDef('copa', 'كوبا أمريكا', 4, 2, 4, 0, 35, 40),
  NatTourDef('gold', 'الكأس الذهبية', 2, 1, 4, 0, 35, 40),
];

/// مستضيفو النسخ (بالترتيب، تتكرر)؛ المضيف يتأهل مباشرة ويحظى بأفضلية +60 نقطة
const kNatHosts = <String, List<List<String>>>{
  'wc': [
    ['أمريكا', 'كندا', 'المكسيك'],
    ['إسبانيا', 'البرتغال', 'المغرب'],
    ['السعودية'],
    ['إنجلترا'],
  ],
  'euro': [
    ['إنجلترا', 'ويلز', 'إسكتلندا'],
    ['إيطاليا', 'تركيا'],
    ['ألمانيا'],
  ],
  'afcon': [
    ['كينيا', 'أوغندا', 'تنزانيا'],
    ['المغرب'],
    ['الجزائر'],
  ],
  'asia': [
    ['السعودية'],
    ['قطر'],
    ['اليابان'],
  ],
  'copa': [
    ['الإكوادور'],
    ['أمريكا'],
    ['الأرجنتين'],
  ],
  'gold': [
    ['أمريكا', 'كندا'],
    ['المكسيك', 'أمريكا'],
    ['أمريكا'],
  ],
};

/// النقاط الأولية (تقريب لتصنيف فيفا الحقيقي)
const _initPts = <String, int>{
  'الأرجنتين': 1886, 'إسبانيا': 1854, 'فرنسا': 1851, 'إنجلترا': 1820, 'البرتغال': 1763, 'البرازيل': 1760, 'هولندا': 1757,
  'بلجيكا': 1739, 'ألمانيا': 1727, 'المغرب': 1727, 'كرواتيا': 1717, 'إيطاليا': 1702, 'كولومبيا': 1701, 'أمريكا': 1681,
  'المكسيك': 1679, 'أوروغواي': 1673, 'سويسرا': 1655, 'اليابان': 1650, 'السنغال': 1645, 'إيران': 1633, 'الدنمارك': 1617,
  'كوريا الجنوبية': 1599, 'الإكوادور': 1592, 'النمسا': 1586, 'تركيا': 1581, 'أستراليا': 1574, 'أوكرانيا': 1560,
  'كندا': 1546, 'مصر': 1546, 'الجزائر': 1545, 'ساحل العاج': 1545, 'بنما': 1539, 'نيجيريا': 1537, 'بولندا': 1532,
  'المجر': 1530, 'ويلز': 1525, 'السويد': 1518, 'صربيا': 1510, 'باراغواي': 1507, 'إسكتلندا': 1507, 'النرويج': 1501,
  'الأردن': 1500, 'روسيا': 1500, 'التشيك': 1497, 'رومانيا': 1490, 'بيرو': 1490, 'اليونان': 1485, 'الكونغو الديمقراطية': 1485,
  'كوستاريكا': 1485, 'سلوفاكيا': 1480, 'أيرلندا': 1480, 'جامايكا': 1480, 'أوزبكستان': 1478, 'تونس': 1476, 'الكاميرون': 1475,
  'جنوب أفريقيا': 1475, 'السعودية': 1460, 'مالي': 1465, 'بوركينا فاسو': 1470, 'الرأس الأخضر': 1460, 'شيلي': 1470, 'تشيلي': 1470,
  'فنزويلا': 1460, 'قطر': 1455, 'ألبانيا': 1470, 'جورجيا': 1470, 'أيسلندا': 1470, 'سلوفينيا': 1450, 'غانا': 1450, 'العراق': 1440,
  'أيرلندا الشمالية': 1450, 'البوسنة والهرسك': 1450, 'فنلندا': 1440, 'شمال مقدونيا': 1440, 'إسرائيل': 1440, 'الغابون': 1440,
  'هندوراس': 1420, 'هايتي': 1420, 'الجبل الأسود': 1420, 'الإمارات': 1400, 'غينيا': 1400, 'كوسوفو': 1400, 'كازاخستان': 1400,
  'بلغاريا': 1400, 'أنغولا': 1390, 'عُمان': 1390, 'بوليفيا': 1380, 'زامبيا': 1380, 'بنين': 1380, 'أوغندا': 1380, 'أرمينيا': 1380,
  'سوريا': 1380, 'تنزانيا': 1370, 'كوراساو': 1370, 'غواتيمالا': 1370, 'الكونغو': 1360, 'غينيا الاستوائية': 1360, 'فلسطين': 1360,
  'البحرين': 1360, 'ليبيا': 1330, 'السودان': 1350, 'أذربيجان': 1350, 'الصين': 1340, 'قبرص': 1340, 'موريتانيا': 1340,
  'موزمبيق': 1340, 'كينيا': 1340, 'النيجر': 1340, 'غامبيا': 1340, 'إندونيسيا': 1330, 'نيوزيلندا': 1330, 'لوكسمبورغ': 1330,
  'كوريا الشمالية': 1330, 'قيرغيزستان': 1330, 'طاجيكستان': 1330, 'السلفادور': 1330, 'توغو': 1330, 'ناميبيا': 1330, 'الكويت': 1330,
  'لبنان': 1320, 'تايلاند': 1320, 'جزر القمر': 1320, 'غينيا بيساو': 1320, 'مدغشقر': 1310, 'سيراليون': 1300, 'زيمبابوي': 1300,
  'كوبا': 1300, 'ترينيداد وتوباغو': 1290, 'ماليزيا': 1250, 'سورينام': 1290, 'فيتنام': 1290, 'مالاوي': 1290, 'الفلبين': 1270,
  'غيانا': 1270, 'إثيوبيا': 1260, 'بوروندي': 1260, 'رواندا': 1260, 'الهند': 1250, 'نيكاراغوا': 1250, 'جمهورية الدومينيكان': 1230,
  'تشاد': 1210, 'مالطا': 1180,
};

/// الاتحاد القاري للمنتخب (بحسب الإقليم في قائمة الدول)
String natConfOf(String name, String region) {
  switch (region) {
    case 'A':
      return 'caf';
    case 'E':
      return 'uefa';
    case 'S':
      return (name == 'إسرائيل' || name == 'كازاخستان') ? 'uefa' : 'afc';
    case 'O':
      return name == 'أستراليا' ? 'afc' : 'ofc';
    default:
      const south = {'البرازيل', 'الأرجنتين', 'أوروغواي', 'باراغواي', 'تشيلي', 'كولومبيا', 'بيرو', 'الإكوادور', 'بوليفيا', 'فنزويلا'};
      return south.contains(name) ? 'conmebol' : 'concacaf';
  }
}

typedef ScorerPool = List<(String, String, double)> Function(String nation); // (لاعب، نادي، وزن)

class NatState {
  final Map<String, double> pts = {};
  final Map<String, double> start = {}; // نقاط بداية الموسم لإظهار التغيّر
  final Map<String, String> conf = {};
  final Map<String, int> qp = {}, qgd = {}; // نتائج مباريات التصفيات للموسم
  final List<NatTour> history = [];
  /// سجل المباريات الدولية (تصفيات/ودية): [موسم، جولة، أ، ب، أهداف أ، أهداف ب، النوع 0 تصفيات/1 ودية]
  final List<List<dynamic>> log = [];
  /// النوافذ الدولية المنتهية هذا الموسم، والتصنيف المنشور رسمياً (يتحدّث بعد كل نافذة)
  final Set<int> winDone = {};
  final Map<String, double> pub = {};
  final Map<String, int> prevRk = {};
  String pubDate = '';
  bool pendRel = false;
  static const winNames = ['سبتمبر', 'أكتوبر', 'نوفمبر', 'مارس', 'يونيو'];
  // قوة المنتخب الداخلية (Elo مبدئي) تُستعمل لمحاكاة النتائج فقط؛ ولا تُعرض كنقاط
  // نقاط التصنيف المعروضة: صيغة فيفا الكلاسيكية M × I × T × C بمتوسطات المواسم (1 / 0.5 / 0.3 / 0.2)
  final Map<String, List<double>> cur = {}; // [مجموع نقاط المباريات، عدد المباريات] للموسم الجاري
  final Map<String, List<double>> past = {}; // متوسطات المواسم السابقة (الأحدث أخيراً، حتى 3)
  Map<String, int> _rk = {};
  static const _confCoef = {'uefa': 1.0, 'conmebol': 1.0, 'concacaf': 0.88, 'afc': 0.86, 'caf': 0.86, 'ofc': 0.85};

  /// نقاط التصنيف الرسمية بصيغة فيفا الحالية: P = P0 + I × (W − We)، بنقاط ابتدائية قريبة من التصنيف الحقيقي
  double rating(String n) => pts[n] ?? 0;

  void snapshotRanks() {
    final l = pts.keys.toList()
      ..sort((a, b) {
        final c = rating(b).compareTo(rating(a));
        return c != 0 ? c : pts[b]!.compareTo(pts[a]!);
      });
    _rk = {for (var i = 0; i < l.length; i++) l[i]: i + 1};
  }

  /// نهاية موسم: يُحفظ متوسط نقاط مباريات كل منتخب ويُصفَّر عدّاد الموسم
  void rollSeason() {
    cur.forEach((n, c) {
      if (c[1] > 0) {
        final l = past.putIfAbsent(n, () => []);
        l.add(c[0] / c[1]);
        while (l.length > 3) {
          l.removeAt(0);
        }
      }
    });
    cur.clear();
  }

  void _credit(String a, String b, int ag, int bg, double imp, int? pa, int? pb) {
    double m(int x, int y, int? px, int? py) => x > y ? 3.0 : (x < y ? 0.0 : ((px != null && py != null) ? (px > py ? 2.0 : 1.0) : 1.0));
    double t(String o) => max(0.5, (200 - (_rk[o] ?? 100)) / 100.0);
    final c = ((_confCoef[conf[a]] ?? 0.86) + (_confCoef[conf[b]] ?? 0.86)) / 2;
    final xa = cur.putIfAbsent(a, () => [0.0, 0.0]);
    xa[0] += m(ag, bg, pa, pb) * imp * t(b) * c;
    xa[1] += 1;
    final xb = cur.putIfAbsent(b, () => [0.0, 0.0]);
    xb[0] += m(bg, ag, pb, pa) * imp * t(a) * c;
    xb[1] += 1;
  }

  bool get ready => pts.isNotEmpty;

  void init(Iterable<(String, String)> nations, Random rng) {
    for (final n in nations) {
      conf[n.$1] = natConfOf(n.$1, n.$2);
      if (pts.containsKey(n.$1)) {
        _seedPast(n.$1);
        continue;
      }
      final base = _initPts[n.$1];
      if (base != null) {
        pts[n.$1] = base.toDouble();
      } else {
        final c = conf[n.$1]!;
        final b = switch (c) { 'caf' => 1220, 'afc' => 1180, 'uefa' => 1200, 'conmebol' => 1300, 'concacaf' => 1120, _ => 1000 };
        pts[n.$1] = b + (n.$1.hashCode % 80) - 40.0;
      }
      _seedPast(n.$1);
    }
  }

  /// نقاط ابتدائية معقولة للتصنيف قبل أول مباراة (تتلاشى تدريجياً مع نتائج المباريات)
  void _seedPast(String n) {
    if (past.containsKey(n) || (cur[n]?[1] ?? 0) > 0) return;
    final r = ((pts[n] ?? 1200) - 1000) * 0.45 + 250;
    past[n] = [r / 100, r / 100, r / 100];
  }

  List<String> get ranking {
    final l = pts.keys.toList()
      ..sort((a, b) {
        final c = rating(b).compareTo(rating(a));
        return c != 0 ? c : pts[b]!.compareTo(pts[a]!);
      });
    return l;
  }

  int rankOf(String n) => ranking.indexOf(n) + 1;

  static double expected(double dr) => 1 / (pow(10, -dr / 600) + 1);

  static int _poisson(Random r, double l) {
    final lim = exp(-l);
    var k = 0;
    var p = 1.0;
    do {
      k++;
      p *= r.nextDouble();
    } while (p > lim && k < 12);
    return k - 1;
  }

  /// أهداف المباراة من فارق التصنيف (ra، rb) — متوسط الأهداف نحو 2.7
  static (int, int) goals(Random r, double ra, double rb) {
    final d = (ra - rb) / 700;
    return (_poisson(r, 1.35 * exp(d)), _poisson(r, 1.35 * exp(-d)));
  }

  /// معادلة فيفا: P = P0 + I × (W − We). في الأدوار الإقصائية لا يخسر الخاسر نقاطاً
  void apply(String a, String b, int ag, int bg, double imp, {bool ko = false, int? pa, int? pb, double fifa = 1.0}) {
    _credit(a, b, ag, bg, fifa, pa, pb);
    final ra = pts[a] ?? 1200, rb = pts[b] ?? 1200;
    double w;
    if (ag != bg) {
      w = ag > bg ? 1 : 0;
    } else if (pa != null && pb != null) {
      w = pa > pb ? 0.75 : 0.5;
    } else {
      w = 0.5;
    }
    final wb = ag != bg ? 1 - w : (pa != null && pb != null ? (pb > pa ? 0.75 : 0.5) : 0.5);
    final we = expected(ra - rb);
    var da = imp * (w - we);
    var db = imp * (wb - (1 - we));
    if (ko) {
      if (da < 0) da = 0;
      if (db < 0) db = 0;
    }
    pts[a] = ra + da;
    pts[b] = rb + db;
  }

  /// بداية موسم جديد: تصفير نقاط التصفيات والنوافذ
  void startSeason() {
    qp.clear();
    qgd.clear();
    winDone.clear();
  }

  /// نافذة دولية (0 سبتمبر، 1 أكتوبر، 2 نوفمبر، 3 مارس، 4 يونيو): جولة تصفيات رسمية داخل الاتحاد (0–3)
  /// ومباريات ودية بين منتخبات من أي اتحاد (كل النوافذ عدا أكتوبر)
  int playWindow(int wid, Random rng, double Function(String) adj, int season) {
    snapshotRanks();
    var n = 0;
    void play(String a, String b, bool qual) {
      final ra = pts[a]! + adj(a) + 40, rb = pts[b]! + adj(b);
      final g = goals(rng, ra, rb);
      apply(a, b, g.$1, g.$2, qual ? 25 : 10, fifa: qual ? 2.5 : 1.0);
      log.add([season, wid, a, b, g.$1, g.$2, qual ? 0 : 1]);
      n++;
      if (qual) {
        qp[a] = (qp[a] ?? 0) + (g.$1 > g.$2 ? 3 : (g.$1 == g.$2 ? 1 : 0));
        qp[b] = (qp[b] ?? 0) + (g.$2 > g.$1 ? 3 : (g.$1 == g.$2 ? 1 : 0));
        qgd[a] = (qgd[a] ?? 0) + g.$1 - g.$2;
        qgd[b] = (qgd[b] ?? 0) + g.$2 - g.$1;
      }
    }

    if (wid <= 3) {
      final byConf = <String, List<String>>{};
      conf.forEach((nm, c) => byConf.putIfAbsent(c, () => []).add(nm));
      for (final l in byConf.values) {
        final x = [...l]..shuffle(rng);
        for (var i = 0; i + 1 < x.length; i += 2) {
          play(x[i], x[i + 1], true);
        }
      }
    }
    if (wid != 1) {
      final x = conf.keys.toList()..shuffle(rng);
      for (var i = 0; i + 1 < x.length; i += 2) {
        play(x[i], x[i + 1], false);
      }
    }
    winDone.add(wid);
    pendRel = true;
    if (log.length > 1400) log.removeRange(0, log.length - 1400);
    return n;
  }

  /// ترتيب التصنيف المنشور رسمياً (قبل أول إصدار يُعرض الترتيب الحالي)
  List<String> get pubRanking {
    if (pub.isEmpty) return ranking;
    final l = pub.keys.toList()..sort((a, b) => pub[b]!.compareTo(pub[a]!));
    return l;
  }

  /// إصدار تصنيف جديد: نقاط كل منتخب الآن وحركة المراكز مقارنة بالإصدار السابق
  void publish(String date) {
    final old = pubRanking;
    prevRk
      ..clear()
      ..addAll({for (var i = 0; i < old.length; i++) old[i]: i + 1});
    pub
      ..clear()
      ..addAll({for (final n in pts.keys) n: rating(n)});
    pubDate = date;
    pendRel = false;
  }

  /// أفضل منتخبات اتحاد في التصفيات (النقاط ثم فارق الأهداف ثم تصنيف فيفا)
  List<String> qualifiers(Iterable<String> confs, int n, {Set<String> exclude = const {}}) {
    final l = [for (final e in conf.entries) if (confs.contains(e.value) && !exclude.contains(e.key)) e.key]
      ..sort((a, b) {
        final c = (qp[b] ?? 0).compareTo(qp[a] ?? 0);
        if (c != 0) return c;
        final d = (qgd[b] ?? 0).compareTo(qgd[a] ?? 0);
        return d != 0 ? d : pts[b]!.compareTo(pts[a]!);
      });
    return l.take(n).toList();
  }

  static List<int> _bracket(int n) {
    var cur = [0];
    while (cur.length < n) {
      final len = cur.length * 2;
      cur = [for (final x in cur) ...[x, len - 1 - x]];
    }
    return cur;
  }

  /// يلعب بطولة كاملة ويحدّث نقاط فيفا بعد كل مباراة
  NatTour play(NatTourDef d, int season, List<String> teams, List<String> hosts, Random rng, double Function(String) adj, ScorerPool pool) {
    String stage(String s) => s;
    snapshotRanks();
    double eff(String n) => pts[n]! + adj(n) + (hosts.contains(n) ? 60 : 0);
    final sorted = [...teams]..sort((a, b) => eff(b).compareTo(eff(a)));
    final g = d.groups;
    final groups = List.generate(g, (_) => <String>[]);
    for (var pot = 0; pot < 4; pot++) {
      final slice = sorted.sublist(pot * g, pot * g + g)..shuffle(rng);
      for (var i = 0; i < g; i++) {
        groups[i].add(slice[i]);
      }
    }
    final t = NatTour(d.key, d.name, season, sorted, groups, hosts);
    final scorers = <String, int>{};

    void credit(String nation, int goals) {
      if (goals <= 0) return;
      final p = pool(nation);
      if (p.isEmpty) return;
      final total = p.fold<double>(0, (a, e) => a + e.$3);
      for (var k = 0; k < goals; k++) {
        var x = rng.nextDouble() * total;
        for (final e in p) {
          x -= e.$3;
          if (x <= 0) {
            final key = '${e.$1}|$nation|${e.$2}';
            scorers[key] = (scorers[key] ?? 0) + 1;
            break;
          }
        }
      }
    }

    NatMatch play1(String a, String b, String st, double imp, bool ko) {
      final g1 = goals(rng, eff(a), eff(b));
      int? pa, pb;
      var ag = g1.$1, bg = g1.$2;
      if (ko && ag == bg) {
        // وقت إضافي ثم ركلات ترجيح
        final e = goals(rng, (eff(a) + 0), (eff(b) + 0));
        ag += e.$1 ~/ 2;
        bg += e.$2 ~/ 2;
        if (ag == bg) {
          final pHome = (0.5 + (eff(a) - eff(b)) / 2500).clamp(0.38, 0.62).toDouble();
          final aw = rng.nextDouble() < pHome;
          final w = 4 + rng.nextInt(2);
          final l = w - 1 - rng.nextInt(2);
          pa = aw ? w : l;
          pb = aw ? l : w;
        }
      }
      credit(a, ag);
      credit(b, bg);
      apply(a, b, ag, bg, imp, ko: ko && d.key == 'wc', pa: pa, pb: pb, fifa: d.key == 'wc' ? 4.0 : 3.0);
      final m = NatMatch(a, b, ag, bg, stage(st), pa: pa, pb: pb);
      t.matches.add(m);
      return m;
    }

    // دور المجموعات (6 مباريات لكل مجموعة)
    const pairs = [(0, 1), (2, 3), (0, 2), (3, 1), (3, 0), (1, 2)];
    for (var gi = 0; gi < g; gi++) {
      final label = 'G${String.fromCharCode(65 + gi)}';
      for (final pr in pairs) {
        play1(groups[gi][pr.$1], groups[gi][pr.$2], label, d.imp, false);
      }
    }
    // ترتيب المجموعات
    final rows = <String, List<int>>{}; // نقاط، فارق، أهداف
    for (final m in t.matches) {
      for (final side in [(m.a, m.ag, m.bg), (m.b, m.bg, m.ag)]) {
        final r = rows.putIfAbsent(side.$1, () => [0, 0, 0]);
        r[0] += side.$2 > side.$3 ? 3 : (side.$2 == side.$3 ? 1 : 0);
        r[1] += side.$2 - side.$3;
        r[2] += side.$2;
      }
    }
    int cmp(String a, String b) {
      for (var i = 0; i < 3; i++) {
        final c = rows[b]![i].compareTo(rows[a]![i]);
        if (c != 0) return c;
      }
      return eff(b).compareTo(eff(a));
    }

    final q = <String>[];
    final thirds = <String>[];
    for (final gr in groups) {
      final s = [...gr]..sort(cmp);
      q..add(s[0])..add(s[1]);
      if (d.thirds > 0) thirds.add(s[2]);
    }
    thirds.sort(cmp);
    q.addAll(thirds.take(d.thirds));
    // بذر الإقصائيات: الأول ثم الثاني ثم الثالث حسب النقاط
    final pos = <String, int>{};
    for (final gr in groups) {
      final s = [...gr]..sort(cmp);
      for (var i = 0; i < s.length; i++) {
        pos[s[i]] = i;
      }
    }
    q.sort((a, b) {
      final c = pos[a]!.compareTo(pos[b]!);
      return c != 0 ? c : cmp(a, b);
    });
    final order = _bracket(q.length);
    var cur = [for (final i in order) q[i]];
    while (cur.length > 1) {
      final st = switch (cur.length) { 32 => 'R32', 16 => 'R16', 8 => 'QF', 4 => 'SF', _ => 'F' };
      final next = <String>[];
      for (var i = 0; i + 1 < cur.length; i += 2) {
        final m = play1(cur[i], cur[i + 1], st, d.impKo, true);
        next.add(m.winner!);
        if (st == 'F') {
          t.champion = m.winner;
          t.runnerUp = m.winner == m.a ? m.b : m.a;
        }
      }
      cur = next;
    }
    t.scorers = Map.fromEntries((scorers.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(15));
    return t;
  }
}
