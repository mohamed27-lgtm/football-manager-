"""مدربو الأندية الحقيقيون من Transfermarkt Datasets (CC0): ينزّل clubs.csv ويطابق أسماء أندية اللعبة (assets/leagues)
وينتج assets/coaches.json = {اسم النادي بحروف صغيرة: اسم المدرب}. يُشغَّل داخل GitHub Actions."""
import csv, gzip, io, json, pathlib, sys, urllib.request, zipfile
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import tm_enrich as te

BASE = 'https://pub-e682421888d945d684bcae8890b0ec20.r2.dev/data/'

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return urllib.request.urlopen(req, timeout=120).read()

def load_clubs():
    try:
        return gzip.decompress(get(BASE + 'clubs.csv.gz')).decode('utf-8')
    except Exception as e:
        print('clubs.csv.gz failed:', repr(e)[:120])
    z = zipfile.ZipFile(io.BytesIO(get(BASE + 'transfermarkt-datasets.zip')))
    name = next(n for n in z.namelist() if n.endswith('clubs.csv'))
    return z.read(name).decode('utf-8')

try:
    rows = list(csv.DictReader(io.StringIO(load_clubs())))
except Exception as e:
    print('download failed:', repr(e)[:200]); sys.exit(0)
print('columns:', list(rows[0].keys()) if rows else None, 'rows:', len(rows))
if not rows or 'coach_name' not in rows[0]:
    print('NO coach_name column'); sys.exit(0)

idx = []
for r in rows:
    c = (r.get('coach_name') or '').strip()
    if c and c.lower() not in ('nan', 'none'):
        idx.append((te.club_key(r['name']), c))
print('clubs with coach:', len(idx))

out, total = {}, 0
for f in pathlib.Path('assets/leagues').glob('*_*.json'):
    try: d = json.loads(f.read_text(encoding='utf-8'))
    except Exception: continue
    for t in d.get('teams', []):
        total += 1
        k = te.club_key(t['name'])
        best, bs = None, 0
        for ck, c in idx:
            s = te._club_sim(k, ck)
            if s > bs: best, bs = c, s
        if best and bs >= 0.85:
            out[t['name'].lower().strip()] = best
print(f'matched {len(out)} / {total} teams')
pathlib.Path('assets/coaches.json').write_text(json.dumps(out, ensure_ascii=False), encoding='utf-8')
