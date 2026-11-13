"""أيقونة التطبيق وشاشة التشغيل الأصلية في APK من صورة المدرب (assets/brand). يُشغَّل بعد flutter create."""
import pathlib
from PIL import Image, ImageDraw

res = pathlib.Path('android/app/src/main/res')
if not res.exists():
    raise SystemExit('no android res')
av = Image.open('assets/brand/coach_avatar.jpg').convert('RGB')
scene = Image.open('assets/brand/coach_scene.jpg').convert('RGB')

def rounded(im, size, r):
    im = im.resize((size, size), Image.LANCZOS).convert('RGBA')
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * r), fill=255)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), m)
    return out

for d, sz in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    dd = res / f'mipmap-{d}'
    dd.mkdir(parents=True, exist_ok=True)
    rounded(av, sz, 0.22).save(dd / 'ic_launcher.png')
    # إزالة أيقونة التكيّف إن وُجدت حتى لا تغطي الصورة
for f in res.glob('mipmap-anydpi*/ic_launcher*.xml'):
    f.unlink()

dr = res / 'drawable'
dr.mkdir(parents=True, exist_ok=True)
scene.resize((540, 810), Image.LANCZOS).save(dr / 'splash_scene.jpg', quality=85)
xml = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black"/>
    <item>
        <bitmap android:src="@drawable/splash_scene" android:gravity="fill_horizontal|top"/>
    </item>
</layer-list>
'''
for name in ('drawable', 'drawable-v21'):
    d = res / name
    d.mkdir(parents=True, exist_ok=True)
    (d / 'launch_background.xml').write_text(xml, encoding='utf-8')
print('android brand applied')
