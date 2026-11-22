import 'package:flutter_test/flutter_test.dart';
import 'package:football_manager/last_match.dart';

LastMatch _m({required int hg, required int ag, required double xh, required double xa, int ph = 50, int sh = 10, int sa = 10, int th = 4, List<Map<String, dynamic>> ev = const []}) => LastMatch(
      comp: 'الدوري',
      round: 1,
      homeId: 1,
      awayId: 2,
      homeName: 'أ',
      awayName: 'ب',
      hg: hg,
      ag: ag,
      userHome: true,
      events: ev,
      stats: {
        'poss': [ph, 100 - ph],
        'shots': [sh, sa],
        'target': [th, 3],
        'xg': [xh, xa],
      },
      ratings: [
        {'id': 1, 'n': 'نجم', 'r': 8.1, 'h': true, 'p': 3},
        {'id': 2, 'n': 'ضعيف', 'r': 5.2, 'h': true, 'p': 1},
      ],
    );

void main() {
  test('تحليل المباراة: يقرأ xG والاستحواذ والتسديد والطرد', () {
    expect(_m(hg: 1, ag: 0, xh: 0.4, xa: 2.0).analysis().first, startsWith('فوز محظوظ'));
    expect(_m(hg: 0, ag: 1, xh: 2.1, xa: 0.5).analysis().first, startsWith('خسارة قاسية'));
    expect(_m(hg: 2, ag: 0, xh: 2.0, xa: 0.5).analysis().first, startsWith('فوز مستحق'));
    expect(_m(hg: 1, ag: 1, xh: 1.0, xa: 1.1).analysis().first, startsWith('تعادل عادل'));
    final a = _m(hg: 0, ag: 0, xh: 1, xa: 1, ph: 65, sh: 5, sa: 12).analysis();
    expect(a.any((s) => s.startsWith('سيطرة بلا أنياب')), isTrue);
    final b = _m(hg: 0, ag: 0, xh: 1, xa: 1, sh: 12, th: 2).analysis();
    expect(b.any((s) => s.startsWith('التسديد غير دقيق')), isTrue);
    final c = _m(hg: 1, ag: 0, xh: 1, xa: 0.5, ev: [{'m': 30, 't': 'red', 'h': true, 'a': 'x'}]).analysis();
    expect(c.any((s) => s.contains('بنقص عددي')), isTrue);
    expect(c.length, lessThanOrEqualTo(5));
    final d = _m(hg: 1, ag: 0, xh: 1, xa: 0.5).analysis();
    expect(d.any((s) => s.startsWith('أفضل لاعبيك: نجم')), isTrue);
    expect(d.any((s) => s.startsWith('الأضعف أداءً: ضعيف')), isTrue);
  });
}
