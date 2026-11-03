"""Turn the hand-written rounds in content/*.txt into the app's JSON, and check them.

Usage: python build_content.py <image_dir>
Copies each painting's images from <image_dir> into the app and writes OneTrueThing/Paintings/<batch>.json.

Format (one block per painting):

    ## id | Title | Artist | artist dates | date | medium | collection
    desc: What the image shows, for VoiceOver.
    @ x y zoom | Where label | Prompt | Hint
    + The true statement || Why it's true
    - A false statement || Why it's false
    - Another false statement || Why it's false
    (five @ rounds per painting)
"""
import glob
import json
import os
import shutil
import sys

from categories import CATEGORIES

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "tools", "content")
OUT = os.path.join(ROOT, "OneTrueThing", "Paintings")


def parse(path):
    paintings, p, r = [], None, None
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.strip()
        if not line or line.startswith("#!"):
            continue
        where = f"{os.path.basename(path)}:{n}"
        if line.startswith("## "):
            f = [x.strip() for x in line[3:].split("|")]
            assert len(f) == 7, f"{where}: header needs 7 fields"
            p = dict(zip(["id", "title", "artist", "artistDates", "date", "medium", "collection"], f))
            p["rounds"], p["_where"] = [], where
            paintings.append(p)
        elif line.startswith("desc:"):
            p["imageDescription"] = line[5:].strip()
        elif line.startswith("@"):
            f = [x.strip() for x in line[1:].split("|")]
            assert len(f) == 4, f"{where}: round needs 4 fields"
            x, y, z = (float(v) for v in f[0].split())
            assert 0 <= x <= 1 and 0 <= y <= 1 and 1 <= z <= 4, f"{where}: bad focus"
            r = {"focus": {"x": x, "y": y, "zoom": z}, "where": f[1], "prompt": f[2], "hint": f[3], "statements": []}
            p["rounds"].append(r)
        elif line[0] in "+-":
            text, _, why = line[1:].partition("||")
            assert why.strip(), f"{where}: statement needs a why"
            s = {"text": text.strip(), "why": why.strip()}
            if line[0] == "+":
                s["isTrue"] = True
            r["statements"].append(s)
        else:
            raise ValueError(f"{where}: can't read line: {line}")
    return paintings


def check(p):
    w = p.pop("_where")
    assert "imageDescription" in p, f"{w}: missing desc"
    assert len(p["rounds"]) == 5, f"{w}: {p['id']} has {len(p['rounds'])} rounds"
    for i, r in enumerate(p["rounds"], 1):
        assert len(r["statements"]) == 3, f"{w}: {p['id']} round {i} needs 3 statements"
        assert sum(s.get("isTrue", False) for s in r["statements"]) == 1, f"{w}: {p['id']} round {i} needs one true"


def main():
    images = sys.argv[1]
    sources = json.load(open(os.path.join(images, "sources.json")))
    category_of = {}
    for cid, _, _, ids in CATEGORIES:
        for pid in ids:
            assert pid not in category_of, f"{pid} is in two categories"
            category_of[pid] = cid
    seen = set()
    for path in sorted(glob.glob(os.path.join(CONTENT, "*.txt"))):
        batch = parse(path)
        for p in batch:
            check(p)
            assert p["id"] not in seen, f"duplicate {p['id']}"
            seen.add(p["id"])
            src = sources.get(p["id"], {})
            p["credit"] = f'Image: {src.get("credit", "public domain")}'
            assert p["id"] in category_of, f"{p['id']} has no category"
            p["category"] = category_of[p["id"]]
            for suffix in (".jpg", "-thumb.jpg"):
                shutil.copy(os.path.join(images, p["id"] + suffix), os.path.join(OUT, p["id"] + suffix))
        name = os.path.splitext(os.path.basename(path))[0]
        with open(os.path.join(OUT, f"{name}.json"), "w", encoding="utf-8") as f:
            json.dump(batch, f, indent=1, ensure_ascii=False)
        print(f"{name}: {len(batch)} paintings")
    print(len(seen), "paintings from content files")

    # Paintings written straight as JSON (like milkmaid.json) get their category here too.
    for path in glob.glob(os.path.join(OUT, "*.json")):
        name = os.path.basename(path)
        if name == "categories.json" or os.path.splitext(name)[0] in {os.path.splitext(os.path.basename(c))[0] for c in glob.glob(os.path.join(CONTENT, "*.txt"))}:
            continue
        data = json.load(open(path, encoding="utf-8"))
        for p in data if isinstance(data, list) else [data]:
            assert p["id"] in category_of, f"{p['id']} has no category"
            p["category"] = category_of[p["id"]]
            seen.add(p["id"])
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1, ensure_ascii=False)

    missing = set(category_of) - seen
    assert not missing, f"categorised but missing: {missing}"
    with open(os.path.join(OUT, "categories.json"), "w", encoding="utf-8") as f:
        json.dump([{"id": c, "name": n, "span": s} for c, n, s, _ in CATEGORIES], f, indent=1, ensure_ascii=False)
    print(len(CATEGORIES), "categories,", len(seen), "paintings in all")


if __name__ == "__main__":
    main()
