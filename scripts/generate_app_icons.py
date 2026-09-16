#!/usr/bin/env python3
"""Generate Droword alternate app icons (1024 / @2x 120 / @3x 180)."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / "Droword" / "AlternateIcons"
APPICONSET = REPO / "Droword" / "Assets.xcassets" / "AppIcon.appiconset"
CLASSIC = APPICONSET / "AppIcon-Any-Appearance.png"
MASK_PATH = Path(__file__).resolve().parent / "quote_mask.png"
SIZE = 1024


def load_quote_mask() -> Image.Image:
    if MASK_PATH.exists():
        src = Image.open(MASK_PATH).convert("L")
        if src.size != (SIZE, SIZE):
            src = src.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        return src

    src = Image.open(CLASSIC).convert("L")
    if src.size != (SIZE, SIZE):
        src = src.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    # Quotes are dark on white. White in mask = quote pixels.
    mask = src.point(lambda p: 255 if p < 140 else 0)
    mask.save(MASK_PATH)
    return mask


QUOTE_MASK = load_quote_mask()


def rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def new_canvas(color: tuple[int, int, int]) -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (*color, 255))


def vertical_gradient(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        for x in range(SIZE):
            px[x, y] = (r, g, b, 255)
    return img


def linear_gradient(
    c1: tuple[int, int, int], c2: tuple[int, int, int], angle: float
) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    rad = math.radians(angle)
    dx, dy = math.cos(rad), math.sin(rad)
    min_p = max_p = 0.0
    corners = [(0, 0), (SIZE - 1, 0), (0, SIZE - 1), (SIZE - 1, SIZE - 1)]
    projs = [x * dx + y * dy for x, y in corners]
    min_p, max_p = min(projs), max(projs)
    span = max_p - min_p or 1
    for y in range(SIZE):
        for x in range(SIZE):
            t = ((x * dx + y * dy) - min_p) / span
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            px[x, y] = (r, g, b, 255)
    return img


def radial_gradient(
    inner: tuple[int, int, int], outer: tuple[int, int, int], cx=0.5, cy=0.45
) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    ox, oy = cx * SIZE, cy * SIZE
    max_d = math.hypot(SIZE, SIZE) * 0.72
    for y in range(SIZE):
        for x in range(SIZE):
            t = min(1.0, math.hypot(x - ox, y - oy) / max_d)
            t = t * t
            r = int(inner[0] + (outer[0] - inner[0]) * t)
            g = int(inner[1] + (outer[1] - inner[1]) * t)
            b = int(inner[2] + (outer[2] - inner[2]) * t)
            px[x, y] = (r, g, b, 255)
    return img


def paste_quotes(base: Image.Image, color, mask: Image.Image | None = None) -> Image.Image:
    m = mask or QUOTE_MASK
    if isinstance(color, Image.Image):
        layer = color.convert("RGBA")
    else:
        if len(color) == 3:
            color = (*color, 255)
        layer = Image.new("RGBA", (SIZE, SIZE), color)
    out = base.convert("RGBA")
    out.paste(layer, (0, 0), m)
    return out


def gloss(img: Image.Image, strength: int = 48) -> Image.Image:
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-SIZE * 0.2, -SIZE * 0.72, SIZE * 1.2, SIZE * 0.55), fill=(255, 255, 255, strength))
    overlay = overlay.filter(ImageFilter.GaussianBlur(80))
    return Image.alpha_composite(img, overlay)


def vignette(img: Image.Image, amount: int = 70) -> Image.Image:
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-80, -80, SIZE + 80, SIZE + 80), outline=None)
    # radial darken via noise-free gradient
    px = overlay.load()
    cx = cy = SIZE / 2
    max_d = math.hypot(cx, cy)
    for y in range(SIZE):
        for x in range(SIZE):
            t = math.hypot(x - cx, y - cy) / max_d
            a = int(max(0, (t - 0.45) / 0.55) ** 1.6 * amount)
            px[x, y] = (0, 0, 0, a)
    return Image.alpha_composite(img, overlay)


def grain(img: Image.Image, amount: float = 18, seed: int = 1) -> Image.Image:
    rng = random.Random(seed)
    noise = Image.effect_noise((SIZE, SIZE), amount).convert("L")
    # mix a little extra speckle
    px = noise.load()
    for _ in range(8000):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        px[x, y] = min(255, px[x, y] + rng.randint(20, 80))
    noise = Image.merge("RGBA", (noise, noise, noise, Image.new("L", (SIZE, SIZE), 40)))
    return ImageChops.overlay(img.convert("RGBA"), noise)


def wavy_bands(colors: list[tuple[int, int, int]], amp=38.0, freq=2.4) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    n = len(colors)
    for y in range(SIZE):
        offset = math.sin(y / SIZE * math.pi * freq) * amp
        for x in range(SIZE):
            t = ((x + offset) / SIZE) % 1.0
            i = min(n - 1, int(t * n))
            px[x, y] = (*colors[i], 255)
    return img.filter(ImageFilter.GaussianBlur(1.2))


def concentric_rings(
    c1: tuple[int, int, int], c2: tuple[int, int, int], rings: int = 14
) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (*c2, 255))
    d = ImageDraw.Draw(img)
    cx = cy = SIZE / 2
    for i in range(rings, 0, -1):
        t = i / rings
        col = (
            int(c1[0] + (c2[0] - c1[0]) * (1 - t)),
            int(c1[1] + (c2[1] - c1[1]) * (1 - t)),
            int(c1[2] + (c2[2] - c1[2]) * (1 - t)),
        )
        r = t * SIZE * 0.78
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*col, 255))
    return img.filter(ImageFilter.GaussianBlur(6))


def rainbow_fill() -> Image.Image:
    stops = [
        rgb("FF2D55"),
        rgb("FF9F0A"),
        rgb("FFD60A"),
        rgb("30D158"),
        rgb("64D2FF"),
        rgb("BF5AF2"),
    ]
    bbox = QUOTE_MASK.getbbox() or (0, 0, SIZE, SIZE)
    y0, y1 = bbox[1], bbox[3]
    span = max(1, y1 - y0)
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    n = len(stops) - 1
    for y in range(SIZE):
        t = max(0.0, min(1.0, (y - y0) / span)) * n
        i = min(n - 1, int(t))
        f = t - i
        c1, c2 = stops[i], stops[i + 1]
        col = (
            int(c1[0] + (c2[0] - c1[0]) * f),
            int(c1[1] + (c2[1] - c1[1]) * f),
            int(c1[2] + (c2[2] - c1[2]) * f),
            255,
        )
        for x in range(SIZE):
            px[x, y] = col
    return img


def letter_grid() -> Image.Image:
    img = new_canvas(rgb("F4ECDF"))
    d = ImageDraw.Draw(img)
    glyphs = list("あA字한ああ字A한字A한")
    rng = random.Random(7)
    for i, ch in enumerate(glyphs * 40):
        x = (i * 86) % SIZE
        y = (i * 86) // SIZE * 92 - 20
        if y > SIZE:
            break
        d.text((x + rng.randint(-8, 8), y), ch, fill=(40, 32, 24, 28))
    faint = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fd = ImageDraw.Draw(faint)
    for y in range(0, SIZE, 48):
        fd.line((0, y, SIZE, y), fill=(90, 70, 50, 18), width=1)
    for x in range(0, SIZE, 48):
        fd.line((x, 0, x, SIZE), fill=(90, 70, 50, 14), width=1)
    return Image.alpha_composite(img, faint)


def draw_stars(d: ImageDraw.ImageDraw, cx, cy, r, color, n=5):
    pts = []
    for i in range(n * 2):
        ang = math.radians(-90 + i * 180 / n)
        rad = r if i % 2 == 0 else r * 0.4
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=color)


# ── backgrounds ──


def bg_classic() -> Image.Image:
    img = radial_gradient(rgb("FFFFFF"), rgb("E4EAF1"), 0.48, 0.38)
    return gloss(img, 26)


def bg_classic_dark() -> Image.Image:
    img = radial_gradient(rgb("2C2C30"), rgb("111114"), 0.42, 0.32)
    return gloss(vignette(img, 50), 22)


def bg_night() -> Image.Image:
    img = radial_gradient(rgb("2A2438"), rgb("0B0B10"), 0.35, 0.3)
    specks = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sp = specks.load()
    rng = random.Random(3)
    for _ in range(220):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        a = rng.randint(40, 160)
        sp[x, y] = (255, 255, 255, a)
    specks = specks.filter(ImageFilter.GaussianBlur(0.6))
    img = Image.alpha_composite(img, specks)
    return gloss(vignette(img, 90), 28)


def bg_grain() -> Image.Image:
    img = radial_gradient(rgb("3A3A42"), rgb("16161A"))
    img = grain(img, 28, seed=11)
    return gloss(img, 22)


def bg_neon() -> Image.Image:
    img = new_canvas(rgb("07070C"))
    d = ImageDraw.Draw(img)
    for i, col in enumerate([(255, 45, 120, 40), (40, 220, 255, 36), (180, 80, 255, 32)]):
        y = 180 + i * 220
        d.rounded_rectangle((-40, y, SIZE + 40, y + 70), 40, outline=col[:3] + (0,), width=0)
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.rectangle((0, y, SIZE, y + 16), fill=col)
        glow = glow.filter(ImageFilter.GaussianBlur(28))
        img = Image.alpha_composite(img, glow)
    # faint grid
    grid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    for i in range(0, SIZE, 64):
        g.line((i, 0, i, SIZE), fill=(255, 255, 255, 12), width=1)
        g.line((0, i, SIZE, i), fill=(255, 255, 255, 12), width=1)
    return gloss(Image.alpha_composite(img, grid), 18)


def bg_aurora() -> Image.Image:
    img = new_canvas(rgb("12082A"))
    blobs = [
        ((-200, 80, 700, 700), rgb("7C3AED")),
        ((400, -100, 1200, 620), rgb("2563EB")),
        ((100, 400, 980, 1200), rgb("EC4899")),
        ((-100, 500, 600, 1100), rgb("22D3EE")),
    ]
    for box, col in blobs:
        layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse(box, fill=(*col, 160))
        layer = layer.filter(ImageFilter.GaussianBlur(90))
        img = Image.alpha_composite(img, layer)
    return gloss(vignette(img, 50), 36)


def bg_sun() -> Image.Image:
    img = radial_gradient(rgb("FFCC4D"), rgb("C2185B"), 0.5, 0.42)
    warm = radial_gradient(rgb("FF6B1A"), rgb("7B1FA2"), 0.55, 0.55)
    img = Image.blend(img, warm, 0.45)
    rays = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(rays)
    cx = cy = SIZE / 2
    for i in range(28):
        a0 = math.radians(i * (360 / 28) - 3)
        a1 = math.radians(i * (360 / 28) + 3)
        pts = [
            (cx, cy),
            (cx + 900 * math.cos(a0), cy + 900 * math.sin(a0)),
            (cx + 900 * math.cos(a1), cy + 900 * math.sin(a1)),
        ]
        d.polygon(pts, fill=(255, 220, 120, 36 if i % 2 == 0 else 14))
    img = Image.alpha_composite(img.convert("RGBA"), rays)
    return gloss(img, 32)


def bg_ocean() -> Image.Image:
    img = wavy_bands(
        [rgb("0B3D4A"), rgb("127A8A"), rgb("1DB8B0"), rgb("7EE0D6"), rgb("127A8A"), rgb("0B3D4A")],
        amp=70,
        freq=3.1,
    )
    return gloss(vignette(img, 40), 30)


def bg_forest() -> Image.Image:
    img = vertical_gradient(rgb("1A3B22"), rgb("0D1F14"))
    d = ImageDraw.Draw(img)
    rng = random.Random(5)
    for i in range(18):
        x = rng.randint(-80, SIZE)
        w = rng.randint(90, 220)
        h = rng.randint(400, 900)
        y = SIZE - h + 80
        col = (rng.randint(20, 50), rng.randint(90, 140), rng.randint(40, 70), 70)
        d.ellipse((x, y, x + w, y + h), fill=col)
    img = img.filter(ImageFilter.GaussianBlur(8))
    return gloss(grain(img, 10, seed=4), 20)


def bg_english() -> Image.Image:
    """Union Jack — UK, not US."""
    blue, white, red = rgb("012169"), rgb("FFFFFF"), rgb("C8102E")
    img = new_canvas(blue)
    d = ImageDraw.Draw(img)
    d.line((0, 0, SIZE, SIZE), fill=white, width=int(SIZE * 0.26))
    d.line((SIZE, 0, 0, SIZE), fill=white, width=int(SIZE * 0.26))
    d.line((0, 0, SIZE, SIZE), fill=red, width=int(SIZE * 0.09))
    d.line((SIZE, 0, 0, SIZE), fill=red, width=int(SIZE * 0.09))
    cross = SIZE * 0.28
    bar = SIZE * 0.16
    mid = SIZE / 2
    d.rectangle((mid - cross / 2, 0, mid + cross / 2, SIZE), fill=white)
    d.rectangle((0, mid - cross / 2, SIZE, mid + cross / 2), fill=white)
    d.rectangle((mid - bar / 2, 0, mid + bar / 2, SIZE), fill=red)
    d.rectangle((0, mid - bar / 2, SIZE, mid + bar / 2), fill=red)
    return gloss(img, 22)


def bg_portuguese() -> Image.Image:
    """Portugal flag: green hoist, red fly, gold sphere."""
    img = new_canvas(rgb("DA291C"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, SIZE * 0.40, SIZE), fill=rgb("046A38"))
    cx, cy = SIZE * 0.40, SIZE / 2
    r = SIZE * 0.17
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgb("F1B517"))
    inner = r * 0.58
    d.ellipse((cx - inner, cy - inner, cx + inner, cy + inner), fill=rgb("DA291C"))
    ring = r * 0.78
    d.ellipse((cx - ring, cy - ring, cx + ring, cy + ring), outline=rgb("FFFFFF"), width=10)
    return gloss(img, 24)


def bg_spanish() -> Image.Image:
    img = new_canvas(rgb("C60B1E"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, SIZE * 0.25, SIZE, SIZE * 0.75), fill=rgb("FFC400"))
    return gloss(img, 28)


def bg_french() -> Image.Image:
    img = new_canvas(rgb("FFFFFF"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, SIZE / 3, SIZE), fill=rgb("002395"))
    d.rectangle((SIZE * 2 / 3, 0, SIZE, SIZE), fill=rgb("ED2939"))
    return gloss(img, 24)


def bg_german() -> Image.Image:
    img = new_canvas(rgb("000000"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, SIZE / 3, SIZE, SIZE * 2 / 3), fill=rgb("DD0000"))
    d.rectangle((0, SIZE * 2 / 3, SIZE, SIZE), fill=rgb("FFCE00"))
    return gloss(img, 20)


def bg_japanese() -> Image.Image:
    img = new_canvas(rgb("F7F7F7"))
    d = ImageDraw.Draw(img)
    r = SIZE * 0.28
    cx = cy = SIZE / 2
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgb("BC002D"))
    return gloss(img, 30)


def bg_chinese() -> Image.Image:
    img = new_canvas(rgb("DE2910"))
    d = ImageDraw.Draw(img)
    draw_stars(d, SIZE * 0.18, SIZE * 0.22, 90, rgb("FFDE00"), 5)
    for ang, dist in [(0, 0.18), (36, 0.16), (72, 0.16), (108, 0.18)]:
        a = math.radians(-40 + ang)
        x = SIZE * 0.18 + SIZE * dist * math.cos(a)
        y = SIZE * 0.22 + SIZE * dist * math.sin(a)
        draw_stars(d, x, y, 28, rgb("FFDE00"), 5)
    return gloss(img, 22)


def bg_korean() -> Image.Image:
    img = new_canvas(rgb("F5F5F5"))
    d = ImageDraw.Draw(img)
    cx = cy = SIZE / 2
    r = SIZE * 0.16
    # Taegeuk
    d.pieslice((cx - r, cy - r, cx + r, cy + r), 180, 360, fill=rgb("CD2E3A"))
    d.pieslice((cx - r, cy - r, cx + r, cy + r), 0, 180, fill=rgb("0047A0"))
    d.ellipse((cx - r / 2, cy - r, cx + r / 2, cy), fill=rgb("CD2E3A"))
    d.ellipse((cx - r / 2, cy, cx + r / 2, cy + r), fill=rgb("0047A0"))
    # Simplified trigrams
    def trigram(px, py, rot, bars):
        layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        w, h, gap = 150, 18, 14
        for i, full in enumerate(bars):
            yy = py - 28 + i * (h + gap)
            if full:
                ld.rectangle((px - w / 2, yy, px + w / 2, yy + h), fill=(20, 20, 20, 255))
            else:
                ld.rectangle((px - w / 2, yy, px - 10, yy + h), fill=(20, 20, 20, 255))
                ld.rectangle((px + 10, yy, px + w / 2, yy + h), fill=(20, 20, 20, 255))
        return layer.rotate(rot, center=(px, py), resample=Image.Resampling.BICUBIC)

    img = Image.alpha_composite(img, trigram(SIZE * 0.22, SIZE * 0.22, 45, [1, 1, 1]))
    img = Image.alpha_composite(img, trigram(SIZE * 0.78, SIZE * 0.22, -45, [0, 0, 0]))
    img = Image.alpha_composite(img, trigram(SIZE * 0.22, SIZE * 0.78, -45, [0, 1, 0]))
    img = Image.alpha_composite(img, trigram(SIZE * 0.78, SIZE * 0.78, 45, [1, 0, 1]))
    return gloss(img, 26)


def compose(bg: Image.Image, quote, shadow=True) -> Image.Image:
    img = bg.convert("RGBA")
    if shadow:
        sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sh.paste((0, 0, 0, 90), (0, 0), QUOTE_MASK)
        sh = sh.filter(ImageFilter.GaussianBlur(14))
        img = Image.alpha_composite(img, sh)
    return paste_quotes(img, quote)


def save(name: str, img: Image.Image) -> None:
    rgb_img = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
    rgb_img.paste(img.convert("RGBA"), mask=img.split()[-1] if img.mode == "RGBA" else None)
    # flatten
    flat = img.convert("RGB")
    dest = ROOT / f"{name}.png"
    flat.save(dest, "PNG", optimize=True)
    flat.resize((120, 120), Image.Resampling.LANCZOS).save(ROOT / f"{name}@2x.png", "PNG", optimize=True)
    flat.resize((180, 180), Image.Resampling.LANCZOS).save(ROOT / f"{name}@3x.png", "PNG", optimize=True)
    print("wrote", name)


def write_primary(light: Image.Image, dark: Image.Image, tinted: Image.Image) -> None:
    APPICONSET.mkdir(parents=True, exist_ok=True)
    light.convert("RGB").save(APPICONSET / "AppIcon-Any-Appearance.png", "PNG", optimize=True)
    dark.convert("RGB").save(APPICONSET / "AppIcon-Dark.png", "PNG", optimize=True)
    tinted.convert("RGB").save(APPICONSET / "AppIcon-Tinted.png", "PNG", optimize=True)
    print("wrote AppIcon.appiconset")


def main() -> None:
    for stale in ROOT.glob("AppIconEmber*"):
        stale.unlink()

    classic = compose(bg_classic(), rgb("1C1C1E"))
    classic_dark = compose(bg_classic_dark(), rgb("F4F4F8"))
    classic_tinted = compose(new_canvas(rgb("000000")), rgb("FFFFFF"), shadow=False)
    save("AppIconClassic", classic)
    write_primary(classic, classic_dark, classic_tinted)

    save("AppIconNight", compose(bg_night(), rgb("F4F4F8")))
    save("AppIconGrain", compose(bg_grain(), rgb("F7F7F5")))
    save("AppIconNeon", compose(bg_neon(), rainbow_fill(), shadow=False))
    save("AppIconAurora", compose(bg_aurora(), rgb("FFFFFF")))
    save("AppIconSun", compose(bg_sun(), rgb("FFFFFF")))
    save("AppIconOcean", compose(bg_ocean(), rgb("F4FFFD")))
    save("AppIconForest", compose(bg_forest(), rgb("E8F8E4")))

    save("AppIconEnglish", compose(bg_english(), rgb("FFFFFF")))
    save("AppIconSpanish", compose(bg_spanish(), rgb("1A1A1A")))
    save("AppIconFrench", compose(bg_french(), rgb("1A1A1A")))
    save("AppIconGerman", compose(bg_german(), rgb("FFFFFF")))
    save("AppIconJapanese", compose(bg_japanese(), rgb("1C1C1E")))
    save("AppIconChinese", compose(bg_chinese(), rgb("FFFFFF")))
    save("AppIconKorean", compose(bg_korean(), rgb("1C1C1E")))
    save("AppIconPortuguese", compose(bg_portuguese(), rgb("FFFFFF")))


if __name__ == "__main__":
    main()
