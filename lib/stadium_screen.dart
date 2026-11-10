import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'widgets.dart';

class StadiumScreen extends StatefulWidget {
  final GameState gs;
  const StadiumScreen({super.key, required this.gs});
  @override
  State<StadiumScreen> createState() => _StadiumScreenState();
}

class _StadiumScreenState extends State<StadiumScreen> {
  GameState get gs => widget.gs;
  int tab = 0;
  static const _teal = Color(0xFF1FA58A);
  static const _names = ['أسعار رخيصة', 'أسعار عادية', 'أسعار مرتفعة'];
  static const _desc = [
    'حضور أعلى ورضا جماهيري، لكن دخل أقل (×0.8).',
    'توازن بين الدخل والحضور (×1.0).',
    'دخل أعلى (×1.25) لكن الحضور والرضا ينخفضان.',
  ];

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: child,
      );

  String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  Widget _bar(String l, double v, Color c, String r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          Row(children: [
            Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(r, style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: v.clamp(0, 1).toDouble(), minHeight: 8, color: c, backgroundColor: kCard2)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملعب')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final lvl = gs.user.stadium;
          final cap = gs.stadiumCapacity;
          final att = gs.attendance;
          final gate = (0.3 + 0.12 * gs.user.reputation) * (0.7 + 0.15 * lvl) * (0.75 + 0.5 * gs.fans / 100) * GameState.ticketMult[gs.ticketLevel];
          return ListView(padding: const EdgeInsets.all(14), children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 0, label: Text('نظرة عامة', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 1, label: Text('التذاكر', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 2, label: Text('الحضور', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 3, label: Text('التوسعة', style: TextStyle(fontSize: 12))),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _tile(_n(cap), 'السعة', kPrimary),
              _tile('${(gs.fillRate * 100).round()}%', 'الإشغال', _teal),
              _tile(money(gate), 'دخل المباراة', const Color(0xFFF5A524)),
            ]),
            if (tab == 0) ...[
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.stadium_rounded, color: kPrimary),
                  const SizedBox(width: 8),
                  Text('ملعب ${gs.user.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  Text('المستوى $lvl/5', style: const TextStyle(color: kMuted)),
                ]),
                const SizedBox(height: 12),
                _bar('الحضور المتوقع', att / cap, _teal, _n(att)),
                _bar('الشعبية', gs.fans / 100, kPrimary, '${gs.fans.round()}%'),
                _bar('مستوى الملعب', lvl / 5, const Color(0xFF6A6FC4), '$lvl/5'),
              ])),
            ],
            if (tab == 1) ...[
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('سياسة أسعار التذاكر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: [for (var i = 0; i < 3; i++) ButtonSegment(value: i, label: Text(_names[i], style: const TextStyle(fontSize: 12)))],
                  selected: {gs.ticketLevel},
                  onSelectionChanged: (v) => gs.setTicketLevel(v.first),
                ),
                const SizedBox(height: 10),
                Text(_desc[gs.ticketLevel], style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
              ])),
              _card(Column(children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Text(_names[i], style: TextStyle(fontWeight: i == gs.ticketLevel ? FontWeight.w900 : FontWeight.w500, color: i == gs.ticketLevel ? kPrimary : null)),
                      const Spacer(),
                      Text('×${GameState.ticketMult[i]}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ]),
                  ),
              ])),
            ],
            if (tab == 2) ...[
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('عوامل الحضور', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 12),
                _bar('الشعبية', gs.fans / 100, kPrimary, '${gs.fans.round()}%'),
                _bar('سياسة الأسعار', 1 - gs.ticketLevel * 0.25, const Color(0xFFF5A524), _names[gs.ticketLevel]),
                _bar('الإشغال', gs.fillRate, _teal, '${(gs.fillRate * 100).round()}%'),
                const SizedBox(height: 4),
                Text('الحضور المتوقع: ${_n(att)} من ${_n(cap)} متفرج. الفوز المتكرر والألقاب ترفع الشعبية.', style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.5)),
              ])),
            ],
            if (tab == 3) ...[
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('توسعة الملعب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 8),
                Text(lvl >= 5 ? 'وصل الملعب إلى أقصى مستوى.' : 'المستوى التالي: السعة ${_n(12000 + 8000 * (lvl + 1))} ودخل أعلى لكل مباراة.', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                const SizedBox(height: 12),
                if (lvl < 5)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: 'ترقية الملعب (${money(gs.upgradeCost(lvl))})',
                      icon: Icons.upgrade_rounded,
                      onPressed: () {
                        final err = gs.upgrade('stadium');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تمت ترقية الملعب 🏗️')));
                      },
                    ),
                  ),
              ])),
            ],
          ]);
        },
      ),
    );
  }
}
