import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'countries.dart' show countryByName;
import 'widgets.dart';
import 'logo_store.dart';

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

/// علم مستطيل طبيعي (نسبة 4:3) كما هو في كل صفحات اللعبة: صورة من الإنترنت مع بديل إيموجي يعمل بدون اتصال
class FlagBadge extends StatelessWidget {
  final String country;
  final double size;
  const FlagBadge(this.country, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final iso = kCountryIso[country] ?? countryByName(country)?.iso;
    final fallback = Center(
      child: Text(_emoji(iso) ?? '🌍', style: TextStyle(fontSize: size * 0.5)),
    );
    final h = size * 0.74;
    return Container(
      width: size * 1.1,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.08 + 1),
        color: kCard2,
        border: Border.all(color: Colors.black26, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: iso == null
          ? fallback
          : Unfilter(
              child: CachedNetworkImage(
                imageUrl: 'https://flagcdn.com/w160/$iso.png',
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
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
  final bool unfilter; // false حين تكون داخل Unfilter أصلاً
  const CompLogo(this.id, {super.key, required this.fallback, required this.color, this.size = 34, this.unfilter = true});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(fallback, color: color, size: size);
    if (id == null || id == 0) return icon;
    return ValueListenableBuilder<int>(
      valueListenable: LogoStore.version,
      builder: (_, __, ___) {
        final f = LogoStore.file(id!);
        final asset = Image.asset('assets/logos/$id.png', width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => icon);
        final w = f == null ? asset : Image.file(f, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => asset);
        return unfilter ? Unfilter(child: w) : w;
      },
    );
  }
}

/// معرّفات شعارات بطولات المنتخبات (API-Sports)
const kNatTourLogoId = <String, int>{'wc': 1, 'euro': 4, 'afcon': 6, 'asia': 7, 'copa': 9, 'gold': 22};

/// معرّف شعار بطولة قارية حسب الاتحاد
const kConfedCupLogoId = <String, int>{'uefa': 2, 'caf': 12, 'afc': 17, 'conmebol': 13, 'concacaf': 16};
const kConfedSecondLogoId = <String, int>{'uefa': 3, 'conmebol': 11};
