/// الديربيات والخصومات التاريخية. المستوى: 2 = ديربي كبير، 1 = ديربي محلي، 0 = لا شيء.
/// تُطابَق الأسماء بعد تطبيعها (أحرف صغيرة بلا رموز ولا أجزاء عامة مثل FC).
String _norm(String s) {
  var t = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9؀-ۿ ]'), ' ');
  t = t.replaceAll(RegExp(r'\b(fc|cf|afc|sc|ac|club|de|the)\b'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// كل عنصر: (النادي أ، النادي ب، اسم الديربي، المستوى)
const _kDerbies = <(List<String>, List<String>, String, int)>[
  (['real madrid'], ['barcelona'], 'الكلاسيكو', 2),
  (['real madrid'], ['atletico madrid', 'atletico de madrid', 'atletico'], 'ديربي مدريد', 2),
  (['barcelona'], ['espanyol'], 'ديربي كتالونيا', 1),
  (['sevilla'], ['real betis', 'betis'], 'ديربي إشبيلية', 2),
  (['athletic club', 'athletic bilbao'], ['real sociedad'], 'ديربي إقليم الباسك', 1),
  (['valencia'], ['villarreal'], 'ديربي إقليم فالنسيا', 1),
  (['manchester united'], ['manchester city'], 'ديربي مانشستر', 2),
  (['manchester united'], ['liverpool'], 'كلاسيكو إنجلترا', 2),
  (['liverpool'], ['everton'], 'ديربي ميرسيسايد', 2),
  (['arsenal'], ['tottenham', 'tottenham hotspur'], 'ديربي شمال لندن', 2),
  (['chelsea'], ['arsenal'], 'ديربي لندن', 1),
  (['chelsea'], ['tottenham', 'tottenham hotspur'], 'ديربي لندن', 1),
  (['west ham', 'west ham united'], ['millwall'], 'ديربي لندن', 1),
  (['newcastle', 'newcastle united'], ['sunderland'], 'ديربي التاين وير', 2),
  (['aston villa'], ['birmingham', 'birmingham city'], 'ديربي برمنغهام', 1),
  (['ac milan', 'milan'], ['inter', 'inter milan', 'internazionale'], 'ديربي ميلانو', 2),
  (['juventus'], ['inter', 'inter milan', 'internazionale'], 'ديربي إيطاليا', 2),
  (['juventus'], ['torino'], 'ديربي تورينو', 2),
  (['roma', 'as roma'], ['lazio'], 'ديربي العاصمة', 2),
  (['napoli'], ['roma', 'as roma'], 'ديربي الشمس', 1),
  (['genoa'], ['sampdoria'], 'ديربي جنوة', 2),
  (['bayern munich', 'bayern'], ['borussia dortmund', 'dortmund'], 'دير كلاسيكر', 2),
  (['borussia dortmund', 'dortmund'], ['schalke 04', 'schalke'], 'ديربي الرور', 2),
  (['hamburger sv', 'hamburg'], ['werder bremen'], 'ديربي الشمال', 1),
  (['paris saint germain', 'paris saint-germain', 'psg'], ['marseille', 'olympique marseille'], 'لو كلاسيك', 2),
  (['lyon', 'olympique lyonnais'], ['saint etienne', 'saint-etienne'], 'ديربي الرون', 2),
  (['benfica'], ['sporting cp', 'sporting lisbon', 'sporting'], 'ديربي لشبونة', 2),
  (['benfica'], ['porto', 'fc porto'], 'كلاسيكو البرتغال', 2),
  (['ajax'], ['feyenoord'], 'دي كلاسيكر', 2),
  (['ajax'], ['psv eindhoven', 'psv'], 'ديربي هولندا', 1),
  (['celtic'], ['rangers'], 'ديربي الأولد فيرم', 2),
  (['galatasaray'], ['fenerbahce'], 'ديربي إسطنبول', 2),
  (['galatasaray'], ['besiktas'], 'ديربي إسطنبول', 2),
  (['fenerbahce'], ['besiktas'], 'ديربي إسطنبول', 2),
  (['boca juniors'], ['river plate'], 'السوبر كلاسيكو', 2),
  (['flamengo'], ['fluminense'], 'ديربي فلا-فلو', 2),
  (['palmeiras'], ['corinthians'], 'ديربي ساو باولو', 2),
  (['al ahly'], ['zamalek'], 'ديربي القاهرة', 2),
  (['wydad ac', 'wydad casablanca'], ['raja casablanca', 'raja ca'], 'ديربي الدار البيضاء', 2),
  (['al hilal'], ['al nassr'], 'ديربي الرياض', 2),
  (['al hilal'], ['al ittihad'], 'كلاسيكو السعودية', 1),
  (['al ittihad'], ['al ahli', 'al ahli saudi'], 'ديربي جدة', 2),
  (['esperance de tunis', 'esperance'], ['club africain'], 'ديربي تونس', 2),
  (['olympiacos'], ['panathinaikos'], 'ديربي الأبدية', 2),
  (['red star belgrade', 'crvena zvezda'], ['partizan', 'partizan belgrade'], 'الديربي الأبدي', 2),
  (['dinamo zagreb'], ['hajduk split'], 'الديربي الكرواتي', 1),
  (['real madrid'], ['bayern munich', 'bayern'], 'خصومة أوروبية', 1),
];

String _compact(String s) => _norm(s);

bool _in(List<String> keys, String n) => keys.contains(n);

/// (المستوى، الاسم) للقاء ناديين؛ (0، '') إن لم يكن ديربي
(int, String) derbyOf(String a, String b) {
  final x = _compact(a), y = _compact(b);
  if (x.isEmpty || y.isEmpty || x == y) return (0, '');
  for (final d in _kDerbies) {
    if ((_in(d.$1, x) && _in(d.$2, y)) || (_in(d.$1, y) && _in(d.$2, x))) return (d.$4, d.$3);
  }
  return (0, '');
}
