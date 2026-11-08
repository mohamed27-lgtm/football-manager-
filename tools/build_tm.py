"""يحوّل ملف لاعبي Transfermarkt (players.csv) إلى tools/tm_leagues.json.gz: دوريات/أندية/لاعبون حاليون مع تقييم مشتق من القيمة السوقية."""
import csv, gzip, json, math, sys, datetime, collections

SRC = sys.argv[1]
REF = datetime.date(2025, 9, 1)

# كود Transfermarkt: (عدد الأندية، معرّف API-Football أو None لدوري جديد، الاسم، الدولة، المستوى)
LEAGUES = {
 'GB1': (20, 39), 'ES1': (20, 140), 'IT1': (20, 135), 'L1': (18, 78), 'FR1': (18, 61), 'SA1': (18, 307),
 'PO1': (18, 94), 'NL1': (18, 88), 'TR1': (20, 203), 'BE1': (16, 144), 'MLS1': (30, 253), 'BRA1': (20, 71),
 'ARG1': (30, 128), 'MEX1': (18, 262), 'SC1': (12, 179), 'A1': (12, 218), 'C1': (12, 207), 'DK1': (12, 119),
 'SE1': (16, 113), 'NO1': (16, 103), 'PL1': (18, 106), 'GR1': (14, 197), 'RU1': (16, 235), 'UKR1': (16, 333),
 'TS1': (16, 345), 'JAP1': (20, 98), 'RSK1': (12, 292),
 'RO1': (16, 9001, 'الدوري الروماني', 'رومانيا', 3), 'SER1': (16, 9002, 'الدوري الصربي', 'صربيا', 3),
 'KR1': (10, 9003, 'الدوري الكرواتي', 'كرواتيا', 3), 'COL1': (20, 9004, 'الدوري الكولومبي', 'كولومبيا', 2),
 'AUS1': (12, 9005, 'الدوري الأسترالي', 'أستراليا', 3),
}

def f(v, d=0.0):
    try: return float(v)
    except: return d

def rating_from_value(v):          # v باليورو
    return 66 + 9.3 * math.log10(max(v, 1e4) / 1e6)

def build(r):
    dob = datetime.date.fromisoformat(r['date_of_birth'][:10]) if r['date_of_birth'] else None
    age = (REF - dob).days // 365 if dob else 25
    v = f(r['market_value_in_eur']); hv = f(r['highest_market_value_in_eur'])
    if v <= 0: v = 150000 if age < 30 else 100000
    ov = rating_from_value(v)
    if age <= 22: ov -= (23 - age) * 1.3        # قيمة الشباب تتضمن الإمكانات
    if age >= 31: ov += min(6, (age - 30) * 0.9) + (rating_from_value(hv) - ov) * 0.12 if hv else (age - 30) * 0.9
    ov = int(max(38, min(93, round(ov))))
    pot = ov
    if age < 25: pot = min(95, ov + round((25 - age) * 1.7 + (rating_from_value(hv) - 60 > 0) * 1))
    ct = 2
    if r['contract_expiration_date']:
        try:
            e = datetime.date.fromisoformat(r['contract_expiration_date'][:10]); ct = max(1, min(5, round((e - REF).days / 365)))
        except: pass
    pos = r['position']
    p = {'id': int(r['player_id']), 'n': r['name'], 'a': age, 'p': {'Goalkeeper': 'Goalkeeper', 'Defender': 'Defender', 'Midfield': 'Midfielder', 'Attack': 'Attacker'}.get(pos, 'Midfielder'),
         'sub': r['sub_position'], 'nat': r['country_of_citizenship'], 'v': round(v / 1e6, 2), 'ov': ov, 'pot': int(pot), 'ct': ct}
    if r['height_in_cm']: p['h'] = int(f(r['height_in_cm']))
    if r['foot']: p['ft'] = r['foot']
    return p

rows = [x for x in csv.DictReader(open(SRC, encoding='utf-8-sig'))
        if x['last_season'] >= '2025' and x['current_club_id'] and x['current_club_domestic_competition_id'] in LEAGUES]
by = collections.defaultdict(lambda: collections.defaultdict(list))
for r in rows:
    by[r['current_club_domestic_competition_id']][(r['current_club_id'], r['current_club_name'])].append(build(r))
out = {}
for code, cfg in LEAGUES.items():
    clubs = by.get(code, {})
    # أندية الدوري الحالية: الأكبر عدد لاعبين ثم الأعلى قيمة
    ranked = sorted(clubs.items(), key=lambda kv: (-min(len(kv[1]), 26), -sum(p['v'] for p in kv[1])))[:cfg[0]]
    teams = []
    for (cid, cname), pl in ranked:
        pl.sort(key=lambda p: -p['ov'])
        top = sorted(p['ov'] for p in pl)[-14:]
        teams.append({'tm': int(cid), 'name': cname, 'str': round(sum(top) / len(top), 1), 'players': pl[:32]})
    teams.sort(key=lambda t: -t['str'])
    out[code] = {'api': cfg[1], 'new': cfg[2:] if len(cfg) > 2 else None, 'teams': teams}
with gzip.open('tools/tm_leagues.json.gz', 'wt', encoding='utf-8') as g:
    json.dump(out, g, ensure_ascii=False, separators=(',', ':'))
print({k: (len(v['teams']), sum(len(t['players']) for t in v['teams'])) for k, v in out.items()})
