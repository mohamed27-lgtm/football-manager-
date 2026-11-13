import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// مدربون حقيقيون من assets/coaches.json (Transfermarkt Datasets) يُحمَّلون عند بدء التطبيق
final Map<String, String> _realCoaches = {};
final List<String> _coachPool = [];

Future<void> loadCoaches() async {
  try {
    final m = jsonDecode(await rootBundle.loadString('assets/coaches.json')) as Map<String, dynamic>;
    _realCoaches
      ..clear()
      ..addAll({for (final e in m.entries) e.key: e.value as String});
  } catch (_) {}
  try {
    final l = jsonDecode(await rootBundle.loadString('assets/coach_pool.json')) as List;
    _coachPool
      ..clear()
      ..addAll(l.cast<String>());
  } catch (_) {}
}

/// مدرب حقيقي متاح للتعيين (من قائمة مدربين حقيقيين غير مرتبطين بأندية اللعبة)، أو null إن نفدت
String? takeCoachFromPool(Random rng, Set<String> inUse) {
  final free = _coachPool.where((c) => !inUse.contains(c)).toList();
  if (free.isEmpty) return null;
  return free[rng.nextInt(free.length)];
}

/// مدربون حقيقيون لأشهر الأندية (بيانات تقريبية وقد تتغير مع الواقع)، وغيرها يحصل على اسم مولَّد ثابت
const _kCoaches = <String, String>{
  'real madrid': 'تشابي ألونسو', 'barcelona': 'هانسي فليك', 'atletico madrid': 'دييغو سيميوني',
  'sevilla': 'ماتياس ألميدا', 'valencia': 'كارلوس كوربيران', 'villarreal': 'مارسيلينو', 'real sociedad': 'بيليغرينو ماتارازو',
  'athletic club': 'إرنستو فالفيردي', 'real betis': 'مانويل بيليغريني', 'girona': 'ميتشل', 'celta vigo': 'كلاوديو خيرالديز',
  'manchester united': 'روبن أموريم', 'manchester city': 'بيب غوارديولا', 'liverpool': 'آرني سلوت', 'chelsea': 'إنزو ماريسكا',
  'arsenal': 'ميكيل أرتيتا', 'tottenham': 'توماس فرانك', 'newcastle': 'إيدي هاو', 'aston villa': 'أوناي إيمري',
  'everton': 'ديفيد مويز', 'brighton': 'فابيان هورتسلر', 'crystal palace': 'أوليفر غلاسنر', 'fulham': 'ماركو سيلفا',
  'brentford': 'كيث أندروز', 'bournemouth': 'أندوني إيراولا', 'wolves': 'فيتور بيريرا',
  'bayern munich': 'فينسان كومباني', 'borussia dortmund': 'نيكو كوفاتش', 'bayer leverkusen': 'كاسبر هيولماند',
  'rb leipzig': 'أولي فيرنر', 'eintracht frankfurt': 'ديلو توبمولر', 'vfb stuttgart': 'سيباستيان هونيس',
  'sc freiburg': 'يوليان شوستر', 'vfl wolfsburg': 'بول سيمونيس', 'mainz 05': 'بو هينريكسن',
  'juventus': 'لوتشانو سباليتي', 'inter': 'كريستيان كيفو', 'ac milan': 'ماسيميليانو أليغري', 'napoli': 'أنطونيو كونتي',
  'roma': 'جان بييرو غاسبريني', 'lazio': 'ماوريتسيو ساري', 'atalanta': 'إيفان يوريتش', 'fiorentina': 'ستيفانو بيولي',
  'bologna': 'فينتشنزو إيطاليانو', 'torino': 'ماركو بارونى', 'genoa': 'باتريك فييرا',
  'paris saint germain': 'لويس إنريكي', 'paris saint-germain': 'لويس إنريكي', 'marseille': 'روبرتو دي زيربي',
  'monaco': 'آدي هوتر', 'lille': 'برونو جينيسيو', 'lyon': 'باولو فونسيكا', 'nice': 'فرانك هيز', 'lens': 'بيير ساج',
  'benfica': 'جوزيه مورينيو', 'porto': 'فرانشيسكو فاريولي', 'fc porto': 'فرانشيسكو فاريولي', 'sporting cp': 'روي بورجيس',
  'braga': 'كارلوس فيسينز', 'ajax': 'جون هيتنغا', 'psv eindhoven': 'بيتر بوس', 'feyenoord': 'روبن فان بيرسي',
  'galatasaray': 'أوكان بوروك', 'al hilal': 'سيموني إينزاغي', 'al-hilal': 'سيموني إينزاغي', 'al nassr': 'جورخي جيسوس',
  'al-nassr': 'جورخي جيسوس', 'al ahli': 'ماتياس ياسله', 'al-ahli': 'ماتياس ياسله', 'al ahly': 'خوسيه ريفيرو',
  'boca juniors': 'ميغيل أنخل روسو', 'river plate': 'مارسيلو غاياردو', 'flamengo': 'فيليبي لويس', 'palmeiras': 'أبيل فيريرا',
  'inter miami': 'خافيير ماسكيرانو', 'la galaxy': 'غريغ فانيي',
};

/// هل لهذا النادي مدرب حقيقي معروف (وليس اسماً مولَّداً)
bool hasRealCoach(String club) {
  final k = club.toLowerCase().trim();
  return _realCoaches.containsKey(k) || _kCoaches.containsKey(k);
}

/// اسم مدرب النادي: حقيقي إن عُرف، وإلا فارغ (لا نختلق أسماء)
String coachFor(String club) {
  final k = club.toLowerCase().trim();
  return _realCoaches[k] ?? _kCoaches[k] ?? '';
}
