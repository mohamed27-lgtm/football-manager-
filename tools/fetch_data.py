#!/usr/bin/env python3
"""استيراد الدوريات والفرق واللاعبين وصورهم من API-Football وتخزينها كملفات.

- يعمل على مراحل ويكمل من حيث توقف (الحصة المجانية 100 طلب يومياً).
- يخزّن:  data/leagues/<id>_<season>.json   بيانات كل دوري
          data/images/{teams,players,leagues}/<id>.png   الصور
- ثم يبني حزماً: packs/league_<id>_<season>.zip + packs/manifest.json
  (تُرفع كأصول إصدار GitHub وتنزّلها اللعبة).
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
LEAGUES_DIR = DATA / "leagues"
IMG = DATA / "images"
PACKS = ROOT / "packs"
MISSING_FILE = DATA / "missing_images.json"

API = "https://v3.football.api-sports.io"
KEY = os.environ.get("API_FOOTBALL_KEY", "").strip()
SEASON = int(os.environ.get("SEASON") or 2023)
ONLY = {int(x) for x in re.split(r"[,\s]+", os.environ.get("LEAGUES", "").strip()) if x}
MAX_IMAGES = int(os.environ.get("MAX_IMAGES") or 5000)
MIN_REMAINING = 3
GAP = 6.6  # ثوانٍ بين الطلبات (حد 10 في الدقيقة)


class Quota(Exception):
    pass


class Api:
    def __init__(self):
        self.last = 0.0
        self.remaining = None
        self.calls = 0

    def exhausted(self):
        return self.remaining is not None and self.remaining <= MIN_REMAINING

    def get(self, path, params, retry=1):
        wait = GAP - (time.time() - self.last)
        if wait > 0:
            time.sleep(wait)
        self.last = time.time()
        url = f"{API}{path}?{urllib.parse.urlencode(params)}"
        req = urllib.request.Request(url, headers={"x-apisports-key": KEY})
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                rem = r.headers.get("x-ratelimit-requests-remaining")
                if rem is not None:
                    self.remaining = int(rem)
                body = json.load(r)
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"HTTP {e.code} على {path}")
        except Exception as e:  # noqa: BLE001
            raise RuntimeError(f"فشل الاتصال بـ {path}: {e}")
        self.calls += 1
        errs = body.get("errors")
        if errs:
            txt = json.dumps(errs, ensure_ascii=False)
            low = txt.lower()
            if "ratelimit" in low and retry > 0:
                time.sleep(62)
                return self.get(path, params, retry - 1)
            if "request limit" in low or "for the day" in low:
                raise Quota(txt)
            raise RuntimeError(txt)
        return body.get("response") or []


def norm(s):
    return re.sub(r"[^a-z]", "", (s or "").lower())


def load_json(p, default=None):
    try:
        return json.loads(Path(p).read_text(encoding="utf-8"))
    except Exception:  # noqa: BLE001
        return default


def save_json(p, obj):
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(p.suffix + ".tmp")
    tmp.write_text(json.dumps(obj, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    tmp.replace(p)


# ───────────── مرحلة 1: البيانات ─────────────

def validated_catalog(api):
    cat = load_json(ROOT / "tools" / "leagues.json", [])
    allf = DATA / f"all_leagues_{SEASON}.json"
    known = load_json(allf)
    if known is None:
        print(f"→ جلب قائمة كل الدوريات لموسم {SEASON} (طلب واحد)")
        res = api.get("/leagues", {"season": SEASON})
        known = {
            str(r["league"]["id"]): {
                "name": r["league"]["name"],
                "type": r["league"].get("type"),
                "logo": r["league"].get("logo"),
                "country": r["country"].get("name"),
            }
            for r in res
        }
        save_json(allf, known)
    ok = []
    for l in cat:
        if ONLY and l["id"] not in ONLY:
            continue
        k = known.get(str(l["id"]))
        if not k:
            print(f"⚠️  الدوري {l['id']} ({l['name']}) غير موجود لموسم {SEASON} — تخطّيته")
            continue
        if norm(k["country"]) != norm(l["en"]):
            print(f"⚠️  المعرّف {l['id']} يعود لدوري «{k['name']}» في {k['country']} وليس {l['en']} — تخطّيته")
            continue
        l = dict(l)
        l["logo"] = k.get("logo")
        l["api_name"] = k["name"]
        ok.append(l)
    return ok


def fetch_league(api, l):
    path = LEAGUES_DIR / f"{l['id']}_{SEASON}.json"
    d = load_json(path)
    if d is None:
        teams = api.get("/teams", {"league": l["id"], "season": SEASON})
        if not teams:
            raise RuntimeError("لا توجد فرق")
        d = {
            "id": l["id"], "name": l["name"], "country": l["country"], "tier": l["tier"],
            "season": SEASON, "at": datetime.now(timezone.utc).isoformat(),
            "logo": l.get("logo"),
            "teams": [
                {
                    "id": t["team"]["id"], "name": t["team"]["name"], "logo": t["team"].get("logo"),
                    "venue": (t.get("venue") or {}).get("name"), "rank": 99 + i, "pts": 0,
                    "loaded": False, "players": [],
                }
                for i, t in enumerate(teams)
            ],
        }
        if not api.exhausted():
            try:
                st = api.get("/standings", {"league": l["id"], "season": SEASON})
                rows = {}
                for g in (st[0]["league"]["standings"] if st else []):
                    for row in g:
                        rows[row["team"]["id"]] = (row["rank"], int(row["points"]))
                for t in d["teams"]:
                    if t["id"] in rows:
                        t["rank"], t["pts"] = rows[t["id"]]
            except (RuntimeError, KeyError, IndexError) as e:
                print(f"   (تعذّر جلب الترتيب: {e})")
        save_json(path, d)
    for t in d["teams"]:
        if t["loaded"]:
            continue
        if api.exhausted():
            raise Quota("الحصة اليومية شارفت على الانتهاء")
        res = api.get("/players/squads", {"team": t["id"]})
        ps = (res[0].get("players") if res else None) or []
        t["players"] = [
            {"id": p["id"], "n": p["name"], "a": p.get("age"), "p": p.get("position") or "",
             "ph": p.get("photo"), "no": p.get("number")}
            for p in ps
        ]
        t["loaded"] = True
        save_json(path, d)
        print(f"   ✓ {t['name']}: {len(ps)} لاعباً (متبقٍ {api.remaining})")
    return d


def phase_data(api):
    if not KEY:
        print("لا يوجد API_FOOTBALL_KEY — تخطّي مرحلة البيانات")
        return
    try:
        cat = validated_catalog(api)
    except Quota as e:
        print(f"⛔ الحصة: {e}")
        return
    except RuntimeError as e:
        print(f"⛔ {e}")
        return
    for l in cat:
        d = load_json(LEAGUES_DIR / f"{l['id']}_{SEASON}.json")
        if d and all(t["loaded"] for t in d["teams"]):
            continue
        print(f"▶ {l['name']} ({l['id']})")
        try:
            fetch_league(api, l)
        except Quota as e:
            print(f"⛔ توقّفت بسبب الحصة، ستُكمل في التشغيل التالي: {e}")
            return
        except RuntimeError as e:
            print(f"   ✗ فشل: {e}")


# ───────────── مرحلة 2: الصور ─────────────

class Blocked(Exception):
    pass


def download(url, dest, missing):
    rel = str(dest.relative_to(IMG))
    if rel in missing:
        return False
    if dest.exists() and dest.stat().st_size > 0:
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (football-manager importer)"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            raise Blocked(f"HTTP {e.code}")
        if e.code == 404:
            missing.add(rel)
        return False
    except Exception:  # noqa: BLE001
        return False
    if not data:
        return False
    dest.write_bytes(data)
    time.sleep(0.04)
    return True


def image_jobs(d):
    jobs = []
    if d.get("logo"):
        jobs.append((d["logo"], IMG / "leagues" / f"{d['id']}.png"))
    for t in d["teams"]:
        if t.get("logo"):
            jobs.append((t["logo"], IMG / "teams" / f"{t['id']}.png"))
        for p in t["players"]:
            if p.get("ph"):
                jobs.append((p["ph"], IMG / "players" / f"{p['id']}.png"))
    return jobs


def phase_images():
    missing = set(load_json(MISSING_FILE, []))
    done = 0
    try:
        for f in sorted(LEAGUES_DIR.glob(f"*_{SEASON}.json")):
            d = load_json(f)
            if not d:
                continue
            for url, dest in image_jobs(d):
                if done >= MAX_IMAGES:
                    print(f"⏸ بلغت حد الصور لهذا التشغيل ({MAX_IMAGES})، تكمل لاحقاً")
                    return
                if download(url, dest, missing):
                    done += 1
    except Blocked as e:
        print(f"⛔ خادم الصور رفض الطلب ({e})، تكمل لاحقاً")
    finally:
        save_json(MISSING_FILE, sorted(missing))
        print(f"🖼  صور جديدة في هذا التشغيل: {done}")


# ───────────── مرحلة 3: الحزم ─────────────

def pack_league(d, missing):
    """يحوّل مسارات الصور إلى مسارات نسبية داخل الحزمة ويُرجع (json, ملفات)"""
    files = {}

    def local(url, folder, ident):
        if not url:
            return None
        src = IMG / folder / f"{ident}.png"
        if src.exists() and src.stat().st_size > 0:
            arc = f"images/{folder}/{ident}.png"
            files[arc] = src
            return arc
        return None

    out = {k: d[k] for k in ("id", "name", "country", "tier", "season", "at")}
    out["logo"] = local(d.get("logo"), "leagues", d["id"])
    out["teams"] = []
    for t in d["teams"]:
        out["teams"].append({
            "id": t["id"], "name": t["name"], "venue": t.get("venue"),
            "rank": t["rank"], "pts": t["pts"], "loaded": True,
            "logo": local(t.get("logo"), "teams", t["id"]),
            "players": [
                {"id": p["id"], "n": p["n"], "a": p.get("a"), "p": p.get("p", ""),
                 "no": p.get("no"), "ph": local(p.get("ph"), "players", p["id"])}
                for p in t["players"]
            ],
        })
    return out, files


def images_complete(d, missing):
    for _url, dest in image_jobs(d):
        rel = str(dest.relative_to(IMG))
        if rel in missing:
            continue
        if not (dest.exists() and dest.stat().st_size > 0):
            return False
    return True


def phase_packs():
    PACKS.mkdir(exist_ok=True)
    missing = set(load_json(MISSING_FILE, []))
    manifest = []
    for f in sorted(LEAGUES_DIR.glob("*.json")):
        d = load_json(f)
        if not d or not d["teams"] or not all(t["loaded"] for t in d["teams"]):
            continue
        if not images_complete(d, missing):
            print(f"… {d['name']}: الصور لم تكتمل بعد، لا حزمة بعد")
            continue
        league_json, files = pack_league(d, missing)
        name = f"league_{d['id']}_{d['season']}.zip"
        out = PACKS / name
        with zipfile.ZipFile(out, "w") as z:
            z.writestr("league.json", json.dumps(league_json, ensure_ascii=False), zipfile.ZIP_DEFLATED)
            for arc, src in sorted(files.items()):
                z.write(src, arc, compress_type=zipfile.ZIP_STORED)  # PNG مضغوطة أصلاً
        manifest.append({
            "id": d["id"], "name": d["name"], "country": d["country"], "tier": d["tier"],
            "season": d["season"], "teams": len(d["teams"]),
            "players": sum(len(t["players"]) for t in d["teams"]),
            "bytes": out.stat().st_size, "file": name,
        })
        print(f"📦 {name} ({out.stat().st_size / 1e6:.1f} MB)")
    save_json(PACKS / "manifest.json", {
        "version": 1,
        "generated": datetime.now(timezone.utc).isoformat(),
        "packs": manifest,
    })


def main():
    api = Api()
    phase_data(api)
    phase_images()
    try:
        import fetch_sportsdb

        fetch_sportsdb.run()
    except Exception as e:  # noqa: BLE001
        print(f"⚠️ تخطّي صور TheSportsDB: {e}")
    phase_packs()
    print(f"انتهى. طلبات API في هذا التشغيل: {api.calls}")


if __name__ == "__main__":
    sys.exit(main())
