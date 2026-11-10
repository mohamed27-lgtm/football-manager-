import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'cups.dart';
import 'game_state.dart';
import 'models.dart';
import 'widgets.dart';
import 'trophies.dart';

/// مباراة في الشجرة (قد تكون فارغة لدور لم تُحسم أطرافه بعد)
class _VM {
  String? home, away;
  int? hg, ag;
  bool? homeWon;
  String? pen;
  bool get empty => home == null && away == null;
  String? get winner => homeWon == null ? null : (homeWon! ? home : away);
}

class _N {
  final _VM vm;
  final int round;
  _N? a, b;
  double y = 0;
  _N(this.vm, this.round);
}

/// شجرة الأدوار الإقصائية بخطوط وصل مثل Super Kickoff: نصفان متقابلان والنهائي في الوسط
class CupTree extends StatelessWidget {
  final GameState gs;
  final Cup cup;
  const CupTree({super.key, required this.gs, required this.cup});

  List<List<_VM>> _rounds() {
    final re = RegExp(r'^(.*?) (\d+)-(\d+) (.*?)( \(ر\.ج (\d+)-(\d+)\))?$');
    final byRound = <String, List<_VM>>{};
    for (final l in cup.log) {
      final i = l.indexOf('|');
      final key = l.substring(0, i);
      if (key.contains('مجموعات') || key.contains('مرحلة الدوري') || key == 'الملحق') continue;
      final m = re.firstMatch(l.substring(i + 1));
      if (m == null) continue;
      final v = _VM()
        ..home = m[1]
        ..away = m[4]
        ..hg = int.parse(m[2]!)
        ..ag = int.parse(m[3]!);
      if (m[5] != null) {
        v.pen = '(${m[6]}-${m[7]})';
        v.homeWon = int.parse(m[6]!) > int.parse(m[7]!);
      } else {
        v.homeWon = v.hg! > v.ag!;
      }
      byRound.putIfAbsent(key, () => []).add(v);
    }
    final rounds = byRound.values.toList();
    final playoff = cup.kind == 2 && cup.size == 32;
    if (!cup.done && !cup.inGroups && cup.ties.isNotEmpty && !playoff) {
      rounds.add([
        for (final t in cup.ties)
          _VM()
            ..home = gs.team(t.home).name
            ..away = gs.team(t.away).name
            ..hg = t.hg
            ..ag = t.ag
            ..homeWon = t.played ? t.winner == t.home : null
            ..pen = t.ph != null ? '(${t.ph}-${t.pa})' : null,
      ]);
    }
    if (rounds.isEmpty && cup.kind > 0) {
      rounds.add([for (var i = 0; i < (cup.kind == 2 ? 8 : 4); i++) _VM()]);
    }
    // أدوار مستقبلية فارغة حتى النهائي
    while (rounds.isNotEmpty && rounds.last.length > 1) {
      rounds.add([for (var i = 0; i < (rounds.last.length + 1) ~/ 2; i++) _VM()]);
    }
    return rounds;
  }

  _N _build(List<List<_VM>> rounds, int r, _VM vm, List<Set<_VM>> claimed) {
    final n = _N(vm, r);
    claimed[r].add(vm);
    if (r == 0) return n;
    final prev = rounds[r - 1];
    _VM? feeder(String? team) {
      if (team == null) return null;
      for (final p in prev) {
        if (!claimed[r - 1].contains(p) && p.winner == team) return p;
      }
      return null;
    }

    _VM? fa, fb;
    if (vm.empty) {
      final free = prev.where((p) => !claimed[r - 1].contains(p)).toList();
      if (free.isNotEmpty) fa = free[0];
      if (free.length > 1) fb = free[1];
    } else {
      fa = feeder(vm.home);
      if (fa != null) claimed[r - 1].add(fa);
      fb = feeder(vm.away);
      if (fa != null) claimed[r - 1].remove(fa);
    }
    if (fa != null) n.a = _build(rounds, r - 1, fa, claimed);
    if (fb != null) n.b = _build(rounds, r - 1, fb, claimed);
    return n;
  }

  double _layout(_N n, List<double> counter) {
    if (n.round == 0) {
      n.y = counter[0] + 0.5;
      counter[0] += 1;
      return n.y;
    }
    final span = pow(2, n.round - 1).toDouble();
    double slot(_N? c) {
      if (c != null) return _layout(c, counter);
      final y = counter[0] + span / 2;
      counter[0] += span;
      return y;
    }

    final ya = slot(n.a), yb = slot(n.b);
    n.y = (ya + yb) / 2;
    return n.y;
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _rounds();
    if (rounds.length < 2) return const SizedBox.shrink();
    final final0 = rounds.last.first;
    final claimed = [for (final _ in rounds) <_VM>{}];
    claimed.last.add(final0);
    final top = rounds.length - 2;
    final prev = rounds[top];
    // نصفا الشجرة: أول مباراتين تغذيان النهائي
    _VM? l, r;
    if (!final0.empty) {
      for (final p in prev) {
        if (p.winner != null && p.winner == final0.home) l ??= p;
        if (p.winner != null && p.winner == final0.away) r ??= p;
      }
    }
    final rest = prev.where((p) => p != l && p != r).toList();
    l ??= rest.isNotEmpty ? rest.removeAt(0) : null;
    r ??= rest.isNotEmpty ? rest.removeAt(0) : null;
    final left = l == null ? null : _build(rounds, top, l, claimed);
    final right = r == null ? null : _build(rounds, top, r, claimed);
    final lc = [0.0], rc = [0.0];
    if (left != null) _layout(left, lc);
    if (right != null) _layout(right, rc);
    final units = max(lc[0], rc[0]).clamp(1, 64).toDouble();
    final cols = 2 * rounds.length - 1;
    const rowH = 62.0;

    return LayoutBuilder(builder: (context, bc) {
      final w = bc.maxWidth - 8;
      final cw = w / cols;
      final cardW = cw - 8;
      final h = units * rowH + 70;
      final pos = <_N, Offset>{};
      final lines = <(Offset, Offset)>[];
      void place(_N? n, bool leftSide) {
        if (n == null) return;
        final col = leftSide ? n.round : cols - 1 - n.round;
        pos[n] = Offset(col * cw + 4, n.y * rowH);
        for (final c in [n.a, n.b]) {
          if (c == null) continue;
          place(c, leftSide);
        }
      }

      place(left, true);
      place(right, false);
      final finalPos = Offset((rounds.length - 1) * cw + 4, units * rowH / 2);
      void link(_N? n, Offset parent, bool leftSide) {
        if (n == null) return;
        final p = pos[n]!;
        final from = leftSide ? Offset(p.dx + cardW, p.dy) : Offset(p.dx, p.dy);
        final to = leftSide ? Offset(parent.dx, parent.dy) : Offset(parent.dx + cardW, parent.dy);
        lines.add((from, to));
        for (final c in [n.a, n.b]) {
          link(c, p, leftSide);
        }
      }

      link(left, finalPos, true);
      link(right, finalPos, false);

      Widget card(_VM v) {
        Widget row(String? name, int? g, bool win, bool lose) {
          final t = name == null ? null : _teamByName(name);
          return SizedBox(
            height: 25,
            child: Row(children: [
              if (t != null) teamBadge(t, size: 18) else Container(width: 18, height: 18, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(g == null ? '' : '$g', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: win ? FontWeight.w900 : FontWeight.w500, color: lose ? kMuted : (win ? kAccent : null))),
              ),
            ]),
          );
        }

        final won = v.homeWon;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: (v.home == gs.user.name || v.away == gs.user.name) ? kAccent : kLine)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            row(v.home, v.hg, won == true, won == false),
            row(v.away, v.ag, won == false, won == true),
            if (v.pen != null) Text(v.pen!, style: const TextStyle(fontSize: 9, color: kMuted)),
          ]),
        );
      }

      final children = <Widget>[
        Positioned.fill(child: CustomPaint(painter: _Lines(lines, finalPos, cardW, kLine))),
        for (final e in pos.entries) Positioned(left: e.value.dx, top: e.value.dy - 27, width: cardW, child: card(e.key.vm)),
        Positioned(left: finalPos.dx, top: finalPos.dy - 27, width: cardW, child: card(final0)),
      ];
      final champ = cup.done && cup.champion != null ? gs.team(cup.champion!) : null;
      return SizedBox(
        height: h,
        child: Stack(children: [
          ...children,
          Positioned(
            left: finalPos.dx - 8,
            top: finalPos.dy + 38,
            width: cardW + 16,
            child: Column(children: [
              trophyImage(trophyKey(cup.name, gs.leagueName), size: 44),
              if (champ != null) Text(champ.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      );
    });
  }

  Team? _teamByName(String n) {
    for (final t in [...gs.teams, ...gs.upper, ...gs.lower, ...gs.foreign.values]) {
      if (t.name == n) return t;
    }
    return null;
  }
}

class _Lines extends CustomPainter {
  final List<(Offset, Offset)> lines;
  final Offset fin;
  final double cardW;
  final Color color;
  _Lines(this.lines, this.fin, this.cardW, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final (a, b) in lines) {
      final mx = (a.dx + b.dx) / 2;
      canvas.drawPath(Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(mx, a.dy)
        ..lineTo(mx, b.dy)
        ..lineTo(b.dx, b.dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant _Lines old) => true;
}
