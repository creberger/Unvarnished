"""Download each painting's public-domain image from its source.

Usage: python fetch_images.py <out_dir> [id ...]
Writes <out_dir>/<id>.jpg (1600px), <out_dir>/<id>-thumb.jpg (480px) and sources.json.
Needs Pillow.
"""
import io
import json
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

from manifest import PAINTINGS

UA = {"User-Agent": "Unvarnished/0.1 (art quiz prototype; christopher@44consulting.net)"}
Image.MAX_IMAGE_PIXELS = None


def get(url, raw=False):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                data = r.read()
                return data if raw else json.loads(data)
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 * (attempt + 1))


def matches(text, words):
    text = text.lower()
    return all(w.lower() in text for w in words)


def from_commons(q, words, exclude=()):
    params = {
        "action": "query", "format": "json", "generator": "search", "gsrnamespace": 6,
        "gsrsearch": q, "gsrlimit": 15, "prop": "imageinfo",
        "iiprop": "url|size|mime|extmetadata", "iiurlwidth": 1600,
    }
    data = get("https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode(params))
    pages = sorted(data.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
    for p in pages:
        info = p["imageinfo"][0]
        meta = info.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "")
        if info["mime"] not in ("image/jpeg", "image/png", "image/tiff"):
            continue
        if not ("public domain" in lic.lower() or lic.lower().startswith("pd") or "cc0" in lic.lower()):
            continue
        if not matches(p["title"], words) or any(x.lower() in p["title"].lower() for x in exclude):
            continue
        if info["width"] < 1000:
            continue
        return {"url": info["thumburl"], "title": p["title"], "page": info["descriptionurl"],
                "license": lic, "credit": "public domain, via Wikimedia Commons"}
    return None


def from_met(q, words):
    data = get("https://collectionapi.metmuseum.org/public/collection/v1.1/search?"
               + urllib.parse.urlencode({"q": q, "hasImages": "true", "limit": 20}))
    for oid in (data.get("objectIDs") or [])[:20]:
        o = get(f"https://collectionapi.metmuseum.org/public/collection/v1/objects/{oid}")
        if not o.get("isPublicDomain") or not o.get("primaryImage"):
            continue
        if not matches(o["title"] + " " + o.get("artistDisplayName", ""), words):
            continue
        return {"url": o["primaryImage"], "title": f'{o["title"]} — {o.get("artistDisplayName", "")}',
                "page": o.get("objectURL"), "license": "CC0",
                "credit": "The Metropolitan Museum of Art, public domain (CC0)"}
    return None


def from_aic(q, words):
    data = get("https://api.artic.edu/api/v1/artworks/search?"
               + urllib.parse.urlencode({"q": q, "limit": 10,
                                         "fields": "id,title,artist_title,image_id,is_public_domain"}))
    for o in data["data"]:
        if not o.get("is_public_domain") or not o.get("image_id"):
            continue
        if not matches(f'{o["title"]} {o.get("artist_title") or ""}', words):
            continue
        return {"url": f'https://www.artic.edu/iiif/2/{o["image_id"]}/full/1686,/0/default.jpg',
                "title": f'{o["title"]} — {o.get("artist_title")}',
                "page": f'https://www.artic.edu/artworks/{o["id"]}', "license": "CC0",
                "credit": "Art Institute of Chicago, public domain (CC0)"}
    return None


def from_cma(q, words):
    data = get("https://openaccess-api.clevelandart.org/api/artworks/?"
               + urllib.parse.urlencode({"q": q, "cc0": 1, "has_image": 1, "limit": 10}))
    for o in data["data"]:
        if o.get("share_license_status") != "CC0":
            continue
        if not matches(o["title"], words):
            continue
        img = o["images"].get("print") or o["images"].get("web")
        return {"url": img["url"], "title": o["title"], "page": o.get("url"), "license": "CC0",
                "credit": "Cleveland Museum of Art, public domain (CC0)"}
    return None


SOURCES = {"commons": from_commons, "met": from_met, "aic": from_aic, "cma": from_cma}


def fetch(entry, out):
    pid, source, q, words, *rest = entry
    if source == "existing" or (ONLY and pid not in ONLY):
        return pid, {"skipped": True}
    try:
        found = SOURCES[source](q, words, *rest)
    except Exception as e:
        return pid, {"error": f"lookup failed: {e}"}
    if not found:
        return pid, {"error": "no public-domain match"}
    try:
        img = Image.open(io.BytesIO(get(found["url"], raw=True))).convert("RGB")
    except Exception as e:
        return pid, {"error": f"download failed: {e}", **found}
    img.thumbnail((1600, 1600), Image.LANCZOS)
    img.save(f"{out}/{pid}.jpg", quality=74, optimize=True, progressive=True)
    thumb = img.copy()
    thumb.thumbnail((480, 480), Image.LANCZOS)
    thumb.save(f"{out}/{pid}-thumb.jpg", quality=72, optimize=True)
    return pid, {**found, "source": source, "width": img.width, "height": img.height}


ONLY = set(sys.argv[2:])


def main():
    out = sys.argv[1]
    with ThreadPoolExecutor(4) as pool:
        results = dict(pool.map(lambda e: fetch(e, out), PAINTINGS))
    path = f"{out}/sources.json"
    try:
        previous = json.load(open(path))
    except FileNotFoundError:
        previous = {}
    previous.update({k: v for k, v in results.items() if not v.get("skipped")})
    with open(path, "w") as f:
        json.dump(previous, f, indent=1, ensure_ascii=False)
    results = {k: v for k, v in results.items() if not v.get("skipped")}
    for pid, r in results.items():
        status = "skip" if r.get("skipped") else ("ERROR " + r["error"] if "error" in r else "ok")
        print(f"{pid:32} {status:10} {r.get('title', '')[:70]}")
    print(len(PAINTINGS), "paintings")


if __name__ == "__main__":
    main()
