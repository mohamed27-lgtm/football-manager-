#!/usr/bin/env python3
"""يستبدل صور اللاعبين بصور أحدث من TheSportsDB (مجاني، يضيفها متطوعون) كلما وُجد تطابق مؤكد.

- يبحث عن كل لاعب باسمه، ويطابقه بالاسم والنادي، ثم يحفظ صورته (قصّها/تصغيرها 200px).
- يكمل من حيث توقف: data/sportsdb_photos.json يسجّل ما عولج (حتى غير الموجودين).
- حد الموقع المجاني 30 طلباً في الدقيقة؛ SDB_MAX يحدد عدد البحث في كل تشغيل.
"""
import difflib
import io
import json
import os
import re
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
LEAGUES_DIR = DATA / "leagues"
IMG = DATA / "images" / "players"
MAP_FILE = DATA / "sportsdb_photos.json"

KEY = os.environ.get("SDB_KEY", "123").strip() or "123"
BASE = f"https://www.thesportsdb.com/api/v1/json/{KEY}"
MAX_SEARCH = int(os.environ.get("SDB_MAX") or 1200)
GAP = 3.0
UA = {"User-Agent": "Mozilla/5.0 (football-manager importer)"}


def norm(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    return re.sub(r"[^a-z0-9 ]+", " ", s).split()


STOP = {"fc", "cf", "ac", "as", "sc", "club", "de", "the", "afc", "fk", "sv", "ss", "us", "ssc", "rc", "real"}


def team_match(a, b):
    ta = [t for t in norm(a) if t not in STOP]
    tb = [t for t in norm(b) if t not in STOP]
    if not ta or not tb:
        return False
    if set(ta) & set(tb):
        return True
    return difflib.SequenceMatcher(None, " ".join(ta), " ".join(tb)).ratio() >= 0.7


def get_json(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8", "replace") or "{}")


def best_match(name, team, results):
    toks = norm(name)
    if not toks:
        return None
    sur, first = toks[-1], toks[0]
    full = " ".join(toks)
    best, best_score = None, 0
    for r in results or []:
        rt = norm(r.get("strPlayer", ""))
        if not rt or rt[-1] != sur:
            continue
        score = 1
        rfirst = rt[0]
        if len(first) <= 2 and rfirst[:1] == first[:1]:
            score += 2
        elif first == rfirst:
            score += 2
        if " ".join(rt) == full:
            score += 1
        if team_match(team, r.get("strTeam", "")):
            score += 2
        if score > best_score:
            best, best_score = r, score
    return best if best_score >= 4 else None


def pick_photo(r):
    for k in ("strCutout", "strThumb", "strRender"):
        if r.get(k):
            return r[k]
    return None


def save_image(url, dest):
    from PIL import Image  # pip install pillow

    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=40) as r:
        data = r.read()
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    im.thumbnail((200, 200))
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, "PNG", optimize=True)


def run():
    done = {}
    if MAP_FILE.exists():
        try:
            done = json.loads(MAP_FILE.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            done = {}
    searches = replaced = blocked = 0
    try:
        for f in sorted(LEAGUES_DIR.glob("*.json")):
            d = json.loads(f.read_text(encoding="utf-8"))
            for t in d.get("teams", []):
                for p in t.get("players", []):
                    pid = str(p["id"])
                    if pid in done:
                        continue
                    if searches >= MAX_SEARCH:
                        print(f"⏸ بلغ حد البحث ({MAX_SEARCH}) — يكمل لاحقاً")
                        return
                    name = p["n"]
                    toks = norm(name)
                    if not toks:
                        done[pid] = None
                        continue
                    query = " ".join(toks) if len(toks[0]) > 2 else toks[-1]
                    url = f"{BASE}/searchplayers.php?p={urllib.parse.quote(query)}"
                    res = None
                    for attempt in range(4):
                        try:
                            res = get_json(url).get("player")
                            blocked = 0
                            break
                        except urllib.error.HTTPError as e:
                            if e.code == 429:
                                blocked += 1
                                print(f"   ⏳ 429 — انتظار 70ث (محاولة {attempt + 1})")
                                time.sleep(70)
                                continue
                            done[pid] = None
                            break
                        except Exception:  # noqa: BLE001
                            break
                    else:
                        print("⛔ حد المعدل مستمر — يكمل لاحقاً")
                        return
                    searches += 1
                    time.sleep(GAP)
                    m = best_match(name, t["name"], res)
                    ph = pick_photo(m) if m else None
                    if not ph:
                        done[pid] = None
                    else:
                        try:
                            save_image(ph, IMG / f"{pid}.png")
                            done[pid] = m.get("idPlayer")
                            replaced += 1
                        except Exception as e:  # noqa: BLE001
                            print(f"   ✗ صورة {name}: {e}")
                            done[pid] = None
                    if searches % 50 == 0:
                        MAP_FILE.write_text(json.dumps(done), encoding="utf-8")
                        print(f"   … {searches} بحثاً، {replaced} صورة محدّثة")
    finally:
        MAP_FILE.write_text(json.dumps(done), encoding="utf-8")
        print(f"📷 TheSportsDB: {searches} بحثاً، {replaced} صورة استُبدلت في هذا التشغيل")


if __name__ == "__main__":
    run()
