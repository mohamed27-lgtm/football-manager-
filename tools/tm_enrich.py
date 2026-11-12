"""إثراء لاعبي الـ API ببيانات Transfermarkt الحقيقية: الجنسية، القدم، الطول، القيمة السوقية، العقد، المركز الدقيق.
المطابقة بالاسم + النادي + العمر. غير المتطابق يبقى بلا بيانات (لا نخترع شيئاً)."""
import csv, gzip, math, re, unicodedata, datetime, difflib, pathlib, collections

REF = datetime.date.today()
_SRC = pathlib.Path(__file__).with_name('tm_players.csv.gz')

def norm(x):
    x = unicodedata.normalize('NFD', (x or '').lower())
    x = re.sub(r'[̀-ͯ]', '', x)
    x = x.replace('ø', 'o').replace('ß', 'ss').replace('æ', 'ae').replace('đ', 'd').replace('ł', 'l')
    x = re.sub(r"[^a-z0-9 ]", ' ', x)
    return ' '.join(x.split())

_STOP = {'fc', 'cf', 'ac', 'as', 'sc', 'fk', 'sk', 'club', 'football', 'futbol', 'calcio', 'de', 'the', 'cd', 'ud', 'afc', 'bsc', 'fsv', 'vfb', 'vfl', 'tsg', 'rb', '1', 'real', 'sporting'}

def club_key(x):
    return ' '.join(w for w in norm(x).split() if w not in _STOP)

def rating_from_value(v):
    return 66 + 9.3 * math.log10(max(v, 1e4) / 1e6)

_idx = None
def _load():
    global _idx
    if _idx is not None:
        return _idx
    rows = []
    with gzip.open(_SRC, 'rt', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            try:
                y = int(r['dob'][:4]) if r['dob'] else None
            except ValueError:
                y = None
            r['_y'] = y
            r['_n'] = norm(r['name'])
            r['_c'] = club_key(r['club'])
            rows.append(r)
    byname = collections.defaultdict(list)
    bysur = collections.defaultdict(list)
    for r in rows:
        byname[r['_n']].append(r)
        parts = r['_n'].split()
        if parts:
            bysur[parts[-1]].append(r)
    _idx = (rows, byname, bysur)
    return _idx

_byclub = None
def club_rows(ck):
    global _byclub
    rows, _, _ = _load()
    if _byclub is None:
        _byclub = collections.defaultdict(list)
        for r in rows: _byclub[r['_c']].append(r)
    out = []
    for c, rs in _byclub.items():
        if _club_sim(ck, c) >= 0.75: out.extend(rs)
    return out

def _club_sim(a, b):
    if not a or not b: return 0
    if a == b: return 1
    aw, bw = set(a.split()), set(b.split())
    if aw <= bw or bw <= aw: return 0.9
    return difflib.SequenceMatcher(None, a, b).ratio()

def match(name, age, team_name):
    """يُرجع صف TM أو None"""
    rows, byname, bysur = _load()
    n = norm(name)
    if not n: return None
    ck = club_key(team_name)
    yr = REF.year - age if age else None
    def age_ok(r, tol=1):
        return yr is None or r['_y'] is None or abs(r['_y'] - yr) <= tol
    parts = n.split()
    cands = byname.get(n, [])
    if cands:
        c = [r for r in cands if age_ok(r)]
        if c:
            c.sort(key=lambda r: -_club_sim(ck, r['_c']))
            if len(c) == 1 or _club_sim(ck, c[0]['_c']) >= 0.6:
                return c[0]
    # أسماء مختصرة (J. Bisiwu) أو بدون الاسم الأوسط: لقب مطابق + الحرف الأول + العمر
    sur = parts[-1]
    first = parts[0]
    pool = [r for r in bysur.get(sur, []) if age_ok(r) and r['_n'].split()[0][:1] == first[:1]]
    if len(first) > 1:
        full = [r for r in pool if r['_n'].split()[0] == first or first in r['_n'].split()]
        pool = full or pool
    if pool:
        pool.sort(key=lambda r: -_club_sim(ck, r['_c']))
        if _club_sim(ck, pool[0]['_c']) >= 0.6 or (len(pool) == 1 and len(sur) >= 5):
            return pool[0]
    # ترتيب الأسماء المختلف (Kim Min-Jae ↔ Min-jae Kim) أو اسم أوسط زائد: تقاطع كلمات داخل نفس النادي
    nt = set(parts)
    best = None
    for r in club_rows(ck):
        if not age_ok(r): continue
        rt = set(r['_n'].split())
        common = nt & rt
        if len(common) >= 2 and (nt <= rt or rt <= nt or len(common) >= min(len(nt), len(rt))):
            best = r
            break
        if len(common) >= 1 and len(rt) == 1 and next(iter(rt)) in nt:   # اسم واحد (برازيلي: Fred)
            best = r
            break
    return best

def enrich(p, team_name):
    """يضيف حقول TM إلى لاعب API (قاموس: id,n,a,p,...) ويُرجع True عند المطابقة"""
    r = match(p.get('n'), p.get('a'), team_name)
    if not r: return False
    try: v = float(r['val'] or 0)
    except ValueError: v = 0
    age = p.get('a') or (REF.year - r['_y'] if r['_y'] else 25)
    if v <= 0: v = 150000 if age < 30 else 100000
    ov = rating_from_value(v)
    if age <= 22: ov -= (23 - age) * 1.3
    if age >= 31: ov += min(6, (age - 30) * 0.9)
    ov = int(max(38, min(93, round(ov))))
    pot = ov
    if age < 25: pot = min(95, ov + round((25 - age) * 1.7))
    ct = 2
    if r['exp']:
        try:
            e = datetime.date.fromisoformat(r['exp'][:10]); ct = max(1, min(5, round((e - REF).days / 365)))
        except ValueError: pass
    p.update({'sub': r['sub'] or None, 'nat': r['nat'] or None, 'ft': r['foot'] or None,
              'h': int(r['h']) if r['h'] else None, 'v': round(v / 1e6, 2), 'ov': ov, 'pot': int(pot), 'ct': ct})
    return True
