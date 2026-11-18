"""صور لاعبي Transfermarkt الحرة من ويكيميديا كومنز عبر ويكيداتا (الخاصية P2446 = معرّف Transfermarkt، P18 = الصورة).
ينتج ملف photos_wikidata.zip فيه: p/<id>.jpg (مصغّرة 160px) + credits.json (المصوّر والترخيص لكل صورة).
تراخيص كومنز حرة لكنها تشترط ذكر المصدر، لذلك تُحفظ الاعتمادات وتُعرض في اللعبة.
يعمل داخل GitHub Actions. تزايدي: يعيد استخدام الحزمة السابقة ولا يعيد تنزيل ما نزل.
الاختبار المحلي بلا إنترنت غير ممكن؛ شغّله من الـ workflow."""
import gzip, html, io, json, os, pathlib, re, sys, time, urllib.parse, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORK = pathlib.Path(os.environ.get('WD_WORK', '/tmp/wd_work'))
UA = 'FootballManagerGame/1.0 (https://github.com/mohamed27-lgtm/football-manager-; educational game; contact via repository issues)'
SPARQL = 'https://query.wikidata.org/sparql'
COMMONS_API = 'https://commons.wikimedia.org/w/api.php'
WIDTH = 160
RECHECK_DAYS = 45
MAX_NEW = int(os.environ.get('WD_MAX_NEW', '100000'))   # سقف الصور الجديدة في التشغيل الواحد
BUDGET_SEC = int(os.environ.get('WD_BUDGET_SEC', str(100 * 60)))
T0 = time.time()


def http_get(url, accept=None, tries=5, binary=False):
    delay = 2.0
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA, **({'Accept': accept} if accept else {})})
            with urllib.request.urlopen(req, timeout=90) as r:
                data = r.read()
            return data if binary else data.decode('utf-8')
        except urllib.error.HTTPError as e:
            if e.code in (429, 503, 504) or e.code >= 500:
                ra = e.headers.get('Retry-After')
                time.sleep(min(60, float(ra)) if ra and ra.isdigit() else delay)
                delay *= 2
                continue
            if e.code == 404:
                return None
            raise
        except Exception:
            time.sleep(delay)
            delay *= 2
    return None


def tm_ids():
    d = json.loads(gzip.open(ROOT / 'tools' / 'tm_leagues.json.gz', 'rt', encoding='utf-8').read())
    ids = []
    for L in d.values():
        for t in L['teams']:
            for p in t['players']:
                ids.append(int(p['id']))
    # الأعلى قيمة أولاً: النجوم أولى بالصور إن ضاق الوقت
    return ids


def load_previous():
    """الحزمة السابقة من الإصدار (إن وُجدت) لإعادة استعمالها"""
    photos, credits, checked = {}, {}, {}
    prev = WORK / 'prev.zip'
    os.system(f'gh release download data-latest -p photos_wikidata.zip -O "{prev}" --clobber >/dev/null 2>&1')
    if prev.exists() and prev.stat().st_size > 1000:
        try:
            z = zipfile.ZipFile(prev)
            for n in z.namelist():
                if n.startswith('p/') and n.endswith('.jpg'):
                    photos[int(n[2:-4])] = z.read(n)
            if 'credits.json' in z.namelist():
                credits = {int(k): v for k, v in json.loads(z.read('credits.json')).items()}
            if 'checked.json' in z.namelist():
                checked = {int(k): v for k, v in json.loads(z.read('checked.json')).items()}
            print('previous pack:', len(photos), 'photos,', len(checked), 'checked-without-photo')
        except Exception as e:
            print('previous pack unreadable:', repr(e)[:100])
    return photos, credits, checked


def sparql_images(batch):
    vals = ' '.join(f'"{i}"' for i in batch)
    q = f'SELECT ?tm ?img WHERE {{ VALUES ?tm {{ {vals} }} ?p wdt:P2446 ?tm . OPTIONAL {{ ?p wdt:P18 ?img }} }}'
    raw = http_get(SPARQL + '?format=json&query=' + urllib.parse.quote(q), accept='application/sparql-results+json')
    out = {}
    if not raw:
        return None
    for b in json.loads(raw)['results']['bindings']:
        tm = int(b['tm']['value'])
        out.setdefault(tm, None)
        if 'img' in b and out[tm] is None:
            u = b['img']['value']
            out[tm] = urllib.parse.unquote(u.rsplit('/', 1)[-1])  # اسم الملف على كومنز
    return out


def credit_for(files):
    """المصوّر والترخيص لمجموعة ملفات كومنز"""
    res = {}
    for i in range(0, len(files), 40):
        part = files[i:i + 40]
        url = COMMONS_API + '?action=query&format=json&prop=imageinfo&iiprop=extmetadata&iiextmetadatafilter=Artist|LicenseShortName&titles=' + urllib.parse.quote('|'.join('File:' + f for f in part))
        raw = http_get(url)
        if not raw:
            continue
        norm = {}
        j = json.loads(raw).get('query', {})
        for n in j.get('normalized', []):
            norm[n['to']] = n['from'][5:]
        for pg in j.get('pages', {}).values():
            title = pg.get('title', '')[5:]
            src = norm.get(pg.get('title', ''), title)
            md = (pg.get('imageinfo') or [{}])[0].get('extmetadata', {})
            artist = re.sub(r'<[^>]+>', '', html.unescape(md.get('Artist', {}).get('value', ''))).strip()
            lic = md.get('LicenseShortName', {}).get('value', '').strip()
            res[src] = (artist[:80] or 'Wikimedia Commons') + (f' — {lic}' if lic else '')
            res[title] = res[src]
        time.sleep(0.5)
    return res


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    ids = tm_ids()
    photos, credits, checked = load_previous()
    today = int(time.time() // 86400)
    todo = [i for i in ids if i not in photos and (i not in checked or today - checked[i] > RECHECK_DAYS)]
    print(f'players: {len(ids)}, have: {len(photos)}, to check: {len(todo)}')
    new_files = {}
    # 1) أي من هذه المعرّفات له صورة في ويكيداتا؟
    for b in range(0, len(todo), 300):
        if time.time() - T0 > BUDGET_SEC * 0.35:
            print('time budget reached during SPARQL')
            break
        batch = todo[b:b + 300]
        res = sparql_images(batch)
        if res is None:
            print('sparql batch failed', b)
            continue
        for i in batch:
            if res.get(i):
                new_files[i] = res[i]
            else:
                checked[i] = today
        time.sleep(1.0)
    print('with commons image:', len(new_files))
    # 2) تنزيل المصغّرات
    got = 0
    for n, (tm, fn) in enumerate(new_files.items()):
        if got >= MAX_NEW or time.time() - T0 > BUDGET_SEC:
            print('stopping downloads (budget)')
            break
        url = 'https://commons.wikimedia.org/wiki/Special:FilePath/' + urllib.parse.quote(fn) + f'?width={WIDTH}'
        data = http_get(url, binary=True)
        if data and len(data) > 800 and data[:2] == b'\xff\xd8':
            photos[tm] = data
            got += 1
        else:
            checked[tm] = today
        time.sleep(0.25)
        if n % 500 == 0:
            print('downloaded', got, 'of', n + 1)
    print('new photos:', got, 'total:', len(photos))
    # 3) الاعتمادات (المصوّر + الترخيص) للصور الجديدة
    need = [fn for tm, fn in new_files.items() if tm in photos and tm not in credits]
    cmap = credit_for(need)
    for tm, fn in new_files.items():
        if tm in photos and tm not in credits:
            credits[tm] = cmap.get(fn) or 'Wikimedia Commons'
    if not photos:
        print('no photos at all: nothing to publish')
        sys.exit(0)
    out = WORK / 'photos_wikidata.zip'
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as z:
        for tm, data in photos.items():
            z.writestr(f'p/{tm}.jpg', data)
        z.writestr('credits.json', json.dumps({str(k): v for k, v in credits.items() if k in photos}, ensure_ascii=False))
        z.writestr('checked.json', json.dumps({str(k): v for k, v in checked.items() if k not in photos}))
    print('wrote', out, round(out.stat().st_size / 1e6, 1), 'MB,', len(photos), 'photos')


main()
