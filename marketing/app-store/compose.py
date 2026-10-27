#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
STICKERS = RAW / "stickers"
OUT = ROOT / "out"
FONTS = ROOT.parent.parent / "Droword" / "Fonts"

W, H = 1320, 2868
GOLD = (255, 205, 64)
INK = (36, 26, 74)
WHITE = (255, 255, 255)

FRAMES = [
    {
        "id": "01",
        "bg": (84, 82, 230),
        "glow": (140, 120, 255),
        "en": ["Words that", "actually *stick*"],
        "ru": ["Слова, которые", "*остаются*"],
        "phone": {"shot": "home.png", "y": 880, "angle": 0},
        "stickers": [("star.png", 150, 1010, 250, -12), ("sparkles.png", 1110, 1480, 230, 8), ("heart.png", 120, 2350, 190, -8)],
    },
    {
        "id": "02",
        "bg": (232, 69, 122),
        "glow": (255, 128, 168),
        "en": ["*5 minutes.*", "One lesson.", "Every day."],
        "ru": ["*5 минут.*", "Один урок.", "Каждый день."],
        "phone": {"shot": "lesson.png", "y": 900, "angle": 0},
        "stickers": [("bulb.png", 1110, 1080, 250, 10), ("check.png", 150, 1830, 230, -10)],
    },
    {
        "id": "03",
        "bg": (46, 107, 242),
        "glow": (110, 160, 255),
        "en": ["AI fills", "*the whole card*"],
        "ru": ["ИИ заполнит", "*всю карточку*"],
        "phone": {"shot": "dictionary.png", "y": 880, "angle": 0},
        "callout": {"shot": "dictionary.png", "crop": (72, 920, 1134, 1760), "patch": (900, 0, 1062, 90), "width": 1120, "y": 1520, "angle": -3},
        "stickers": [("book.png", 1120, 960, 240, 10), ("star.png", 140, 1350, 180, -14)],
    },
    {
        "id": "04",
        "bg": (255, 184, 46),
        "glow": (255, 222, 120),
        "fg": INK,
        "accent": (124, 79, 214),
        "en": ["Snap a page.", "*Keep the words.*"],
        "ru": ["Сфоткай страницу —", "*слова в словаре*"],
        "phone": {"shot": "scan.png", "y": 880, "angle": 0},
        "stickers": [("tag.png", 150, 1150, 240, -10), ("sparkles.png", 1120, 1700, 230, 10)],
    },
    {
        "id": "05",
        "bg": (45, 180, 106),
        "glow": (120, 220, 150),
        "en": ["Practice that", "*feels like a game*"],
        "ru": ["Практика,", "*как игра*"],
        "phone": {"shot": "practice.png", "y": 880, "angle": 0},
        "stickers": [("trophy.png", 1110, 1040, 260, 10), ("target.png", 150, 1760, 230, -8), ("heart.png", 1130, 2300, 180, 12)],
    },
    {
        "id": "06",
        "bg": (30, 26, 60),
        "glow": (90, 70, 170),
        "en": ["Make it", "*yours*"],
        "ru": ["Сделай", "*под себя*"],
        "fan": [("home-duolingo.png", -400, 1060, -7), ("home-pixel.png", 400, 1060, 7), ("home-glass.png", 0, 900, 0)],
        "stickers": [("star-pixel.png", 1130, 760, 200, 8), ("star-duo.png", 170, 790, 190, -10), ("star-glass.png", 1150, 2560, 200, 10)],
    },
]


def font(size: int, cyrillic: bool = False) -> ImageFont.FreeTypeFont:
    paths = [Path("/Library/Fonts/SF-Compact-Display-Black.otf"), Path("/System/Library/Fonts/Supplemental/Arial Black.ttf")] if cyrillic else [FONTS / "Poppins-Black.ttf"]
    for path in paths:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def background(frame: dict) -> Image.Image:
    canvas = Image.new("RGB", (W, H), frame["bg"])
    glow = Image.new("RGB", (W, H), frame["glow"])
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse((-420, -900, W + 420, 1500), fill=150)
    mask = mask.filter(ImageFilter.GaussianBlur(260))
    canvas.paste(glow, (0, 0), mask)
    return canvas


def draw_headline(canvas: Image.Image, lines: list[str], frame: dict) -> None:
    draw = ImageDraw.Draw(canvas)
    fg = frame.get("fg", WHITE)
    accent = frame.get("accent", GOLD)
    size = 172
    cyrillic = any(ord(ch) > 127 for line in lines for ch in line)
    f = font(size, cyrillic)
    while size > 96 and max(draw.textlength(line.replace("*", ""), font=f) for line in lines) > W - 200:
        size -= 4
        f = font(size, cyrillic)
    line_h = int(size * 1.08)
    y = 190
    for line in lines:
        parts = line.split("*")
        segments = [(text, accent if i % 2 else fg) for i, text in enumerate(parts) if text]
        total = sum(draw.textlength(text, font=f) for text, _ in segments)
        x = (W - total) / 2
        for text, color in segments:
            draw.text((x, y), text, font=f, fill=color)
            x += draw.textlength(text, font=f)
        y += line_h


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width, img.height), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def phone(shot: Image.Image, width: int) -> Image.Image:
    bezel = int(width * 0.026)
    screen_w = width - bezel * 2
    screen = shot.convert("RGB").resize((screen_w, int(shot.height * screen_w / shot.width)), Image.Resampling.LANCZOS)
    height = screen.height + bezel * 2
    radius = int(width * 0.15)
    body = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((0, 0, width, height), radius=radius, fill=(16, 16, 20, 255))
    ImageDraw.Draw(body).rounded_rectangle((3, 3, width - 3, height - 3), radius=radius - 3, outline=(70, 70, 80, 255), width=3)
    body.alpha_composite(rounded(screen, radius - bezel), (bezel, bezel))
    island_w, island_h = int(width * 0.3), int(width * 0.085)
    ImageDraw.Draw(body).rounded_rectangle(
        ((width - island_w) // 2, bezel + int(width * 0.03), (width + island_w) // 2, bezel + int(width * 0.03) + island_h),
        radius=island_h // 2,
        fill=(0, 0, 0, 255),
    )
    return body


def paste_with_shadow(canvas: Image.Image, layer: Image.Image, center_x: int, top: int, angle: float, shadow: int = 70) -> None:
    if angle:
        layer = layer.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    x = center_x - layer.width // 2
    pad = 120
    alpha = layer.split()[3]
    sh = Image.new("RGBA", (layer.width + pad * 2, layer.height + pad * 2), (0, 0, 0, 0))
    sh_alpha = Image.new("L", sh.size, 0)
    sh_alpha.paste(alpha.point(lambda a: a * shadow // 255), (pad, pad))
    sh.putalpha(sh_alpha.filter(ImageFilter.GaussianBlur(48)))
    base = canvas.convert("RGBA")
    _composite(base, sh, x - pad, top - pad + 40)
    _composite(base, layer, x, top)
    canvas.paste(base.convert("RGB"))


def _composite(base: Image.Image, layer: Image.Image, x: int, y: int) -> None:
    box = (max(0, x), max(0, y), min(base.width, x + layer.width), min(base.height, y + layer.height))
    if box[0] >= box[2] or box[1] >= box[3]:
        return
    crop = layer.crop((box[0] - x, box[1] - y, box[2] - x, box[3] - y))
    base.alpha_composite(crop, (box[0], box[1]))


def sticker(canvas: Image.Image, name: str, cx: int, cy: int, size: int, angle: float) -> None:
    path = STICKERS / name
    if not path.exists():
        return
    img = Image.open(path).convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    scale = size / max(img.width, img.height)
    img = img.resize((int(img.width * scale), int(img.height * scale)), Image.Resampling.LANCZOS)
    paste_with_shadow(canvas, img, cx, cy - img.height // 2, angle, shadow=60)


def callout(canvas: Image.Image, spec: dict, lang: str) -> None:
    shot = Image.open(RAW / lang / spec["shot"]).convert("RGB")
    card = shot.crop(spec["crop"])
    if "patch" in spec:
        ImageDraw.Draw(card).rectangle(spec["patch"], fill=WHITE)
    w = spec["width"]
    card = card.resize((w, int(card.height * w / card.width)), Image.Resampling.LANCZOS)
    paste_with_shadow(canvas, rounded(card, 64), W // 2, spec["y"], spec["angle"], shadow=110)


def compose(frame: dict, lang: str) -> Image.Image | None:
    canvas = background(frame)
    draw_headline(canvas, frame[lang], frame)
    folder = RAW / lang
    if "fan" in frame:
        for shot_name, dx, top, angle in frame["fan"]:
            path = folder / shot_name
            if not path.exists():
                return None
            paste_with_shadow(canvas, phone(Image.open(path), 580), W // 2 + dx, top, angle)
    else:
        spec = frame["phone"]
        path = folder / spec["shot"]
        if not path.exists():
            return None
        paste_with_shadow(canvas, phone(Image.open(path), 1000), W // 2, spec["y"], spec["angle"])
    if "callout" in frame:
        callout(canvas, frame["callout"], lang)
    for name, cx, cy, size, angle in frame["stickers"]:
        sticker(canvas, name, cx, cy, size, angle)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", choices=("en", "ru"), default="en")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    missing = []
    for frame in FRAMES:
        image = compose(frame, args.lang)
        if image is None:
            missing.append(frame["id"])
            continue
        path = OUT / f"poster-{frame['id']}-{args.lang}.png"
        image.save(path, optimize=True)
        print(f"wrote {path}")
    if missing:
        print(f"Missing screenshots in raw/{args.lang}/ for: {', '.join(missing)}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
