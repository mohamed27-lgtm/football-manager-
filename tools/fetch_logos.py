"""ينزّل شعارات الدوريات والكؤوس من API-Sports (مجاني للصور) إلى assets/logos/{id}.png.
يتخطى الموجود، ويُشغَّل داخل GitHub Actions لأن البيئة المحلية بلا إنترنت."""
import json, pathlib, sys, time, urllib.request

OUT = pathlib.Path('assets/logos'); OUT.mkdir(parents=True, exist_ok=True)
ids = {x['id'] for x in json.load(open('tools/leagues.json', encoding='utf-8'))}
ids |= {9001, 9002, 9003, 9004, 9005}  # دوريات جديدة (لا شعار لها في API)
ids -= {9001, 9002, 9003, 9004, 9005}
# كؤوس محلية وسوبر وقارية
ids |= {2, 3, 848, 531, 45, 143, 137, 81, 66, 96, 90, 206, 147, 528, 556, 547, 529, 526, 1, 4, 5, 9, 15, 960}
ok = fail = 0
for i in sorted(ids):
    f = OUT / f'{i}.png'
    if f.exists() and f.stat().st_size > 200:
        continue
    for a in range(3):
        try:
            req = urllib.request.Request(f'https://media.api-sports.io/football/leagues/{i}.png', headers={'User-Agent': 'Mozilla/5.0'})
            d = urllib.request.urlopen(req, timeout=20).read()
            if d[:4] == b'\x89PNG' and len(d) > 200:
                f.write_bytes(d); ok += 1; break
        except Exception as e:
            time.sleep(1)
    else:
        fail += 1
print(f'logos downloaded={ok} failed={fail} total_files={len(list(OUT.glob("*.png")))}')
