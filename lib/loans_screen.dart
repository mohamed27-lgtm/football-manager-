import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'game_state.dart';
import 'squad.dart';
import 'widgets.dart';

/// الإعارات: لاعبون معارون إلينا ولاعبون أعرناهم
class LoansScreen extends StatefulWidget {
  final GameState gs;
  const LoansScreen({super.key, required this.gs});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  GameState get gs => widget.gs;
  int tab = 0;

  Widget _tile(String v, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Column(children: [
            Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: c)),
            Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعارات')),
      body: ListenableBuilder(
        listenable: gs,
        builder: (context, _) {
          final into = gs.user.squad.where((p) => p.onLoan).toList();
          final out = gs.loanedOut;
          final list = tab == 0 ? into : out;
          return ListView(padding: const EdgeInsets.all(14), children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: [
                ButtonSegment(value: 0, label: Text('معارون إلينا (${into.length})')),
                ButtonSegment(value: 1, label: Text('أعرناهم (${out.length})')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _tile('${into.length}', 'معارون إلينا', kPrimary),
              _tile('${out.length}', 'أعرناهم', const Color(0xFF6A6FC4)),
              _tile(gs.windowOpen ? 'مفتوح' : 'مغلق', 'سوق الانتقالات', gs.windowOpen ? const Color(0xFF1FA58A) : const Color(0xFFF5A524)),
            ]),
            const SizedBox(height: 12),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.compare_arrows_rounded,
                title: tab == 0 ? 'لا معارون إلينا' : 'لم تُعِر أحداً',
                subtitle: tab == 0 ? 'استعر لاعبين من سوق الانتقالات.' : 'يمكنك إعارة لاعب من صفحة الفريق خلال فترة الانتقالات.',
              )
            else
              Container(
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final p in list)
                    PlayerTile(
                      p: p,
                      onTap: () => showPlayerSheet(context, gs, p),
                      trailing: tab == 0 && p.optionFee != null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(p.obligation ? 'إلزامية ${money(p.optionFee!)}' : 'خيار ${money(p.optionFee!)}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                              if (!p.obligation)
                                GestureDetector(
                                  onTap: () {
                                    final err = gs.exerciseOption(p);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم تفعيل خيار الشراء ✅')));
                                  },
                                  child: const Text('تفعيل الخيار', style: TextStyle(color: Color(0xFF1FA58A), fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                            ])
                          : Text(tab == 0 ? 'حتى نهاية الموسم' : 'يعود نهاية الموسم', style: const TextStyle(color: kMuted, fontSize: 12)),
                    ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
