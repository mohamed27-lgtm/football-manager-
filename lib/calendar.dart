/// تقويم الموسم: تاريخ كل أسبوع، ويوم ووقت كل بطولة
class KickSlot {
  final int day; // 0 = الاثنين … 6 = الأحد (ضمن أسبوع اللعبة)
  final String time;
  const KickSlot(this.day, this.time);
}

class GameCalendar {
  static const dayNames = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  /// بداية الموسم: الاثنين الأقرب إلى 10 أغسطس من سنة الموسم (الموسم 1 = 2026)
  static DateTime seasonStart(int season) {
    final d = DateTime.utc(2025 + season, 8, 10);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// بداية أسبوع اللعبة (الاثنين) مع توقف شتوي أسبوعين بعد 21 ديسمبر
  static DateTime weekStart(int season, int week) {
    final start = seasonStart(season);
    var d = start.add(Duration(days: 7 * week));
    final winter = DateTime.utc(start.year, 12, 21);
    if (!d.isBefore(winter)) d = d.add(const Duration(days: 14));
    return d;
  }

  static DateTime dateOf(int season, int week, int day) => weekStart(season, week).add(Duration(days: day));

  static String fmt(DateTime d) => '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]}';
  static String fmtShort(DateTime d) => '${d.day} ${monthNames[d.month - 1]}';

  /// الدوري: الجمعة أو السبت أو الأحد
  static KickSlot league(int home, int away, int week, int season) {
    final h = (home * 7 + away * 13 + week * 5 + season * 3) % 3;
    return KickSlot(4 + h, const ['21:00', '18:30', '20:45'][(home + away + week) % 3]);
  }

  /// البطولات الإقصائية: لكل بطولة يومها ووقتها كما في الواقع
  static KickSlot cup(String key, int round, int home, int away) {
    switch (key) {
      case 'con': // دوري الأبطال: الثلاثاء أو الأربعاء 22:00
        return KickSlot(1 + (home + away + round) % 2, '22:00');
      case 'uel': // الدوري الأوروبي: الخميس 22:00
        return const KickSlot(3, '22:00');
      case 'uecl': // دوري المؤتمر: الخميس 19:45
        return const KickSlot(3, '19:45');
      case 'sup': // كأس السوبر
        return const KickSlot(2, '21:00');
      default: // الكأس المحلي: الأربعاء 21:00
        return const KickSlot(2, '21:00');
    }
  }
}
