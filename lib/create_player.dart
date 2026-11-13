import 'dart:io';
import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'countries.dart';
import 'data.dart';
import 'game_state.dart';
import 'i18n.dart';
import 'models.dart';
import 'widgets.dart';

const _skillNames = ['السرعة', 'التسديد', 'التمرير', 'المراوغة', 'الدفاع', 'القوة'];
const _traitNames = ['صاروخ', 'مراوغ', 'قائد', 'بديهة', 'هادئ'];
// مكافأة كل سمة على إحدى المهارات (index)
const _traitBonus = {'صاروخ': 0, 'مراوغ': 3, 'قائد': 2, 'بديهة': 2, 'هادئ': 1};
const _bases = {
  Pos.gk: [40, 20, 45, 25, 60, 55],
  Pos.def: [52, 30, 48, 38, 65, 62],
  Pos.mid: [58, 50, 66, 58, 48, 50],
  Pos.att: [70, 65, 50, 62, 28, 45],
};
const _totalPoints = 30;

Color _skillColor(int v) => v >= 60 ? const Color(0xFF1FA58A) : (v >= 40 ? const Color(0xFF2F7BE6) : const Color(0xFFF5A524));

/// تحويل المهارات الست إلى سمات المحرك
Player _build(String name, Pos pos, int age, int height, String foot, String nat, String? nat2, String? photo, List<int> sk, List<String> traits, {bool real = false}) {
  final s = [...sk];
  for (final t in traits) {
    final i = _traitBonus[t]!;
    s[i] = (s[i] + 3).clamp(0, 99);
  }
  final atk = (0.45 * s[1] + 0.3 * s[3] + 0.25 * s[0]).round();
  final def = (0.7 * s[4] + 0.3 * s[5]).round();
  final gk = (0.6 * s[4] + 0.4 * s[5]).round();
  if (real) pidCounter = pidCounter + 1;
  final p = Player(id: real ? pidCounter : -1, name: name, age: age, pos: pos, atk: atk, def: def, pas: s[2], gk: pos == Pos.gk ? gk : 10, potential: 0, contract: 3, photo: photo)
    ..nat = nat
    ..nat2 = nat2
    ..foot = foot
    ..height = height
    ..sk = s
    ..traits = traits;
  final ov = p.overall;
  p.potential = (ov + 4 + (((24 - age).clamp(0, 8)) * 1.5).round()).clamp(ov, 95);
  return p;
}

class CreatePlayerScreen extends StatefulWidget {
  final GameState gs;
  const CreatePlayerScreen({super.key, required this.gs});
  @override
  State<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends State<CreatePlayerScreen> {
  GameState get gs => widget.gs;
  int step = 0;
  final name = TextEditingController();
  String nat = 'المغرب';
  String? nat2;
  Pos pos = Pos.att;
  String foot = 'اليمنى';
  int age = 17, height = 178;
  String? photo;
  late List<int> skills = [..._bases[pos]!];
  final Set<String> traits = {};

  int get left => _totalPoints - (skills.fold<int>(0, (a, b) => a + b) - _bases[pos]!.fold<int>(0, (a, b) => a + b));

  Player get preview => _build(name.text.isEmpty ? '—' : name.text, pos, age, height, foot, nat, nat2, photo, skills, traits.toList());

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 600, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = '${dir.path}/cp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(dest);
      if (mounted) setState(() => photo = dest);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر اختيار الصورة')));
    }
  }

  Future<String?> _pickCountry(String? current) => showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CountrySheet(current: current),
      );

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(t, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800)));

  Widget _seg<T>(List<(T, String)> items, T cur, void Function(T) on) => Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => on(items[i].$1),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cur == items[i].$1 ? kNavy : kCard, borderRadius: BorderRadius.circular(10)),
                child: Text(items[i].$2, style: TextStyle(fontWeight: FontWeight.w900, color: cur == items[i].$1 ? Colors.white : kMuted)),
              ),
            ),
          ),
        ],
      ]);

  Widget _stepper(String label, bool on, int n, bool done) => Expanded(
        child: Column(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? kPrimary : kCard2, shape: BoxShape.circle),
            child: Text('$n', style: TextStyle(fontWeight: FontWeight.w900, color: on ? Colors.white : kMuted)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: on ? null : kMuted)),
        ]),
      );

  Widget _btn(String label, Color bg, Color fg, VoidCallback? on, {IconData? icon}) => GestureDetector(
        onTap: on,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), offset: const Offset(0, 3))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 16)),
            if (icon != null) ...[const SizedBox(width: 10), Icon(icon, color: fg)],
          ]),
        ),
      );

  Widget _stepBtn(IconData i, bool plus, VoidCallback? on) => GestureDetector(
        onTap: on,
        child: Opacity(
          opacity: on == null ? 0.4 : 1,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: plus ? kPrimary : const Color(0xFFA9D4F8), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 2))]),
            child: Icon(i, color: plus ? Colors.white : kNavy, size: 26),
          ),
        ),
      );

  Widget _counter(String label, String value, VoidCallback? minus, VoidCallback? plus) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _stepBtn(Icons.add, true, plus),
            Expanded(child: Column(children: [Text(label, style: const TextStyle(color: kMuted, fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))])),
            _stepBtn(Icons.remove, false, minus),
          ]),
        ),
      );

  Widget _step1() {
    final c = countryByName(nat);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(
          child: Column(children: [
            Row(children: [
              Expanded(child: _btn('المعرض', const Color(0xFFA9D4F8), kNavy, () => _pick(ImageSource.gallery), icon: Icons.photo_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _btn('الكاميرا', kPrimary, Colors.white, () => _pick(ImageSource.camera), icon: Icons.photo_camera_outlined)),
            ]),
            const SizedBox(height: 10),
            const Text('اختر صورتك بنفسك — يُقصّ تلقائياً على شكل دائري', style: TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 14),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(shape: BoxShape.circle, color: kCard, border: Border.all(color: kMuted.withOpacity(0.5), width: 2)),
          clipBehavior: Clip.antiAlias,
          child: photo != null
              ? Image.file(File(photo!), fit: BoxFit.cover)
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.photo_camera_outlined, color: kPrimary, size: 30),
                  Text('صورة اللاعب', style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
        ),
      ]),
      _label('اسم اللاعب'),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), hintText: tr('اكتب الاسم'), hintStyle: const TextStyle(color: kMuted)),
        ),
      ),
      _label('الجنسية'),
      GestureDetector(
        onTap: () async {
          final r = await _pickCountry(nat);
          if (r != null) setState(() => nat = r);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            if (c != null) FlagRect(c.iso),
            const SizedBox(width: 12),
            Expanded(child: Text(nat, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          if (nat2 != null) {
            setState(() => nat2 = null);
            return;
          }
          final r = await _pickCountry(null);
          if (r != null && r != nat) setState(() => nat2 = r);
        },
        child: Text(nat2 == null ? '+ إضافة جنسية ثانية (اختياري)' : 'الجنسية الثانية: $nat2 (اضغط للإزالة)', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
      ),
      _label('المركز'),
      _seg<Pos>([(Pos.gk, 'حارس'), (Pos.def, 'مدافع'), (Pos.mid, 'وسط'), (Pos.att, 'مهاجم')], pos, (v) => setState(() {
            pos = v;
            skills = [..._bases[v]!];
          })),
      _label('القدم المفضلة'),
      _seg<String>([('اليمنى', 'اليمنى'), ('اليسرى', 'اليسرى'), ('الاثنتان', 'الاثنتان')], foot, (v) => setState(() => foot = v)),
      const SizedBox(height: 14),
      Row(children: [
        _counter('العمر', '$age سنة', age > 16 ? () => setState(() => age--) : null, age < 34 ? () => setState(() => age++) : null),
        const SizedBox(width: 12),
        _counter('الطول', '$height سم', height > 160 ? () => setState(() => height--) : null, height < 205 ? () => setState(() => height++) : null),
      ]),
    ]);
  }

  Widget _step2() {
    final ov = preview.overall;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 84, height: 84, child: CircularProgressIndicator(value: left / _totalPoints, strokeWidth: 9, color: kPrimary, backgroundColor: kCard2)),
              Text('$left', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('نقاط متبقية للتوزيع', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text('وزّع $_totalPoints نقطة على المهارات', style: TextStyle(color: kMuted, fontSize: 13)),
            ]),
          ),
          Column(children: [ratingRing(ov, size: 52), const Text('التقييم', style: TextStyle(color: kMuted, fontSize: 11))]),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < 6; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(border: i == 5 ? null : const Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [
                _stepBtn(Icons.add, true, left > 0 && skills[i] < 99 ? () => setState(() => skills[i]++) : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(children: [
                    Row(children: [
                      Text(_skillNames[i], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const Spacer(),
                      Text('${skills[i]}', style: TextStyle(fontWeight: FontWeight.w900, color: _skillColor(skills[i]))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: skills[i] / 100, minHeight: 7, color: _skillColor(skills[i]), backgroundColor: kCard2)),
                  ]),
                ),
                const SizedBox(width: 12),
                _stepBtn(Icons.remove, false, skills[i] > _bases[pos]![i] ? () => setState(() => skills[i]--) : null),
              ]),
            ),
        ]),
      ),
      _label('السمات (اختر حتى ٢)'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in _traitNames)
          GestureDetector(
            onTap: () => setState(() {
              if (!traits.remove(t) && traits.length < 2) traits.add(t);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(color: traits.contains(t) ? kPrimary : kCard, borderRadius: BorderRadius.circular(20)),
              child: Text(t, style: TextStyle(fontWeight: FontWeight.w900, color: traits.contains(t) ? Colors.white : kMuted)),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      Text('التكلفة: ${GameState.createPlayerCost} كوينز • رصيدك: ${gs.coins}', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 13)),
    ]);
  }

  void _next() {
    if (step == 0) {
      if (name.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم اللاعب')));
        return;
      }
      setState(() => step = 1);
      return;
    }
    final p = _build(name.text.trim(), pos, age, height, foot, nat, nat2, photo, skills, traits.toList(), real: true);
    final err = gs.createPlayer(p);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم إنشاء ${p.name} وانضم إلى فريقك 🌟')));
    if (err == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لاعب جديد'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC857), size: 18),
              const SizedBox(width: 6),
              Text('${gs.coins}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(children: [_stepper('الهوية', step == 0 || step == 1, 1, step > 0), _stepper('المهارات', step == 1, 2, false)]),
        ),
        Expanded(child: step == 0 ? _step1() : _step2()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(children: [
              Expanded(flex: 2, child: _btn(step == 0 ? 'إلغاء' : 'رجوع', kCard, kNavy, () => step == 0 ? Navigator.of(context).pop() : setState(() => step = 0))),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: _btn(step == 0 ? 'التالي: المهارات' : 'إنشاء اللاعب', kPrimary, Colors.white, _next, icon: Icons.swap_horiz_rounded)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  final String? current;
  const _CountrySheet({this.current});
  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String q = '';
  String region = '';
  final sc = ScrollController();
  static const _regions = [('', 'الكل'), ('A', 'أفريقيا'), ('E', 'أوروبا'), ('S', 'آسيا'), ('M', 'الأمريكتان'), ('O', 'أوقيانوسيا')];
  static const _top = ['المغرب', 'مصر', 'فرنسا', 'السنغال', 'البرازيل', 'الجزائر', 'تونس', 'إسبانيا'];
  static const _letters = ['أ', 'ب', 'ت', 'ج', 'ح', 'د', 'ر', 'س', 'ش', 'ع', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];

  List<Country> get list => [
        for (final c in kAllCountries)
          if ((region.isEmpty || c.region == region) && (q.isEmpty || c.name.contains(q))) c
      ];

  Widget _chip(String t, bool on, VoidCallback f, {Widget? lead}) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(color: on ? kNavy : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? kNavy : kLine)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(t, style: TextStyle(fontWeight: FontWeight.w900, color: on ? Colors.white : kNavy)),
            if (lead != null) ...[const SizedBox(width: 8), lead],
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = list;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Color(0xFFEEF0F5), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 44, height: 5, decoration: BoxDecoration(color: kMuted.withOpacity(0.4), borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Text('اختر الجنسية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle), child: const Icon(Icons.close_rounded)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(14)),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim()),
              decoration: InputDecoration(border: InputBorder.none, prefixIcon: const Icon(Icons.search_rounded), hintText: tr('ابحث بين ${kAllCountries.length} دولة...'), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ),
        Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), child: const Text('الأكثر اختياراً', style: TextStyle(color: kMuted, fontWeight: FontWeight.w800)))),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final n in _top)
              _chip(n, false, () => Navigator.of(context).pop(n), lead: FlagRect(countryByName(n)!.iso, w: 26)),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final r in _regions) _chip(r.$2, region == r.$1, () => setState(() => region = r.$1)),
          ]),
        ),
        Expanded(
          child: Row(children: [
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemExtent: 60,
                itemCount: l.length,
                itemBuilder: (_, i) {
                  final c = l[i];
                  final sel = c.name == widget.current;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(c.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: sel ? const Color(0xFF1FA58A).withOpacity(0.12) : kCard, border: const Border(bottom: BorderSide(color: kLine))),
                      child: Row(children: [
                        FlagRect(c.iso),
                        const SizedBox(width: 14),
                        Expanded(child: Text(c.name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: sel ? const Color(0xFF0E7C66) : null))),
                        if (sel) const Icon(Icons.check_rounded, color: Color(0xFF1FA58A)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 22,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final ch in _letters)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final i = l.indexWhere((c) => c.name.startsWith(ch));
                        if (i >= 0) sc.jumpTo((i * 60.0).clamp(0, sc.position.maxScrollExtent));
                      },
                      child: Center(child: Text(ch, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w800))),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
