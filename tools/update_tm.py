"""يحدّث tools/tm_leagues.json.gz من أحدث نسخة من Transfermarkt Datasets (CC0): كل دوريات الدرجة الأولى المتاحة فيها.
يُشغَّل داخل GitHub Actions (الإنترنت هناك مفتوح للمصدر). لا يكتب الملف إن بدا الناتج ناقصاً.
الاستخدام المحلي للاختبار: python tools/update_tm.py --offline players.csv competitions.csv"""
import csv, datetime, gzip, io, json, pathlib, re, sys, urllib.request, zipfile

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
import build_tm as bt

BASE = 'https://pub-e682421888d945d684bcae8890b0ec20.r2.dev/data/'


def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return urllib.request.urlopen(req, timeout=300).read()


def load_csv_text(name):
    try:
        return gzip.decompress(get(BASE + name + '.gz')).decode('utf-8-sig')
    except Exception as e:
        print(name, '.gz failed:', repr(e)[:120])
    z = zipfile.ZipFile(io.BytesIO(get(BASE + 'transfermarkt-datasets.zip')))
    n = next(x for x in z.namelist() if x.endswith(name))
    return z.read(n).decode('utf-8-sig')


def en2ar():
    src = (ROOT / 'lib' / 'nations.dart').read_text(encoding='utf-8')
    block = src[src.index('_en2ar'):]
    block = block[:block.index('};')]
    d = {}
    for m in re.finditer(r"""(?:'([^']+)'|"([^"]+)")\s*:\s*'([^']+)'""", block):
        d[m.group(1) or m.group(2)] = m.group(3)
    return d


def game_countries():
    src = (ROOT / 'lib' / 'countries.dart').read_text(encoding='utf-8')
    raw = src[src.index("const _raw = '''") + 16:]
    raw = raw[:raw.index("'''")]
    out = set()
    for part in re.split(r'[;\n]', raw):
        p = part.strip().split('|')
        if len(p) == 3:
            out.add(p[0])
    return out


def discover(comps_text, ids_path):
    """دوريات الدرجة الأولى الجديدة (غير المعرّفة في build_tm) التي بلدها موجود في اللعبة"""
    rows = list(csv.DictReader(io.StringIO(comps_text)))
    print('competition columns:', list(rows[0].keys()) if rows else None)
    ar, known = en2ar(), game_countries()
    ids = json.loads(ids_path.read_text()) if ids_path.exists() else {}
    extra, skipped = {}, []
    for r in rows:
        if r.get('type') != 'domestic_league' or r.get('sub_type') != 'first_tier':
            continue
        code = r['competition_id']
        if code in bt.LEAGUES:
            continue
        c_ar = ar.get(r.get('country_name', ''))
        if not c_ar or c_ar not in known:
            skipped.append((code, r.get('country_name')))
            continue
        if code not in ids:
            ids[code] = 9100 + len(ids)  # معرّف ثابت لا يُعاد استعماله أبداً
        extra[code] = (16, ids[code], 'دوري ' + c_ar, c_ar, 3)
    print('new leagues:', {k: v[3] for k, v in extra.items()})
    print('skipped (country not in game):', skipped)
    return extra, ids


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == '--offline':
        players_text = open(sys.argv[2], encoding='utf-8-sig').read()
        comps_text = open(sys.argv[3], encoding='utf-8-sig').read()
        out_path = '/tmp/tm_leagues_test.json.gz'
        ids_path = pathlib.Path('/tmp/tm_new_ids_test.json')
        minimum = (1, 1)
    else:
        players_text = load_csv_text('players.csv')
        comps_text = load_csv_text('competitions.csv')
        out_path = str(ROOT / 'tools' / 'tm_leagues.json.gz')
        ids_path = HERE / 'tm_new_ids.json'
        minimum = (25, 12000)
    today = datetime.date.today()
    season_year = today.year if today.month >= 7 else today.year - 1
    extra, ids = discover(comps_text, ids_path)
    leagues = {**bt.LEAGUES, **extra}
    tmp = pathlib.Path('/tmp/players_all.csv')
    tmp.write_text(players_text, encoding='utf-8')
    out = bt.run(str(tmp), ref=today, min_season=str(season_year - 1), leagues=leagues, out_path='/tmp/tm_build.json.gz')
    nl = sum(1 for v in out.values() if v['teams'])
    npl = sum(len(t['players']) for v in out.values() for t in v['teams'])
    print(f'leagues with data: {nl}, players: {npl}, season_year: {season_year}')
    if nl < minimum[0] or npl < minimum[1]:
        print('RESULT TOO SMALL: keeping the old file')
        sys.exit(1)
    # الدوريات الفارغة تُحذف حتى لا تُنشئ دوريات بلا أندية
    out = {k: v for k, v in out.items() if v['teams']}
    with gzip.open(out_path, 'wt', encoding='utf-8') as g:
        json.dump(out, g, ensure_ascii=False, separators=(',', ':'))
    ids_path.write_text(json.dumps(ids, ensure_ascii=False, indent=1))
    print('written', out_path)


main()
