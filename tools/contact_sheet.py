"""Make contact sheets with a 10% grid over each painting, for choosing zoom focus points.

Usage: python contact_sheet.py <image_dir> <out_dir> [per_sheet]
"""
import sys

from PIL import Image, ImageDraw

from manifest import PAINTINGS

CELL = 380


def cell(path, label):
    img = Image.open(path).convert("RGB")
    img.thumbnail((CELL, CELL - 20))
    out = Image.new("RGB", (CELL, CELL), (255, 255, 255))
    ox, oy = (CELL - img.width) // 2, 20
    out.paste(img, (ox, oy))
    d = ImageDraw.Draw(out)
    for i in range(1, 10):
        x = ox + img.width * i / 10
        y = oy + img.height * i / 10
        colour = (255, 0, 255) if i == 5 else (0, 255, 255)
        d.line([(x, oy), (x, oy + img.height)], fill=colour, width=1)
        d.line([(ox, y), (ox + img.width, y)], fill=colour, width=1)
        d.text((x + 2, oy + 2), str(i), fill=(255, 255, 0))
        d.text((ox + 2, y + 2), str(i), fill=(255, 255, 0))
    d.text((4, 4), f"{label}  {img.width}x{img.height}", fill=(0, 0, 0))
    return out


def main():
    src, out = sys.argv[1], sys.argv[2]
    per = int(sys.argv[3]) if len(sys.argv) > 3 else 12
    ids = [p[0] for p in PAINTINGS]
    cols = 4
    for n in range(0, len(ids), per):
        batch = ids[n:n + per]
        rows = (len(batch) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * CELL, rows * CELL), (255, 255, 255))
        for i, pid in enumerate(batch):
            sheet.paste(cell(f"{src}/{pid}.jpg", f"{n + i + 1}. {pid}"), ((i % cols) * CELL, (i // cols) * CELL))
        sheet.save(f"{out}/sheet-{n // per + 1:02}.jpg", quality=80)
        print(f"sheet-{n // per + 1:02}: {', '.join(batch)}")


if __name__ == "__main__":
    main()
