/// صفقة رعاية (أسماء علامات تجارية حقيقية للمحاكاة فقط، بلا شعارات)
class SponsorDeal {
  final String type; // shirt / kit / stadium
  final String brand;
  final double weekly;
  int years;
  SponsorDeal(this.type, this.brand, this.weekly, this.years);

  Map<String, dynamic> toJson() => {'t': type, 'b': brand, 'w': weekly, 'y': years};
  factory SponsorDeal.fromJson(Map<String, dynamic> j) =>
      SponsorDeal(j['t'] as String, j['b'] as String, (j['w'] as num).toDouble(), j['y'] as int);
}

class SponsorOffer {
  final SponsorDeal deal;
  final double bonus;
  const SponsorOffer(this.deal, this.bonus);
  Map<String, dynamic> toJson() => {...deal.toJson(), 'bonus': bonus};
  factory SponsorOffer.fromJson(Map<String, dynamic> j) =>
      SponsorOffer(SponsorDeal.fromJson(j), (j['bonus'] as num).toDouble());
}

const sponsorTypes = <String, String>{
  'shirt': 'راعي القميص',
  'kit': 'مصنّع الأطقم',
  'stadium': 'تسمية الملعب',
};

/// (الاسم، فئة 1 الأعلى … 3، شعبية مطلوبة)
const sponsorBrands = <String, List<(String, int)>>{
  'shirt': [
    ('Emirates', 1), ('Qatar Airways', 1), ('Etihad Airways', 1), ('Samsung', 1),
    ('Rakuten', 2), ('Allianz', 2), ('Turkish Airlines', 2), ('Orange', 2), ('Spotify', 2),
    ('Ooredoo', 3), ('Huawei', 3), ('Coca-Cola', 3), ('Visit Rwanda', 3),
  ],
  'kit': [
    ('Nike', 1), ('Adidas', 1), ('Puma', 1),
    ('Umbro', 2), ('New Balance', 2), ('Kappa', 2),
    ('Macron', 3), ('Joma', 3), ('Hummel', 3),
  ],
  'stadium': [
    ('Etihad', 1), ('Emirates', 1), ('Allianz', 2), ('Signal Iduna', 2),
    ('Vodafone', 2), ('Orange', 3), ('Ooredoo', 3), ('Carrefour', 3),
  ],
};

const tierMult = {1: 1.45, 2: 1.1, 3: 0.8};
const tierFans = {1: 62.0, 2: 38.0, 3: 0.0};
const typeMult = {'shirt': 1.0, 'kit': 0.65, 'stadium': 0.5};
