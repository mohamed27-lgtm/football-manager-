# مدرب كرة القدم (Flutter - ثيم داكن)

لعبة إدارة وتدريب كرة قدم بملعب 2D حي، مع دوريات وأندية ولاعبين وصور حقيقية تُستورد وتُبنى كلها عبر GitHub Actions.

## الإعداد (مرة واحدة)
1. أنشئ مفتاحاً مجانياً من https://www.api-football.com
2. في المستودع: **Settings → Secrets and variables → Actions → New repository secret**
   الاسم `API_FOOTBALL_KEY` والقيمة مفتاحك.
3. **Settings → Actions → General → Workflow permissions → Read and write permissions**.
4. تبويب **Actions → Import football data → Run workflow** (اضغط مرة واحدة).
5. عدّل `defaultPackBase` في `lib/pack_service.dart` إلى:
   `https://github.com/<اسمك>/<المستودع>/releases/download/data-latest`
   (أو اكتب الرابط من داخل اللعبة في شاشة الحزم).

## ماذا يحدث؟
| workflow | ماذا يفعل |
|---|---|
| **Import football data** | يجلب الدوريات والفرق والتشكيلات وصور الشعارات واللاعبين، يحفظها في `data/`، ويبني حزماً `packs/*.zip` ترفعها لإصدار `data-latest`. يعمل يومياً تلقائياً ويكمل من حيث توقف. |
| **Build APK** | يبني `football_manager.apk` عند كل تعديل في `lib/` ويرفعه لإصدار `apk-latest` (وكـ artifact). |

## حدود مهمة
- الخطة المجانية 100 طلب يومياً: كل دوري من 20 فريقاً ≈ 22 طلباً، فالدوريات الستة الأولى في `tools/leagues.json` تكتمل خلال يومين تقريباً وكلها (35 دوري) خلال نحو أسبوع. يمكنك تحديد دوريات بعينها من حقل `leagues` عند تشغيل الـ workflow.
- قد تقتصر الخطة المجانية على المواسم 2021–2023.
- أسماء اللاعبين من الـ API مختصرة أحياناً (مثل «L. Messi»).
- الـ API لا يعطي تقييمات للاعبين، فتُشتق من ترتيب الفريق ومستوى الدوري (انظر `lib/importer.dart`).
- تنزيل الحزم داخل اللعبة بدون مفتاح يتطلب أن يكون **المستودع عاماً** (روابط الإصدارات في المستودعات الخاصة تحتاج توكن).
- الشعارات وصور اللاعبين مملوكة لأصحابها: مناسبة للتجربة الشخصية، ولأي نشر تجاري تحتاج ترخيصاً.
- ملف APK موقّع بمفتاح التطوير (للتجربة والتثبيت اليدوي، وليس للنشر في المتجر).

## تحميل APK
تبويب **Releases → Latest APK → football_manager.apk**.

## بنية الكود
`lib/`: main · home · data_screen · packs_screen · pack_service · api_football · league_store · importer · match_screen · pitch_view · tactics · squad · widgets · game_state · engine · models · data
`tools/`: fetch_data.py · leagues.json
