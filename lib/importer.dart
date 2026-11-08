import 'dart:math';
import 'api_football.dart';
import 'data.dart';
import 'models.dart';

Pos _pos(String s) => switch (s.toLowerCase()) {
      'goalkeeper' => Pos.gk,
      'defender' => Pos.def,
      'attacker' => Pos.att,
      _ => Pos.mid,
    };

/// الـ API لا يوفر تقييمات، لذا نشتقها من قوة الفريق (ترتيبه) ومستوى الدوري
/// مع تباين ثابت لكل لاعب (يعتمد على معرّفه) فتبقى القيم نفسها في كل مرة.
Player playerFromApi(ApiPlayer ap, int teamBase) {
  final h = Random(ap.id);
  if (ap.ov != null) {
    // لاعب حقيقي من Transfermarkt: التقييم مشتق من قيمته السوقية
    final age = (ap.age ?? 25).clamp(15, 43).toInt();
    final p = makePlayer(h, _pos(ap.position), ap.ov!, age, name: ap.name, photo: ap.photo);
    p
      ..potential = max(ap.pot ?? p.overall, p.overall)
      ..contract = (ap.contract ?? 2).clamp(1, 5).toInt()
      ..nat = ap.nat
      ..sub = ap.sub
      ..foot = ap.foot
      ..height = ap.height
      ..mv0 = ap.value
      ..ov0 = p.overall
      ..age0 = age;
    return p;
  }
  final age = (ap.age ?? 25).clamp(16, 42).toInt();
  final adj = age <= 20 ? -4 : age <= 23 ? -1 : age <= 30 ? 1 : age <= 33 ? 0 : -3;
  final ov = (teamBase + h.nextInt(15) - 7 + adj).clamp(40, 92).toInt();
  return makePlayer(h, _pos(ap.position), ov, age, name: ap.name, photo: ap.photo);
}

List<Team> teamsFromLeague(LeagueData d, Random rng) {
  final src = [...d.teams]..sort((a, b) => a.rank.compareTo(b.rank));
  if (src.length.isOdd) src.removeLast(); // الجدول يتطلب عدداً زوجياً
  final n = src.length;
  final base = switch (d.tier) {
    1 => 70,
    2 => 66,
    _ => 62,
  };
  final out = <Team>[];
  for (var i = 0; i < n; i++) {
    final t = src[i];
    final p = n <= 1 ? 0.5 : i / (n - 1);
    final tb = base + ((0.5 - p) * 14).round();
    final rep = p < 0.15 ? 5 : p < 0.35 ? 4 : p < 0.65 ? 3 : 2;
    final squad = [for (final ap in t.players) playerFromApi(ap, tb)]
      ..sort((a, b) => b.overall.compareTo(a.overall));
    if (squad.length > 28) squad.removeRange(28, squad.length);
    final team = Team(
      id: i,
      name: t.name,
      reputation: rep,
      squad: squad,
      budget: 12.0 + rep * 8,
    )
      ..badge = t.logo
      ..venue = t.venue;
    topUpSquad(team, rng);
    // ميزانية واقعية من القيمة السوقية الحقيقية للتشكيلة (نحو 12٪ منها)
    if (t.players.any((x) => x.ov != null)) {
      final sv = team.squad.fold<double>(0, (a, x) => a + x.value);
      team.budget = (0.12 * sv).clamp(5.0, 220.0).toDouble();
    }
    team.autoPick();
    out.add(team);
  }
  return out;
}
