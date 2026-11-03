"""Draw the app icon: a magnifying glass whose lens clears yellowed varnish to clean ultramarine.

Usage: python make_icon.py <out.png> [preview.png]
Needs Pillow.
"""
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 4  # supersample for smooth edges
S = SIZE * SS

VARNISH_LIGHT = (214, 164, 78)
VARNISH_DARK = (128, 82, 30)
ULTRAMARINE_LIGHT = (52, 86, 196)
ULTRAMARINE_DARK = (28, 52, 140)
FRAME = (38, 33, 28)


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient(size, c1, c2, centre=None):
    """Radial when centre is given, otherwise diagonal from top left to bottom right."""
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        for x in range(w):
            if centre:
                cx, cy, r = centre
                t = min(1.0, ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r)
            else:
                t = (x + y) / (w + h - 2)
            px[x, y] = lerp(c1, c2, t)
    return img


def main():
    out = sys.argv[1]
    # Work at a small size for the gradients, then scale up; they're smooth anyway.
    small = SIZE // 4

    # Yellowed varnish: a warm diagonal gradient with a little grain.
    bg = gradient((small, small), VARNISH_LIGHT, VARNISH_DARK).resize((S, S), Image.BICUBIC)
    rnd = random.Random(7)
    grain = Image.new("L", (small, small))
    grain.putdata([rnd.randint(118, 138) for _ in range(small * small)])
    grain = grain.resize((S, S), Image.BICUBIC).filter(ImageFilter.GaussianBlur(SS * 2))
    bg = Image.blend(bg, Image.merge("RGB", (grain, grain, grain)), 0.08)

    # Lens geometry.
    cx, cy, r = 0.42 * S, 0.42 * S, 0.25 * S
    rim = 0.055 * S

    # The handle runs down and to the right at 45 degrees.
    draw = ImageDraw.Draw(bg)
    start = (cx + (r + rim * 0.4) * 0.7071, cy + (r + rim * 0.4) * 0.7071)
    end = (0.83 * S, 0.83 * S)
    handle_w = 0.11 * S
    draw.line([start, end], fill=FRAME, width=round(handle_w))
    draw.ellipse([end[0] - handle_w / 2, end[1] - handle_w / 2, end[0] + handle_w / 2, end[1] + handle_w / 2], fill=FRAME)

    # Rim, then the clean ultramarine seen through the lens.
    draw.ellipse([cx - r - rim, cy - r - rim, cx + r + rim, cy + r + rim], fill=FRAME)
    lens_small = gradient((small, small), ULTRAMARINE_LIGHT, ULTRAMARINE_DARK,
                          centre=(small * 0.36, small * 0.36, small * 0.62)).resize((S, S), Image.BICUBIC)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    bg.paste(lens_small, (0, 0), mask)

    # A soft highlight arc on the glass.
    glare = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(glare)
    inset = r * 0.18
    gd.arc([cx - r + inset, cy - r + inset, cx + r - inset, cy + r - inset], start=200, end=255, fill=150, width=round(0.028 * S))
    glare = glare.filter(ImageFilter.GaussianBlur(SS * 3))
    bg.paste((255, 255, 255), (0, 0), glare)

    icon = bg.resize((SIZE, SIZE), Image.LANCZOS)
    icon.save(out)

    if len(sys.argv) > 2:
        # Preview at home-screen sizes, with iOS's rounded corners, on a dark and a light strip.
        strip = Image.new("RGB", (760, 300), (30, 30, 34))
        light = Image.new("RGB", (760, 150), (235, 235, 240))
        strip.paste(light, (0, 150))
        x = 20
        for size in (120, 60, 40):
            for y0 in (15, 165):
                im = icon.resize((size, size), Image.LANCZOS)
                m = Image.new("L", (size, size), 0)
                ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=size * 0.225, fill=255)
                strip.paste(im, (x, y0 + (120 - size) // 2), m)
            x += size + 30
        big = icon.resize((300, 300), Image.LANCZOS)
        m = Image.new("L", (300, 300), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, 299, 299], radius=67, fill=255)
        canvas = Image.new("RGB", (760, 620), (30, 30, 34))
        canvas.paste(big, (230, 10), m)
        canvas.paste(strip, (0, 320))
        canvas.save(sys.argv[2])


if __name__ == "__main__":
    main()
