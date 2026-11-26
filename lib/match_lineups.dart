import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'engine.dart';
import 'models.dart';
import 'pitch_view.dart';
import 'widgets.dart';

/// تشكيلتا الفريقين أثناء المباراة، مع تبديل بالسحب والإفلات أو بالضغط (مثل Super Kickoff)
class LineupsPanel extends StatefulWidget {
  final MatchSim sim;
  final Side mine;
  final bool halftime;
  final VoidCallback onChanged;
  final VoidCallback onResume;
  const LineupsPanel({super.key, required this.sim, required this.mine, required this.halftime, required this.onChanged, required this.onResume});

  @override
  State<LineupsPanel> createState() => _LineupsPanelState();
}

class _LineupsPanelState extends State<LineupsPanel> {
  bool showMine = true;
  Player? picked; // لاعب محدد بالضغط (من الملعب أو من البدلاء)

  Side get _side => showMine ? widget.mine : (identical(widget.mine, widget.sim.home) ? widget.sim.away : widget.sim.home);

  String _formation(Side s) {
    int n(Pos p) => s.slots.where((x) => x.pos == p).length;
    return '${n(Pos.def)}-${n(Pos.mid)}-${n(Pos.att)}';
  }

  void _try(Player out, Player inn) {
    final err = widget.sim.substitute(widget.mine, out, inn, half: widget.halftime);
    setState(() => picked = null);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      widget.onChanged();
    }
  }

  void _tapPitch(Player p) {
    if (!showMine) return;
    final cur = picked;
    if (cur == null || widget.mine.slots.any((s) => s.p == cur)) {
      setState(() => picked = identical(cur, p) ? null : p);
    } else {
      _try(p, cur);
    }
  }

  void _tapBench(Player b) {
    final cur = picked;
    if (cur == null || widget.mine.bench.contains(cur)) {
      setState(() => picked = identical(cur, b) ? null : b);
    } else {
      _try(cur, b);
    }
  }

  void _instrSheet(Player p) {
    final t = widget.mine.team;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(8), child: Text('تعليمات ${p.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          ListTile(
            title: const Text('بلا تعليمات'),
            trailing: t.instr[p.id] == null ? const Icon(Icons.check) : null,
            onTap: () {
              t.instr.remove(p.id);
              Navigator.pop(ctx);
              setState(() {});
              widget.onChanged();
            },
          ),
          for (final e in kInstr.entries)
            ListTile(
              title: Text(e.value.$1),
              subtitle: Text(e.value.$2),
              trailing: t.instr[p.id] == e.key ? const Icon(Icons.check) : null,
              onTap: () {
                t.instr[p.id] = e.key;
                Navigator.pop(ctx);
                setState(() {});
                widget.onChanged();
              },
            ),
        ]),
      ),
    );
  }

  Widget _chip(Player p, {required bool onPitch, bool interactive = true, bool gone = false}) {
    final sel = identical(picked, p);
    final fit = p.fitness.round();
    final fitCol = fit >= 75 ? const Color(0xFF1FA58A) : (fit >= 55 ? const Color(0xFFF5A524) : const Color(0xFFE5533D));
    final face = Opacity(
      opacity: gone ? 0.4 : 1,
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: sel ? const Color(0x55FFEB3B) : Colors.transparent,
          border: sel ? Border.all(color: const Color(0xFFFFEB3B), width: 1.5) : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            playerFace(p, 34, ring: onPitch ? Colors.white : kMuted, ringWidth: 2),
            Positioned(
              right: -4,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: p.pos == Pos.gk ? const Color(0xFFFFB300) : const Color(0xFF2F7BE6), borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.white, width: 1)),
                child: Text('${p.overall}', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ]),
          const SizedBox(height: 3),
          Text(p.name.split(' ').last + (showMine && widget.mine.team.instr[p.id] != null ? ' ★' : ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: onPitch ? Colors.white : null, shadows: onPitch ? const [Shadow(color: Colors.black, blurRadius: 3)] : null)),
          const SizedBox(height: 2),
          SizedBox(
            width: 38,
            child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: fit / 100, minHeight: 3, color: fitCol, backgroundColor: Colors.black26)),
          ),
        ]),
      ),
    );
    if (!interactive || gone) return face;
    return DragTarget<Player>(
      onWillAcceptWithDetails: (d) => !identical(d.data, p),
      onAcceptWithDetails: (d) {
        final a = d.data, b = p;
        final aOn = widget.mine.slots.any((s) => s.p == a);
        final bOn = widget.mine.slots.any((s) => s.p == b);
        if (aOn == bOn) return; // سحب بين لاعبين من الجهة نفسها لا يعني تبديلاً
        aOn ? _try(a, b) : _try(b, a);
      },
      builder: (ctx, cand, rej) => Draggable<Player>(
        data: p,
        feedback: Material(color: Colors.transparent, child: Transform.scale(scale: 1.15, child: face)),
        childWhenDragging: Opacity(opacity: 0.35, child: face),
        child: GestureDetector(
          onTap: () => onPitch ? _tapPitch(p) : _tapBench(p),
          onLongPress: onPitch && showMine ? () => _instrSheet(p) : null,
          child: Container(decoration: cand.isNotEmpty ? BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1FA58A), width: 2)) : null, child: face),
        ),
      ),
    );
  }

  Widget _pitch(Side s) {
    final canDrag = showMine;
    return AspectRatio(
      aspectRatio: 0.82,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: PitchBackdrop(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final pos in showMine ? [Pos.att, Pos.mid, Pos.def, Pos.gk] : [Pos.gk, Pos.def, Pos.mid, Pos.att])
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final sl in s.slots.where((x) => x.pos == pos)) _chip(sl.p, onPitch: true, interactive: canDrag),
                ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _side;
    final sim = widget.sim;
    final mine = widget.mine;
    final subs = [for (final x in s.subLog) x];
    final block = showMine ? sim.subBlock(mine, half: widget.halftime) : null;
    return ListView(padding: const EdgeInsets.fromLTRB(10, 8, 10, 14), children: [
      Row(children: [
        Expanded(
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(mine.team.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
              ButtonSegment(value: false, label: Text((identical(mine, sim.home) ? sim.away : sim.home).team.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
            ],
            selected: {showMine},
            onSelectionChanged: (v) => setState(() {
              showMine = v.first;
              picked = null;
            }),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('التشكيلة ${_formation(s)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        const Spacer(),
        Text('التبديلات ${5 - s.subsLeft}/5 • الفرص ${s.subWindows}/3', style: const TextStyle(color: kMuted, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      _pitch(s),
      if (showMine) ...[
        const SizedBox(height: 10),
        Text(widget.halftime ? 'اسحب لاعباً من البدلاء إلى لاعب في الملعب (أو اضغط الاثنين). الاستراحة لا تُحتسب فرصة.' : 'اسحب لاعباً من البدلاء إلى لاعب في الملعب (أو اضغط الاثنين) لتبديله. اضغط مطولاً على لاعب لإعطائه تعليمات (★).', style: const TextStyle(color: kMuted, fontSize: 12)),
        if (block != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(block, style: const TextStyle(color: Color(0xFFE5533D), fontSize: 12, fontWeight: FontWeight.w800))),
        const SizedBox(height: 8),
        const Text('البدلاء', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final b in mine.bench) _chip(b, onPitch: false),
          if (mine.bench.isEmpty) const Text('لا يوجد لاعبون على مقاعد البدلاء', style: TextStyle(color: kMuted, fontSize: 12)),
        ]),
      ],
      if (subs.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('التبديلات التي تمت', style: TextStyle(fontWeight: FontWeight.w900)),
        for (final x in subs)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text("${x.minute}' ⬆ ${x.inn.name}  ⬇ ${x.out.name}", style: const TextStyle(fontSize: 12.5)),
          ),
      ],
      const SizedBox(height: 12),
      if (showMine)
        FilledButton.icon(onPressed: widget.onResume, icon: const Icon(Icons.play_arrow), label: Text(sim.finished ? 'انتهت المباراة' : 'متابعة اللعب')),
    ]);
  }
}
