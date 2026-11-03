"""Swap rewritten statements into the content files (and milkmaid.json) in place.

Usage: python apply_rewrites.py <rewrites.txt> [...]

Format:

    ## painting-id
    @3 New hint (optional; leave blank after @3 to keep the old one)
    + The true statement || Why
    - A false statement || Why
    - Another false statement || Why

Each @N replaces round N's hint (if given) and all three of its statements.
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "tools", "content")
MILKMAID = os.path.join(ROOT, "OneTrueThing", "Paintings", "milkmaid.json")


def parse(path):
    out, pid, rnd = {}, None, None
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("## "):
            pid = line[3:].strip()
            out[pid] = {}
        elif line.startswith("@"):
            num, _, hint = line[1:].partition(" ")
            rnd = int(num)
            out[pid][rnd] = {"hint": hint.strip() or None, "statements": []}
        elif line[0] in "+-":
            text, _, why = line[1:].partition("||")
            assert why.strip(), f"{path}:{n}: statement needs a why"
            out[pid][rnd]["statements"].append((line[0], text.strip(), why.strip()))
        else:
            raise ValueError(f"{path}:{n}: can't read: {line}")
    for pid, rounds in out.items():
        for r, data in rounds.items():
            s = data["statements"]
            assert len(s) == 3 and sum(k == "+" for k, _, _ in s) == 1, f"{pid} round {r}: need 3 with one true"
    return out


def apply_to_text(lines, rewrites):
    result, pid, rnd, skip = [], None, 0, False
    for line in lines:
        s = line.strip()
        if s.startswith("## "):
            pid, rnd, skip = s[3:].split("|")[0].strip(), 0, False
        elif s.startswith("@") and pid:
            rnd += 1
            skip = False
            new = rewrites.get(pid, {}).get(rnd)
            if new:
                parts = line.rstrip("\n").split("|")
                if new["hint"]:
                    parts[3] = " " + new["hint"]
                result.append("|".join(parts).rstrip() + "\n")
                result += [f"{k} {t} || {w}\n" for k, t, w in new["statements"]]
                skip = True
                rewrites[pid].pop(rnd)
                continue
        elif s and s[0] in "+-" and skip:
            continue
        result.append(line)
    return result


def main():
    rewrites = {}
    for path in sys.argv[1:]:
        for pid, rounds in parse(path).items():
            rewrites.setdefault(pid, {}).update(rounds)
    for path in sorted(glob.glob(os.path.join(CONTENT, "*.txt"))):
        lines = open(path, encoding="utf-8").readlines()
        open(path, "w", encoding="utf-8").writelines(apply_to_text(lines, rewrites))
    if rewrites.get("milkmaid"):
        data = json.load(open(MILKMAID, encoding="utf-8"))
        for rnd, new in list(rewrites["milkmaid"].items()):
            r = data["rounds"][rnd - 1]
            if new["hint"]:
                r["hint"] = new["hint"]
            r["statements"] = [{"text": t, "why": w, **({"isTrue": True} if k == "+" else {})}
                               for k, t, w in new["statements"]]
            rewrites["milkmaid"].pop(rnd)
        with open(MILKMAID, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1, ensure_ascii=False)
    left = {p: sorted(r) for p, r in rewrites.items() if r}
    assert not left, f"not applied (unknown painting or round): {left}"
    print("applied", sum(1 for _ in sys.argv[1:]), "file(s)")


if __name__ == "__main__":
    main()
