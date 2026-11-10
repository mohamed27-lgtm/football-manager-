import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'widgets.dart';

/// دولة: الاسم العربي، رمز ISO، القارة (A أفريقيا، E أوروبا، S آسيا، M الأمريكتان، O أوقيانوسيا)
class Country {
  final String name, iso, region;
  const Country(this.name, this.iso, this.region);
}

const _raw = '''
المغرب|ma|A;مصر|eg|A;الجزائر|dz|A;تونس|tn|A;ليبيا|ly|A;السودان|sd|A;السنغال|sn|A;مالي|ml|A;غينيا|gn|A;ساحل العاج|ci|A;غانا|gh|A;نيجيريا|ng|A;الكاميرون|cm|A;الكونغو الديمقراطية|cd|A;الكونغو|cg|A;الغابون|ga|A;أنغولا|ao|A;جنوب أفريقيا|za|A;زامبيا|zm|A;زيمبابوي|zw|A;موزمبيق|mz|A;تنزانيا|tz|A;كينيا|ke|A;أوغندا|ug|A;إثيوبيا|et|A;الصومال|so|A;جيبوتي|dj|A;موريتانيا|mr|A;بوركينا فاسو|bf|A;النيجر|ne|A;تشاد|td|A;بنين|bj|A;توغو|tg|A;سيراليون|sl|A;ليبيريا|lr|A;غامبيا|gm|A;غينيا بيساو|gw|A;الرأس الأخضر|cv|A;غينيا الاستوائية|gq|A;أفريقيا الوسطى|cf|A;بوروندي|bi|A;رواندا|rw|A;مالاوي|mw|A;ناميبيا|na|A;بوتسوانا|bw|A;مدغشقر|mg|A;موريشيوس|mu|A;جزر القمر|km|A;إريتريا|er|A;جنوب السودان|ss|A;ليسوتو|ls|A;إسواتيني|sz|A;سيشل|sc|A;ساو تومي وبرينسيب|st|A
فرنسا|fr|E;إسبانيا|es|E;ألمانيا|de|E;إيطاليا|it|E;إنجلترا|gb-eng|E;إسكتلندا|gb-sct|E;ويلز|gb-wls|E;أيرلندا الشمالية|gb-nir|E;أيرلندا|ie|E;البرتغال|pt|E;هولندا|nl|E;بلجيكا|be|E;لوكسمبورغ|lu|E;سويسرا|ch|E;النمسا|at|E;الدنمارك|dk|E;السويد|se|E;النرويج|no|E;فنلندا|fi|E;أيسلندا|is|E;بولندا|pl|E;التشيك|cz|E;سلوفاكيا|sk|E;المجر|hu|E;رومانيا|ro|E;بلغاريا|bg|E;اليونان|gr|E;كرواتيا|hr|E;صربيا|rs|E;البوسنة والهرسك|ba|E;سلوفينيا|si|E;الجبل الأسود|me|E;شمال مقدونيا|mk|E;ألبانيا|al|E;كوسوفو|xk|E;أوكرانيا|ua|E;روسيا|ru|E;بيلاروسيا|by|E;مولدوفا|md|E;ليتوانيا|lt|E;لاتفيا|lv|E;إستونيا|ee|E;تركيا|tr|E;قبرص|cy|E;مالطا|mt|E;جورجيا|ge|E;أرمينيا|am|E;أذربيجان|az|E;ليختنشتاين|li|E;أندورا|ad|E;موناكو|mc|E;سان مارينو|sm|E;جزر فارو|fo|E;جبل طارق|gi|E
السعودية|sa|S;الإمارات|ae|S;قطر|qa|S;الكويت|kw|S;البحرين|bh|S;عُمان|om|S;اليمن|ye|S;العراق|iq|S;سوريا|sy|S;لبنان|lb|S;الأردن|jo|S;فلسطين|ps|S;إيران|ir|S;إسرائيل|il|S;أفغانستان|af|S;باكستان|pk|S;الهند|in|S;بنغلاديش|bd|S;سريلانكا|lk|S;نيبال|np|S;بوتان|bt|S;جزر المالديف|mv|S;الصين|cn|S;اليابان|jp|S;كوريا الجنوبية|kr|S;كوريا الشمالية|kp|S;منغوليا|mn|S;هونغ كونغ|hk|S;تايوان|tw|S;تايلاند|th|S;فيتنام|vn|S;ماليزيا|my|S;إندونيسيا|id|S;الفلبين|ph|S;سنغافورة|sg|S;كمبوديا|kh|S;لاوس|la|S;ميانمار|mm|S;بروناي|bn|S;كازاخستان|kz|S;أوزبكستان|uz|S;تركمانستان|tm|S;قيرغيزستان|kg|S;طاجيكستان|tj|S
البرازيل|br|M;الأرجنتين|ar|M;أوروغواي|uy|M;باراغواي|py|M;تشيلي|cl|M;كولومبيا|co|M;بيرو|pe|M;الإكوادور|ec|M;بوليفيا|bo|M;فنزويلا|ve|M;غيانا|gy|M;سورينام|sr|M;أمريكا|us|M;كندا|ca|M;المكسيك|mx|M;كوستاريكا|cr|M;بنما|pa|M;هندوراس|hn|M;السلفادور|sv|M;غواتيمالا|gt|M;نيكاراغوا|ni|M;بليز|bz|M;كوبا|cu|M;جامايكا|jm|M;هايتي|ht|M;جمهورية الدومينيكان|do|M;ترينيداد وتوباغو|tt|M;بربادوس|bb|M;الباهاماس|bs|M;بورتوريكو|pr|M;كوراساو|cw|M;سانت لوسيا|lc|M;غرينادا|gd|M
أستراليا|au|O;نيوزيلندا|nz|O;فيجي|fj|O;بابوا غينيا الجديدة|pg|O;جزر سليمان|sb|O;فانواتو|vu|O;ساموا|ws|O;تونغا|to|O;كاليدونيا الجديدة|nc|O;غوام|gu|O
''';

final List<Country> kAllCountries = () {
  final l = <Country>[];
  for (final part in _raw.split(RegExp(r'[;\n]'))) {
    final p = part.trim().split('|');
    if (p.length == 3) l.add(Country(p[0], p[1], p[2]));
  }
  l.sort((a, b) => a.name.compareTo(b.name));
  return l;
}();

Country? countryByName(String? n) {
  if (n == null) return null;
  for (final c in kAllCountries) {
    if (c.name == n) return c;
  }
  return null;
}

String flagEmoji(String iso) {
  if (iso == 'gb-eng') return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
  if (iso == 'gb-sct') return '🏴󠁧󠁢󠁳󠁣󠁴󠁿';
  if (iso == 'gb-wls') return '🏴󠁧󠁢󠁷󠁬󠁳󠁿';
  if (iso.length != 2) return '🌍';
  return String.fromCharCodes(iso.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
}

/// علم مستطيل صغير (صورة flagcdn مع بديل إيموجي)
class FlagRect extends StatelessWidget {
  final String iso;
  final double w;
  const FlagRect(this.iso, {super.key, this.w = 46});
  @override
  Widget build(BuildContext context) {
    final h = w * 0.68;
    final fb = Center(child: Text(flagEmoji(iso), style: TextStyle(fontSize: h * 0.7)));
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: kLine)),
      clipBehavior: Clip.antiAlias,
      child: iso == 'xk'
          ? fb
          : Unfilter(
              child: CachedNetworkImage(
                imageUrl: 'https://flagcdn.com/w80/$iso.png',
                fit: BoxFit.cover,
                placeholder: (_, __) => fb,
                errorWidget: (_, __, ___) => fb,
              ),
            ),
    );
  }
}
