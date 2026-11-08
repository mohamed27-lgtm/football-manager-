import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'widgets.dart';

/// رموز ISO للدول (بالأسماء العربية المستخدمة في الدوريات)
const kCountryIso = <String, String>{
  'إنجلترا': 'gb-eng', 'إسكتلندا': 'gb-sct', 'ويلز': 'gb-wls', 'إسبانيا': 'es', 'إيطاليا': 'it', 'ألمانيا': 'de',
  'فرنسا': 'fr', 'السعودية': 'sa', 'المغرب': 'ma', 'مصر': 'eg', 'البرتغال': 'pt', 'هولندا': 'nl', 'تركيا': 'tr',
  'بلجيكا': 'be', 'أمريكا': 'us', 'البرازيل': 'br', 'الأرجنتين': 'ar', 'المكسيك': 'mx', 'الجزائر': 'dz',
  'تونس': 'tn', 'الإمارات': 'ae', 'قطر': 'qa', 'روسيا': 'ru', 'أوكرانيا': 'ua', 'اليونان': 'gr', 'سويسرا': 'ch',
  'النمسا': 'at', 'الدنمارك': 'dk', 'السويد': 'se', 'النرويج': 'no', 'بولندا': 'pl', 'التشيك': 'cz',
  'اليابان': 'jp', 'كوريا الجنوبية': 'kr', 'الصين': 'cn', 'أيرلندا': 'ie',
};

String? _emoji(String? iso) {
  if (iso == null) return null;
  if (iso == 'gb-eng') return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
  if (iso == 'gb-sct') return '🏴󠁧󠁢󠁳󠁣󠁴󠁿';
  if (iso == 'gb-wls') return '🏴󠁧󠁢󠁷󠁬󠁳󠁿';
  if (iso.length != 2) return null;
  return String.fromCharCodes(iso.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
}

/// علم دائري احترافي: صورة من الإنترنت مع بديل إيموجي يعمل بدون اتصال
class FlagBadge extends StatelessWidget {
  final String country;
  final double size;
  const FlagBadge(this.country, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final iso = kCountryIso[country];
    final fallback = Center(
      child: Text(_emoji(iso) ?? '🌍', style: TextStyle(fontSize: size * 0.55)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kCard2,
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: iso == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: 'https://flagcdn.com/w160/$iso.png',
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

/// كأس محلي وسوبر لكل دوري (معرّفات API-Sports)
const kDomesticCupId = <int, int>{39: 45, 140: 143, 135: 137, 78: 81, 61: 66, 94: 96, 88: 90, 203: 206, 144: 147};
const kSuperCupId = <int, int>{39: 528, 140: 556, 135: 547, 78: 529, 61: 526};

/// شعار بطولة محفوظ في المستودع (assets/logos) مع أيقونة بديلة
class CompLogo extends StatelessWidget {
  final int? id;
  final IconData fallback;
  final Color color;
  final double size;
  const CompLogo(this.id, {super.key, required this.fallback, required this.color, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(fallback, color: color, size: size);
    if (id == null || id == 0) return icon;
    return Image.asset('assets/logos/$id.png', width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => icon);
  }
}
