"""Make the home screen's background: every painting in black and white, tiled into one image.

Usage: python make_mosaic.py <out.jpg>
Reads the thumbnails in OneTrueThing/Paintings. Needs Pillow.
"""
import glob
import os
import random
import sys

from PIL import Image, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAINTINGS = os.path.join(ROOT, "OneTrueThing", "Paintings")
COLS, ROWS, TILE = 8, 14, 150  # a tall grid to fill a phone screen


def main():
    thumbs = sorted(glob.glob(os.path.join(PAINTINGS, "*-thumb.jpg")))
    rnd = random.Random(1434)  # fixed order, so the mosaic only changes when the paintings do
    rnd.shuffle(thumbs)
    tiles = []
    for path in thumbs:
        img = Image.open(path).convert("L")
        img = ImageOps.fit(img, (TILE, TILE), Image.LANCZOS)
        tiles.append(ImageOps.autocontrast(img, cutoff=1))
    mosaic = Image.new("L", (COLS * TILE, ROWS * TILE))
    for i in range(COLS * ROWS):
        mosaic.paste(tiles[i % len(tiles)], ((i % COLS) * TILE, (i // COLS) * TILE))
    mosaic.save(sys.argv[1], quality=70, optimize=True, progressive=True)
    print(f"{len(tiles)} paintings, {mosaic.size[0]}x{mosaic.size[1]}")


if __name__ == "__main__":
    main()
