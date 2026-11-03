"""Draw the app icon: a pair of eyes looking closely at a Mondrian.

Usage: python make_icon.py <out.png> [preview.png] [--style peek|eyes]
Needs Pillow.
"""
import math
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
SS = 3  # supersample for smooth edges
S = SIZE * SS

VARNISH_LIGHT = (176, 128, 54)
VARNISH_DARK = (74, 46, 18)
ULTRAMARINE_LIGHT = (70, 108, 222)
ULTRAMARINE_DARK = (24, 46, 138)
LEAD_TIN_YELLOW = (232, 196, 88)
SERIF = "/System/Library/Fonts/Supplemental/Didot.ttc"


def radial(size, inner, outer, cx, cy, r):
    """A radial gradient, drawn small and scaled up since it's smooth anyway."""
    w, h = size
    sw, sh = max(1, w // 8), max(1, h // 8)
    img = Image.new("RGB", (sw, sh))
    px = img.load()
    for y in range(sh):
        for x in range(sw):
            t = min(1.0, math.hypot(x - cx * sw, y - cy * sh) / (r * max(sw, sh)))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(inner, outer))
    return img.resize(size, Image.BICUBIC)


def craquelure(seed=11):
    """A web of fine cracks, like aged varnish: random wandering lines that branch."""
    rnd = random.Random(seed)
    mask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(mask)
    for _ in range(70):
        x, y = rnd.uniform(0, S), rnd.uniform(0, S)
        angle = rnd.uniform(0, math.tau)
        for _ in range(rnd.randint(6, 14)):
            step = rnd.uniform(0.02, 0.06) * S
            angle += rnd.uniform(-0.7, 0.7)
            nx, ny = x + math.cos(angle) * step, y + math.sin(angle) * step
            d.line([(x, y), (nx, ny)], fill=255, width=max(1, SS))
            if rnd.random() < 0.25:
                angle += rnd.choice([-1, 1]) * math.pi / 2.5
            x, y = nx, ny
    return mask.filter(ImageFilter.GaussianBlur(SS * 0.6))


def varnish():
    bg = radial((S, S), VARNISH_LIGHT, VARNISH_DARK, 0.35, 0.3, 1.05)
    cracks = craquelure()
    dark = Image.new("RGB", (S, S), (40, 24, 8))
    return Image.composite(dark, bg, cracks.point(lambda v: v * 0.55))


def clean_paint():
    paint = radial((S, S), ULTRAMARINE_LIGHT, ULTRAMARINE_DARK, 0.3, 0.25, 1.1)
    # A sliver of lead-tin yellow, as on Vermeer's turbans and bodices.
    band = Image.new("L", (S, S), 0)
    ImageDraw.Draw(band).polygon([(0.55 * S, S), (S, 0.62 * S), (S, 0.78 * S), (0.75 * S, S)], fill=255)
    return Image.composite(Image.new("RGB", (S, S), LEAD_TIN_YELLOW), paint, band.filter(ImageFilter.GaussianBlur(SS * 6)))


def window_mask():
    """A rectangular cleaning test patch, slightly soft-edged like a swabbed area."""
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0.24 * S, 0.24 * S, 0.76 * S, 0.76 * S], radius=0.03 * S, fill=255)
    return m.filter(ImageFilter.GaussianBlur(SS * 1.5))


def stroke_mask():
    """One broad swab stroke across the varnish, with a ragged edge."""
    rnd = random.Random(3)
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    for i in range(240):
        t = i / 239
        x = (0.16 + 0.68 * t) * S
        y = (0.82 - 0.64 * t) * S
        r = (0.15 + 0.03 * math.sin(t * 9) + rnd.uniform(-0.01, 0.01)) * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    return m.filter(ImageFilter.GaussianBlur(SS * 2))


def letter_mask():
    """A large serif U."""
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    font = ImageFont.truetype(SERIF, int(0.86 * S))
    l, t, r, b = d.textbbox((0, 0), "U", font=font)
    d.text(((S - (r - l)) / 2 - l, (S - (b - t)) / 2 - t), "U", font=font, fill=255)
    return m


def draw(style):
    base = varnish()
    mask = {"window": window_mask, "stroke": stroke_mask, "letter": letter_mask}[style]()
    out = Image.composite(clean_paint(), base, mask)
    # A soft shadow where the clean paint meets the varnish, so the edge reads at small sizes.
    edge = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(SS * 5 | 1)), mask).filter(ImageFilter.GaussianBlur(SS * 3))
    out = Image.composite(Image.new("RGB", (S, S), (30, 18, 6)), out, edge.point(lambda v: v * 0.5))
    return out.resize((SIZE, SIZE), Image.LANCZOS)


MONDRIAN_RED = (214, 40, 34)
MONDRIAN_BLUE = (24, 64, 168)
MONDRIAN_YELLOW = (246, 202, 32)
CANVAS = (244, 241, 232)
LINE = (20, 20, 22)


def mondrian(height):
    """A Mondrian-style grid of thick black lines and primary colours, filling the top of the icon."""
    img = Image.new("RGB", (S, height), CANVAS)
    d = ImageDraw.Draw(img)
    w = int(0.045 * S)
    x1, x2 = int(0.30 * S), int(0.86 * S)
    y1, y2 = int(0.24 * height), int(0.70 * height)
    d.rectangle([x1, 0, S, y2], fill=MONDRIAN_RED)
    d.rectangle([0, y2, x1, height], fill=MONDRIAN_BLUE)
    d.rectangle([x2, y2, S, height], fill=MONDRIAN_YELLOW)
    for x in (x1, x2):
        d.rectangle([x - w // 2, y2 if x == x2 else 0, x + w // 2, height], fill=LINE)
    d.rectangle([0, y1 - w // 2, x1, y1 + w // 2], fill=LINE)
    d.rectangle([0, y2 - w // 2, S, y2 + w // 2], fill=LINE)
    d.rectangle([x2, int(0.86 * height) - w // 2, S, int(0.86 * height) + w // 2], fill=LINE)
    return img


def eyes(img, cx, cy, spread, rx, ry, look):
    """Two eyes centred on (cx, cy), pupils shifted by `look` (dx, dy, as fractions of the eye)."""
    d = ImageDraw.Draw(img)
    for side in (-1, 1):
        ex = cx + side * spread
        d.ellipse([ex - rx, cy - ry, ex + rx, cy + ry], fill=(250, 250, 248), outline=LINE, width=int(0.014 * S))
        pr = 0.5 * rx
        px, py = ex + look[0] * (rx - pr), cy + look[1] * (ry - pr)
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=LINE)
        hr = 0.32 * pr
        d.ellipse([px - 0.35 * pr - hr, py - 0.35 * pr - hr, px - 0.35 * pr + hr, py - 0.35 * pr + hr], fill=(255, 255, 255))


def draw_peek():
    """The Mondrian on the wall, and a dark head peeking up from the bottom edge, eyes looking up at it."""
    img = Image.new("RGB", (S, S), CANVAS)
    img.paste(mondrian(int(0.70 * S)), (0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, int(0.70 * S), S, S], fill=(214, 208, 196))  # gallery wall below the frame
    d.rectangle([0, int(0.70 * S) - int(0.012 * S), S, int(0.70 * S) + int(0.012 * S)], fill=LINE)
    head = (34, 30, 30)
    d.ellipse([0.14 * S, 0.66 * S, 0.86 * S, 1.38 * S], fill=head)
    eyes(img, 0.5 * S, 0.84 * S, 0.15 * S, 0.12 * S, 0.1 * S, (0.15, -0.75))
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def draw_eyes():
    """The Mondrian fills the icon, with a big pair of eyes in front looking up at it."""
    img = mondrian(S)
    eyes(img, 0.5 * S, 0.74 * S, 0.19 * S, 0.16 * S, 0.13 * S, (0.2, -0.75))
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def rounded(img, size):
    im = img.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=size * 0.225, fill=255)
    return im, m


def preview(icons, path):
    """Each option large, then at home-screen and Settings sizes, on dark and light strips."""
    cols = len(icons)
    sheet = Image.new("RGB", (cols * 340 + 20, 560), (30, 30, 34))
    ImageDraw.Draw(sheet).rectangle([0, 420, sheet.width, 560], fill=(235, 235, 240))
    d = ImageDraw.Draw(sheet)
    for i, (name, icon) in enumerate(icons):
        x = 20 + i * 340
        im, m = rounded(icon, 300)
        sheet.paste(im, (x, 20), m)
        d.text((x, 330), name, fill=(220, 220, 220))
        for j, s in enumerate((60, 40)):
            for y in (350, 440):
                im, m = rounded(icon, s)
                sheet.paste(im, (x + j * 80, y + (60 - s) // 2), m)
    sheet.save(path)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    style = next((a.split("=")[1] for a in sys.argv[1:] if a.startswith("--style=")), "peek")
    styles = {"peek": draw_peek, "eyes": draw_eyes}
    if len(args) > 1:
        icons = [(name, f()) for name, f in styles.items()]
        preview(icons, args[1])
        dict(icons)[style].save(args[0])
    else:
        styles[style]().save(args[0])


if __name__ == "__main__":
    main()
