"""ينسخ بيانات الدوريات من data/leagues إلى assets/leagues ويبني index.json (يُشغَّل قبل بناء التطبيق)."""
import json, pathlib, shutil

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
    shutil.copy(f, dst / f.name)
    index.append({"id": d["id"], "season": d["season"], "file": f.name})
(dst / "index.json").write_text(json.dumps(index, ensure_ascii=False), encoding="utf-8")
print(f"bundled {len(index)} leagues")
