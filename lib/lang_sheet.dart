import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'settings.dart';
import 'widgets.dart';

const kLangs = <(String, String, String)>[
  ('ar', 'العربية', 'sa'),
  ('en', 'English', 'gb'),
  ('fr', 'Français', 'fr'),
  ('es', 'Español', 'es'),
];

Widget _flag(String iso, double w) {
  final emoji = String.fromCharCodes(iso.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
  final fb = Text(emoji, style: TextStyle(fontSize: w * 0.7));
  return ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: Unfilter(
      child: CachedNetworkImage(
        imageUrl: 'https://flagcdn.com/w80/$iso.png',
        width: w,
        height: w * 0.68,
        fit: BoxFit.cover,
        placeholder: (_, __) => fb,
        errorWidget: (_, __, ___) => fb,
      ),
    ),
  );
}

/// نافذة اختيار اللغة بعجلة وأعلام (مثل Super Kickoff)
Future<void> showLanguageSheet(BuildContext context) async {
  var idx = kLangs.indexWhere((l) => l.$1 == AppSettings.i.lang);
  if (idx < 0) idx = 0;
  final ctl = FixedExtentScrollController(initialItem: idx);
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Text(tr('اللغة'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(
              height: 230,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  height: 58,
                  decoration: BoxDecoration(color: kAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                ),
                ListWheelScrollView.useDelegate(
                  controller: ctl,
                  itemExtent: 58,
                  perspective: 0.003,
                  diameterRatio: 2.2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) => setS(() => idx = i),
                  childDelegate: ListWheelChildListDelegate(children: [
                    for (var i = 0; i < kLangs.length; i++)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _flag(kLangs[i].$3, 38),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 120,
                            child: Text(kLangs[i].$2,
                                style: TextStyle(fontSize: i == idx ? 24 : 19, fontWeight: i == idx ? FontWeight.w900 : FontWeight.w500, color: i == idx ? null : kMuted)),
                          ),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            GradientButton(
              label: _choose[kLangs[idx].$1]!,
              onPressed: () {
                AppSettings.i.set(lang: kLangs[idx].$1);
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    ),
  );
  ctl.dispose();
}

const _choose = {'ar': 'اختيار', 'en': 'Select', 'fr': 'Choisir', 'es': 'Elegir'};
