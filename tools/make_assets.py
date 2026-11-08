"""ينسخ بيانات الدوريات من data/leagues إلى assets/leagues ويبني index.json (يُشغَّل قبل بناء التطبيق)."""
import json, pathlib, shutil, gzip, re, difflib, datetime

cfg = {}
try:
    cfg = {x['id']: x for x in json.loads(pathlib.Path('tools/leagues.json').read_text(encoding='utf-8'))}
except Exception:
    pass

src = pathlib.Path("data/leagues")
dst = pathlib.Path("assets/leagues")
dst.mkdir(parents=True, exist_ok=True)
index = []
for f in sorted(src.glob("*_*.json")) if src.exists() else []:
    try:
        d = json.loads(f.read_text(encoding="utf-8"))
    except Exception:
        continue
    if not d.get("teams"):
        continue
    c = cfg.get(d['id'], {})
    d['div'] = c.get('div', d.get('div', 1))
    d['country'] = c.get('country', d.get('country'))
    (dst / f.name).write_text(json.dumps(d, ensure_ascii=False), encoding='utf-8')
    index.append({"id": d["id"], "season": d["season"], "file": f.name})
(dst / "index.json").write_text(json.dumps(index, ensure_ascii=False), encoding="utf-8")
print(f"bundled {len(index)} leagues")


# ───── دمج لاعبي Transfermarkt الحقيقيين (tools/tm_leagues.json.gz) ─────
import unicodedata

def _norm(x):
    x = unicodedata.normalize('NFD', x.lower())
    x = re.sub(r"[\u0300-\u036f]", "", x)
    x = re.sub(r"[^a-z0-9 ]", " ", x)
    stop = {"fc", "cf", "ac", "as", "sc", "fk", "sk", "club", "football", "futbol", "calcio", "de", "the", "cd", "ud", "afc", "bsc", "fsv", "vfb", "vfl", "tsg", "rb", "1"}
    return " ".join(w for w in x.split() if w not in stop)

def _score(a, b):
    n, m = _norm(a), _norm(b)
    if not n or not m: return 0
    r = difflib.SequenceMatcher(None, n, m).ratio()
    if n == m: return 1.0
    nw, mw = set(n.split()), set(m.split())
    if nw <= mw or mw <= nw:
        if len(nw & mw) and (len(nw & mw) >= 2 or max(len(w) for w in nw & mw) >= 5): r = max(r, 0.85)
    return r

def _assign(new, old):
    """مطابقة واحد لواحد، الأعلى تشابهاً أولاً"""
    pairs = sorted(((_score(t['name'], o['name']), i, j) for i, t in enumerate(new) for j, o in enumerate(old)), reverse=True)
    ti, oj, res = set(), set(), {}
    for sc, i, j in pairs:
        if sc < 0.62: break
        if i in ti or j in oj: continue
        ti.add(i); oj.add(j); res[i] = old[j]
    return res

tmp = pathlib.Path('tools/tm_leagues.json.gz')
if tmp.exists():
    tm = json.loads(gzip.open(tmp, 'rt', encoding='utf-8').read())
    used = 0
    for code, L in tm.items():
        api = L['api']
        path = dst / f"{api}_2023.json"
        if path.exists():
            d = json.loads(path.read_text(encoding='utf-8'))
        elif L.get('new'):
            nm, country, tier = L['new']
            d = {'id': api, 'name': nm, 'country': country, 'tier': tier, 'div': 1, 'season': 2023, 'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'teams': []}
        else:
            continue
        old = d.get('teams', [])
        teams = []
        mp = _assign(L['teams'], old)
        for i, t in enumerate(L['teams']):
            o = mp.get(i)
            players = [{'id': p['id'], 'n': p['n'], 'a': p['a'], 'p': p['p'], 'ph': None, 'no': None,
                        'sub': p.get('sub'), 'nat': p.get('nat'), 'v': p['v'], 'ov': p['ov'], 'pot': p['pot'], 'ct': p['ct'],
                        'h': p.get('h'), 'ft': p.get('ft')} for p in t['players']]
            teams.append({'id': o['id'] if o else 800000 + t['tm'], 'name': o['name'] if o else t['name'],
                          'logo': o.get('logo') if o else None, 'venue': o.get('venue') if o else None,
                          'rank': i + 1, 'pts': 0, 'loaded': True, 'players': players})
        d['teams'] = teams
        path.write_text(json.dumps(d, ensure_ascii=False), encoding='utf-8')
        if not any(e['file'] == path.name for e in index):
            index.append({"id": d['id'], "season": d['season'], "file": path.name})
        used += 1
    (dst / "index.json").write_text(json.dumps(index, ensure_ascii=False), encoding="utf-8")
    print(f"real Transfermarkt squads merged into {used} leagues")
