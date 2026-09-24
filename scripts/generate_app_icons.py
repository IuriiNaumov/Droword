#!/usr/bin/env python3
"""Generate Droword alternate app icons (1024 / @2x 120 / @3x 180).

2025–26 trends: light→dark depth, soft liquid orbs, top specular rim,
sharp quote mark on top (no heavy glass blur over the glyph).
"""

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

    mask = src.point(lambda p: 255 if p < 140 else 0)
    mask.save(MASK_PATH)
    return mask


QUOTE_MASK = load_quote_mask()


def rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def new_canvas(color: tuple[int, int, int]) -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (*color, 255))


def vertical_gradient(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> Image.Image:
    strip = Image.new("RGB", (1, SIZE))
    px = strip.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        px[0, y] = (
            int(c1[0] + (c2[0] - c1[0]) * t),
            int(c1[1] + (c2[1] - c1[1]) * t),
            int(c1[2] + (c2[2] - c1[2]) * t),
        )
    return strip.resize((SIZE, SIZE), Image.Resampling.BILINEAR).convert("RGBA")


def linear_gradient(
    c1: tuple[int, int, int], c2: tuple[int, int, int], angle: float
) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    rad = math.radians(angle)
    dx, dy = math.cos(rad), math.sin(rad)
    corners = [(0, 0), (SIZE - 1, 0), (0, SIZE - 1), (SIZE - 1, SIZE - 1)]
    projs = [x * dx + y * dy for x, y in corners]
    min_p, max_p = min(projs), max(projs)
    span = max_p - min_p or 1
    for y in range(SIZE):
        for x in range(SIZE):
            t = ((x * dx + y * dy) - min_p) / span
            px[x, y] = (
                int(c1[0] + (c2[0] - c1[0]) * t),
                int(c1[1] + (c2[1] - c1[1]) * t),
                int(c1[2] + (c2[2] - c1[2]) * t),
                255,
            )
    return img


def radial_gradient(
    inner: tuple[int, int, int], outer: tuple[int, int, int], cx=0.5, cy=0.38
) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    ox, oy = cx * SIZE, cy * SIZE
    max_d = math.hypot(SIZE, SIZE) * 0.72
    for y in range(SIZE):
        for x in range(SIZE):
            t = min(1.0, math.hypot(x - ox, y - oy) / max_d)
            t = t * t * (3 - 2 * t)
            px[x, y] = (
                int(inner[0] + (outer[0] - inner[0]) * t),
                int(inner[1] + (outer[1] - inner[1]) * t),
                int(inner[2] + (outer[2] - inner[2]) * t),
                255,
            )
    return img


def soft_orb(
    img: Image.Image,
    color: tuple[int, int, int],
    box: tuple[float, float, float, float],
    alpha: int = 140,
    blur: int = 90,
) -> Image.Image:
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=(*color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(img, layer)


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


def gloss(img: Image.Image, strength: int = 42) -> Image.Image:
    """Top specular — Liquid Glass style rim, not a wash over the whole icon."""
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-SIZE * 0.15, -SIZE * 0.78, SIZE * 1.15, SIZE * 0.42), fill=(255, 255, 255, strength))
    overlay = overlay.filter(ImageFilter.GaussianBlur(70))
    out = Image.alpha_composite(img, overlay)

    rim = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.rectangle((0, 0, SIZE, int(SIZE * 0.08)), fill=(255, 255, 255, 28))
    rd.rectangle((0, int(SIZE * 0.92), SIZE, SIZE), fill=(255, 255, 255, 14))
    rim = rim.filter(ImageFilter.GaussianBlur(18))
    return Image.alpha_composite(out, rim)


def vignette(img: Image.Image, amount: int = 70) -> Image.Image:
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = overlay.load()
    cx = cy = SIZE / 2
    max_d = math.hypot(cx, cy)
    for y in range(SIZE):
        for x in range(SIZE):
            t = math.hypot(x - cx, y - cy) / max_d
            a = int(max(0, (t - 0.42) / 0.58) ** 1.7 * amount)
            px[x, y] = (0, 0, 0, a)
    return Image.alpha_composite(img, overlay)


def grain(img: Image.Image, amount: float = 16, seed: int = 1) -> Image.Image:
    noise = Image.effect_noise((SIZE, SIZE), amount).convert("L")
    noise = Image.merge("RGBA", (noise, noise, noise, Image.new("L", (SIZE, SIZE), 36)))
    return ImageChops.overlay(img.convert("RGBA"), noise)


def horizontal_stripes(colors: list[tuple[int, int, int]]) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE))
    d = ImageDraw.Draw(img)
    n = len(colors)
    h = SIZE / n
    for i, col in enumerate(colors):
        y0 = int(i * h)
        y1 = int((i + 1) * h) if i < n - 1 else SIZE
        d.rectangle((0, y0, SIZE, y1), fill=(*col, 255))
    return img


def soft_stripes(colors: list[tuple[int, int, int]], blur: int = 2) -> Image.Image:
    return horizontal_stripes(colors).filter(ImageFilter.GaussianBlur(blur))


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
    return img.filter(ImageFilter.GaussianBlur(1.6))


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


def draw_stars(d: ImageDraw.ImageDraw, cx, cy, r, color, n=5):
    pts = []
    for i in range(n * 2):
        ang = math.radians(-90 + i * 180 / n)
        rad = r if i % 2 == 0 else r * 0.4
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=color)


# --- trendy backgrounds -------------------------------------------------

def bg_classic() -> Image.Image:
    img = radial_gradient(rgb("FFFFFF"), rgb("D8E2F0"), 0.48, 0.32)
    img = soft_orb(img, rgb("A8C4F0"), (-120, -180, 620, 560), 90, 100)
    img = soft_orb(img, rgb("E8D4F5"), (420, 500, 1180, 1180), 70, 110)
    return gloss(img, 34)


def bg_classic_dark() -> Image.Image:
    img = radial_gradient(rgb("3A3A42"), rgb("0C0C10"), 0.42, 0.28)
    img = soft_orb(img, rgb("5B7CDE"), (-80, -120, 520, 480), 70, 100)
    return gloss(vignette(img, 55), 28)


def bg_night() -> Image.Image:
    img = vertical_gradient(rgb("1E1830"), rgb("050508"))
    img = soft_orb(img, rgb("7C5CFF"), (-160, -100, 640, 640), 130, 95)
    img = soft_orb(img, rgb("FF5AC8"), (380, 420, 1200, 1180), 90, 110)
    img = soft_orb(img, rgb("3B82F6"), (200, -40, 900, 520), 70, 90)
    specks = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sp = specks.load()
    rng = random.Random(3)
    for _ in range(260):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        sp[x, y] = (255, 255, 255, rng.randint(50, 180))
    specks = specks.filter(ImageFilter.GaussianBlur(0.7))
    return gloss(vignette(Image.alpha_composite(img, specks), 70), 32)


def bg_grain() -> Image.Image:
    img = vertical_gradient(rgb("4A4640"), rgb("1A1816"))
    img = soft_orb(img, rgb("8A7E6A"), (100, -80, 800, 520), 60, 100)
    img = grain(img, 22, seed=11)
    return gloss(img, 24)


def bg_neon() -> Image.Image:
    img = vertical_gradient(rgb("0A0A14"), rgb("04040A"))
    img = soft_orb(img, rgb("FF2D74"), (-200, 40, 700, 700), 110, 85)
    img = soft_orb(img, rgb("22D3EE"), (360, -80, 1200, 620), 100, 90)
    img = soft_orb(img, rgb("A855F7"), (120, 480, 980, 1200), 90, 95)
    grid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    for i in range(0, SIZE, 72):
        g.line((i, 0, i, SIZE), fill=(255, 255, 255, 10), width=1)
        g.line((0, i, SIZE, i), fill=(255, 255, 255, 10), width=1)
    return gloss(Image.alpha_composite(img, grid), 22)


def bg_aurora() -> Image.Image:
    img = vertical_gradient(rgb("14082E"), rgb("060412"))
    img = soft_orb(img, rgb("8B5CF6"), (-200, 40, 720, 720), 160, 95)
    img = soft_orb(img, rgb("2563EB"), (380, -140, 1220, 640), 140, 100)
    img = soft_orb(img, rgb("EC4899"), (60, 420, 980, 1220), 130, 100)
    img = soft_orb(img, rgb("22D3EE"), (-40, 560, 560, 1180), 100, 90)
    return gloss(vignette(img, 40), 40)


def bg_sun() -> Image.Image:
    img = radial_gradient(rgb("FFE08A"), rgb("E11D48"), 0.5, 0.36)
    img = soft_orb(img, rgb("FFB020"), (-60, -120, 700, 560), 120, 80)
    img = soft_orb(img, rgb("F97316"), (280, 360, 1180, 1180), 110, 100)
    img = soft_orb(img, rgb("DB2777"), (100, 620, 900, 1280), 90, 90)
    return gloss(img, 36)


def bg_ocean() -> Image.Image:
    img = vertical_gradient(rgb("5EEAD4"), rgb("0F3D4A"))
    img = soft_orb(img, rgb("99F6E4"), (-100, -160, 720, 520), 120, 90)
    img = soft_orb(img, rgb("0EA5A4"), (300, 480, 1200, 1200), 100, 100)
    waves = wavy_bands(
        [rgb("0B3D4A"), rgb("14B8A6"), rgb("5EEAD4"), rgb("99F6E4"), rgb("14B8A6")],
        amp=48,
        freq=2.6,
    )
    img = Image.blend(img, waves, 0.35)
    return gloss(vignette(img, 35), 34)


def bg_forest() -> Image.Image:
    img = vertical_gradient(rgb("4ADE80"), rgb("14532D"))
    img = soft_orb(img, rgb("86EFAC"), (-80, -120, 680, 520), 110, 90)
    img = soft_orb(img, rgb("166534"), (260, 500, 1180, 1220), 100, 100)
    d = ImageDraw.Draw(img)
    rng = random.Random(5)
    for _ in range(12):
        x = rng.randint(-60, SIZE)
        w = rng.randint(100, 240)
        h = rng.randint(360, 820)
        y = SIZE - h + 60
        col = (rng.randint(20, 55), rng.randint(100, 160), rng.randint(50, 90), 55)
        d.ellipse((x, y, x + w, y + h), fill=col)
    img = img.filter(ImageFilter.GaussianBlur(6))
    return gloss(grain(img, 8, seed=4), 26)


def bg_glass() -> Image.Image:
    """Extra trendy liquid-glass wash."""
    img = vertical_gradient(rgb("F0F7FF"), rgb("9BB8E8"))
    img = soft_orb(img, rgb("FFFFFF"), (-100, -200, 700, 480), 160, 80)
    img = soft_orb(img, rgb("7DD3FC"), (300, 400, 1200, 1200), 100, 100)
    img = soft_orb(img, rgb("C4B5FD"), (-40, 560, 560, 1200), 80, 90)
    return gloss(img, 48)


# --- pride ---------------------------------------------------------------

def bg_pride() -> Image.Image:
    img = soft_stripes(
        [
            rgb("E40303"),
            rgb("FF8C00"),
            rgb("FFED00"),
            rgb("008026"),
            rgb("24408E"),
            rgb("732982"),
        ],
        blur=1,
    )
    return gloss(img, 30)


# --- language flags (kept recognizable, soft finish) ---------------------

def bg_english() -> Image.Image:
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
    return gloss(img, 26)


def bg_portuguese() -> Image.Image:
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
    return gloss(img, 26)


def bg_spanish() -> Image.Image:
    img = new_canvas(rgb("C60B1E"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, SIZE * 0.25, SIZE, SIZE * 0.75), fill=rgb("FFC400"))
    return gloss(img, 30)


def bg_french() -> Image.Image:
    img = new_canvas(rgb("FFFFFF"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, SIZE / 3, SIZE), fill=rgb("002395"))
    d.rectangle((SIZE * 2 / 3, 0, SIZE, SIZE), fill=rgb("ED2939"))
    return gloss(img, 26)


def bg_german() -> Image.Image:
    img = new_canvas(rgb("000000"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, SIZE / 3, SIZE, SIZE * 2 / 3), fill=rgb("DD0000"))
    d.rectangle((0, SIZE * 2 / 3, SIZE, SIZE), fill=rgb("FFCE00"))
    return gloss(img, 22)


def bg_japanese() -> Image.Image:
    img = radial_gradient(rgb("FFFFFF"), rgb("F0F0F0"), 0.5, 0.4)
    d = ImageDraw.Draw(img)
    r = SIZE * 0.28
    cx = cy = SIZE / 2
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgb("BC002D"))
    return gloss(img, 32)


def bg_chinese() -> Image.Image:
    img = vertical_gradient(rgb("FF3B2F"), rgb("B91C1C"))
    d = ImageDraw.Draw(img)
    draw_stars(d, SIZE * 0.18, SIZE * 0.22, 90, rgb("FFDE00"), 5)
    for ang, dist in [(0, 0.18), (36, 0.16), (72, 0.16), (108, 0.18)]:
        a = math.radians(-40 + ang)
        x = SIZE * 0.18 + SIZE * dist * math.cos(a)
        y = SIZE * 0.22 + SIZE * dist * math.sin(a)
        draw_stars(d, x, y, 28, rgb("FFDE00"), 5)
    return gloss(img, 24)


def bg_korean() -> Image.Image:
    img = radial_gradient(rgb("FFFFFF"), rgb("F2F2F2"), 0.5, 0.4)
    d = ImageDraw.Draw(img)
    cx = cy = SIZE / 2
    r = SIZE * 0.16

    d.pieslice((cx - r, cy - r, cx + r, cy + r), 180, 360, fill=rgb("CD2E3A"))
    d.pieslice((cx - r, cy - r, cx + r, cy + r), 0, 180, fill=rgb("0047A0"))
    d.ellipse((cx - r / 2, cy - r, cx + r / 2, cy), fill=rgb("CD2E3A"))
    d.ellipse((cx - r / 2, cy, cx + r / 2, cy + r), fill=rgb("0047A0"))

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
    return gloss(img, 28)


def compose(bg: Image.Image, quote, shadow=True) -> Image.Image:
    img = bg.convert("RGBA")
    if shadow:
        sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sh.paste((0, 0, 0, 70), (0, 0), QUOTE_MASK)
        sh = sh.filter(ImageFilter.GaussianBlur(12))
        offset = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        offset.paste(sh, (0, 8))
        img = Image.alpha_composite(img, offset)
    return paste_quotes(img, quote)


def save(name: str, img: Image.Image) -> None:
    flat = img.convert("RGB")
    ROOT.mkdir(parents=True, exist_ok=True)
    flat.save(ROOT / f"{name}.png", "PNG", optimize=True)
    flat.resize((120, 120), Image.Resampling.LANCZOS).save(
        ROOT / f"{name}@2x.png", "PNG", optimize=True
    )
    flat.resize((180, 180), Image.Resampling.LANCZOS).save(
        ROOT / f"{name}@3x.png", "PNG", optimize=True
    )
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

    save("AppIconNight", compose(bg_night(), rgb("F8F7FF")))
    save("AppIconGrain", compose(bg_grain(), rgb("F7F7F5")))
    save("AppIconNeon", compose(bg_neon(), rainbow_fill(), shadow=False))
    save("AppIconAurora", compose(bg_aurora(), rgb("FFFFFF")))
    save("AppIconSun", compose(bg_sun(), rgb("FFFFFF")))
    save("AppIconOcean", compose(bg_ocean(), rgb("F4FFFD")))
    save("AppIconForest", compose(bg_forest(), rgb("F0FFF0")))
    save("AppIconGlass", compose(bg_glass(), rgb("1C3A5F")))

    save("AppIconPride", compose(bg_pride(), rgb("FFFFFF")))

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
