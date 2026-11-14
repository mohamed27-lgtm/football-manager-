part of 'game_state.dart';

/// وجهة إعارة مقترحة للاعب
class LoanOption {
  final Team club;
  final String tier; // مستوى أدنى / نفس المستوى / مستوى أعلى
  final int role; // 0 بديل غالباً، 1 مشارك بانتظام، 2 أساسي
  const LoanOption(this.club, this.tier, this.role);
  String get roleLabel => const ['بديل في الغالب', 'مشارك بانتظام', 'أساسي مضمون'][role];
  String get minutesLabel => const ['أقل من 25% من الدقائق', 'نحو 55% من الدقائق', 'أكثر من 80% من الدقائق'][role];
}

extension LoansLogic on GameState {
  int _roleAt(Player p, Team t) {
    final d = p.overall - t.strength;
    return d >= 2 ? 2 : (d >= -4 ? 1 : 0);
  }

  /// ثلاث وجهات: درجة أدنى (دقائق أكثر)، نادٍ بمستواه، ونادٍ أقوى (مستوى أعلى لكن دقائق أقل)
  List<LoanOption> loanOptions(Player p) {
    final r = Random(p.id * 31 + week);
    List<Team> sh(Iterable<Team> xs) => ([...xs.where((t) => t.name != user.name)]..shuffle(r));
    final res = <LoanOption>[];
    final low = sh(lower);
    if (low.isNotEmpty) {
      low.sort((a, b) => _roleAt(p, b).compareTo(_roleAt(p, a)));
      res.add(LoanOption(low.first, 'مستوى أدنى', _roleAt(p, low.first)));
    }
    final mid = sh(teams);
    if (mid.isNotEmpty) {
      mid.sort((a, b) => (p.overall - a.strength + 1).abs().compareTo((p.overall - b.strength + 1).abs()));
      res.add(LoanOption(mid.first, 'نفس المستوى', _roleAt(p, mid.first)));
    }
    final up = sh(upper.isNotEmpty ? upper : teams.where((t) => t.strength > p.overall));
    if (up.isNotEmpty) {
      up.sort((a, b) => a.strength.compareTo(b.strength));
      final t = up[min(up.length - 1, r.nextInt(3))];
      res.add(LoanOption(t, 'مستوى أعلى', _roleAt(p, t)));
    }
    return res;
  }

  /// كل جولة: يشارك المعار حسب دوره، وتتراكم دقائقه وأهدافه
  void loanTick() {
    for (final p in loanedOut) {
      if (p.loanClub == null) continue;
      final role = p.loanRole;
      if (rng.nextDouble() >= const [0.22, 0.6, 0.92][role]) continue;
      p.loanApps++;
      final mins = switch (role) { 2 => 80 + rng.nextInt(11), 1 => 35 + rng.nextInt(56), _ => 12 + rng.nextInt(25) };
      p.loanMins += mins;
      final pg = switch (p.pos) { Pos.att => 0.36, Pos.mid => 0.12, Pos.def => 0.04, Pos.gk => 0.0 } * (p.overall / 68.0) * mins / 90.0;
      if (rng.nextDouble() < pg) {
        p.loanGoals++;
        if (p.loanGoals == 1 || p.loanGoals % 5 == 0) {
          news.insert(0, '⚽ ${p.name} يسجّل مع ${p.loanClub} (${p.loanGoals} أهداف في ${p.loanApps} مباراة)');
        }
      }
    }
    if (week % 8 == 0) {
      for (final p in loanedOut) {
        if (p.loanClub != null && p.loanRole == 0 && p.loanApps < 3 && week > 8) {
          news.insert(0, '😕 ${p.name} لا يحصل على دقائق كافية مع ${p.loanClub}');
        }
      }
    }
  }

  /// استدعاء معار خلال فترة الانتقالات
  String? recallLoan(Player p) {
    if (!windowOpen) return 'لا يمكن الاستدعاء إلا خلال فترة الانتقالات';
    if (!loanedOut.contains(p)) return 'اللاعب غير معار';
    loanedOut.remove(p);
    _clearLoan(p);
    user.squad.add(p);
    news.insert(0, '↩️ استدعيت ${p.name} من إعارته');
    unawaited(save());
    notifyListeners();
    return null;
  }

  void _clearLoan(Player p) {
    p.loanClub = null;
    p.loanApps = 0;
    p.loanMins = 0;
    p.loanGoals = 0;
  }

  /// نهاية الموسم: النمو يتبع الدقائق الفعلية لا مجرد الإعارة
  void settleLoan(Player p) {
    final apps = p.loanApps, mins = p.loanMins;
    final ratio = (mins / 3000.0).clamp(0.0, 1.0);
    final club = p.loanClub ?? '';
    if (p.age <= 22 && p.overall < p.potential) {
      final room = p.potential - p.overall;
      final g = ratio >= 0.6 ? 1 + rng.nextInt(3) : ratio >= 0.3 ? rng.nextInt(2) : 0;
      final gg = min(room, g);
      if (gg > 0) {
        _grow(p, gg);
        news.insert(0, '📈 تطور ${p.name} خلال إعارته مع $club (+$gg) — $apps مباراة، $mins دقيقة');
      } else if (ratio < 0.2) {
        news.insert(0, '😕 ${p.name} لم يحصل على دقائق كافية مع $club ($apps مباراة) فلم يتطور');
        p.morale = max(30, p.morale - 8);
      }
    }
    _clearLoan(p);
  }
}
