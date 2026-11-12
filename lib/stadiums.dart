/// ملاعب حقيقية لأشهر الأندية (احتياطي حين لا تحمل بيانات الدوري اسم الملعب)
const _kStadiums = <String, String>{
  'real madrid': 'سانتياغو برنابيو', 'barcelona': 'سبوتيفاي كامب نو', 'atletico madrid': 'متروبوليتانو',
  'sevilla': 'رامون سانشيز بيزخوان', 'valencia': 'ميستايا', 'villarreal': 'إستاديو دي لا سيراميكا',
  'real sociedad': 'ريالي أرينا', 'athletic club': 'سان ماميس', 'real betis': 'بينيتو فيامارين',
  'manchester united': 'أولد ترافورد', 'manchester city': 'الاتحاد', 'liverpool': 'أنفيلد',
  'chelsea': 'ستامفورد بريدج', 'arsenal': 'الإمارات', 'tottenham': 'توتنهام هوتسبير', 'newcastle': 'سانت جيمس بارك',
  'aston villa': 'فيلا بارك', 'west ham': 'ملعب لندن', 'everton': 'غوديسون بارك', 'leicester': 'كينغ باور',
  'bayern munich': 'أليانز أرينا', 'borussia dortmund': 'سيغنال إيدونا بارك', 'bayer leverkusen': 'باي أرينا',
  'rb leipzig': 'ريد بول أرينا', 'eintracht frankfurt': 'دويتشه بنك بارك', 'schalke 04': 'فيلتينس أرينا',
  'juventus': 'أليانز ستاديوم', 'inter': 'سان سيرو (جوزيبي مياتزا)', 'ac milan': 'سان سيرو (جوزيبي مياتزا)',
  'napoli': 'دييغو أرماندو مارادونا', 'roma': 'الأولمبيكو', 'lazio': 'الأولمبيكو', 'atalanta': 'غيويس ستاديوم',
  'fiorentina': 'أرتيميو فرانكي', 'torino': 'أوليمبيكو غراندي تورينو',
  'paris saint germain': 'حديقة الأمراء', 'paris saint-germain': 'حديقة الأمراء', 'marseille': 'أورانج فيلودروم',
  'lyon': 'غروباما ستاديوم', 'monaco': 'لويس الثاني', 'lille': 'بيير موروا',
  'benfica': 'ملعب النور', 'porto': 'دراغاو', 'fc porto': 'دراغاو', 'sporting cp': 'خوسيه ألفالادي',
  'ajax': 'يوهان كرويف أرينا', 'psv eindhoven': 'فيليبس ستاديون', 'feyenoord': 'دي كويب',
  'celtic': 'سيلتيك بارك', 'rangers': 'آيبروكس', 'galatasaray': 'رامس بارك', 'fenerbahce': 'شكري سراج أوغلو',
  'besiktas': 'بيسيكتاش بارك', 'al hilal': 'المملكة أرينا', 'al nassr': 'الأول بارك', 'al ittihad': 'الجوهرة المشعة',
  'al ahli': 'الجوهرة المشعة', 'al-hilal': 'المملكة أرينا', 'al-nassr': 'الأول بارك',
  'al ahly': 'ملعب القاهرة الدولي', 'zamalek': 'ملعب القاهرة الدولي', 'wydad ac': 'مركب محمد الخامس',
  'raja casablanca': 'مركب محمد الخامس', 'boca juniors': 'لا بومبونيرا', 'river plate': 'المونومنتال',
  'flamengo': 'ماراكانا', 'palmeiras': 'أليانز بارك', 'inter miami': 'تشيس ستاديوم', 'la galaxy': 'ديغنيتي هيلث سبورتس بارك',
};

String? stadiumFor(String club) => _kStadiums[club.toLowerCase().trim()];
