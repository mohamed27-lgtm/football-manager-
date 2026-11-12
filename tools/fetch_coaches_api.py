#!/usr/bin/env python3
"""مدربو الأندية من API-Football /coachs (تدريجياً بميزانية طلبات يومية صغيرة).
يخزّن data/coaches_api.json = {معرّف الفريق: {"team": اسم الفريق, "coach": اسم المدرب أو ""}} ويكمل من حيث توقف."""
import glob, json, os, sys, time, urllib.parse, urllib.request
from pathlib import Path

KEY = os.environ.get('API_FOOTBALL_KEY', '').strip()
BUDGET = int(os.environ.get('COACH_BUDGET') or 40)
OUT = Path('data/coaches_api.json')
if not KEY:
    print('no API key'); sys.exit(0)
done = json.loads(OUT.read_text(encoding='utf-8')) if OUT.exists() else {}
todo = []
for f in sorted(glob.glob('data/leagues/*.json')):
    try: d = json.loads(Path(f).read_text(encoding='utf-8'))
    except Exception: continue
    for t in d.get('teams', []):
        if t['id'] < 800000 and str(t['id']) not in done:
            todo.append((t['id'], t['name']))
print('remaining teams:', len(todo))

def current(resp, tid):
    best = None
    for c in resp:
        for e in c.get('career') or []:
            if (e.get('team') or {}).get('id') == tid and not e.get('end'):
                nm = ' '.join(x for x in [c.get('firstname'), c.get('lastname')] if x) or c.get('name') or ''
                if best is None or (e.get('start') or '') > best[0]:
                    best = (e.get('start') or '', nm.strip())
    return best[1] if best else ''

used = 0
for tid, name in todo:
    if used >= BUDGET: break
    time.sleep(6.6)
    url = 'https://v3.football.api-sports.io/coachs?' + urllib.parse.urlencode({'team': tid})
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={'x-apisports-key': KEY}), timeout=40) as r:
            rem = r.headers.get('x-ratelimit-requests-remaining')
            body = json.load(r)
    except Exception as e:
        print('fail', tid, repr(e)[:100]); break
    used += 1
    if body.get('errors'):
        print('errors', body['errors']); break
    done[str(tid)] = {'team': name, 'coach': current(body.get('response') or [], tid)}
    if rem is not None and int(rem) <= 5: break
OUT.parent.mkdir(exist_ok=True)
OUT.write_text(json.dumps(done, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
print('fetched', used, 'total', len(done), 'with coach', sum(1 for v in done.values() if v['coach']))
