#!/usr/bin/env python3
"""Compose App Store posters: text top + real screenshot in device frame.

Drop portrait screenshots into marketing/app-store/raw/:
  01-home.png, 02-dictionary.png, 03-practice.png, 04-ai-card.png, 05-themes.png

Then:
  python3 marketing/app-store/compose.py
  python3 marketing/app-store/compose.py --lang ru
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OUT = ROOT / "out"

W, H = 1290, 2796

FRAMES = [
    {
        "id": "01",
        "raw": "01-home.png",
        "en": "Words that stick",
        "ru": "Слова, которые\nостаются",
        "bg": (232, 240, 236),
        "fg": (17, 17, 17),
        "logo": (17, 17, 17),
    },
    {
        "id": "02",
        "raw": "02-dictionary.png",
        "en": "Build your\ndictionary",
        "ru": "Свой словарь",
        "bg": (59, 130, 246),
        "fg": (255, 255, 255),
        "logo": (255, 255, 255),
    },
    {
        "id": "03",
        "raw": "03-practice.png",
        "en": "Smart spaced\nreviews",
        "ru": "Умные\nповторения",
        "bg": (52, 199, 89),
        "fg": (255, 255, 255),
        "logo": (255, 255, 255),
    },
    {
        "id": "04",
        "raw": "04-ai-card.png",
        "en": "AI fills\nthe card",
        "ru": "ИИ собирает\nкарточку",
        "bg": (18, 18, 20),
        "fg": (255, 255, 255),
        "logo": (255, 255, 255),
    },
    {
        "id": "05",
        "raw": "05-themes.png",
        "en": "Make it yours",
        "ru": "Под себя",
        "bg": (255, 214, 186),
        "fg": (17, 17, 17),
        "logo": (17, 17, 17),
    },
]

def load_font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica Neue Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()

def draw_quote_mark(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int], scale: float = 1.0) -> None:
    font = load_font(int(72 * scale), bold=True)
    draw.text((x, y), "“", font=font, fill=color)

def fit_cover(img: Image.Image, tw: int, th: int) -> Image.Image:
    scale = max(tw / img.width, th / img.height)
    nw, nh = int(img.width * scale), int(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))

def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask

def compose_frame(frame: dict, lang: str, screenshot: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (W, H), frame["bg"])
    draw = ImageDraw.Draw(canvas)

    draw_quote_mark(draw, 72, 64, frame["logo"], scale=1.0)

    headline = frame[lang]
    font = load_font(118, bold=True)

    bbox = draw.multiline_textbbox((0, 0), headline, font=font, align="center", spacing=12)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    hx = (W - tw) // 2
    hy = 220
    draw.multiline_text((hx, hy), headline, font=font, fill=frame["fg"], align="center", spacing=12)


    bezel = 18
    radius = 90
    phone_w = 980
    phone_h = 2000
    phone_x = (W - phone_w) // 2
    phone_y = H - phone_h - 80


    draw.rounded_rectangle(
        (phone_x, phone_y, phone_x + phone_w, phone_y + phone_h),
        radius=radius,
        fill=(10, 10, 12),
    )

    screen_box = (
        phone_x + bezel,
        phone_y + bezel,
        phone_x + phone_w - bezel,
        phone_y + phone_h - bezel,
    )
    sw = screen_box[2] - screen_box[0]
    sh = screen_box[3] - screen_box[1]
    screen = fit_cover(screenshot.convert("RGB"), sw, sh)
    mask = rounded_mask((sw, sh), radius - bezel)
    canvas.paste(screen, (screen_box[0], screen_box[1]), mask)


    return canvas

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", choices=("en", "ru"), default="en")
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    missing = []

    for frame in FRAMES:
        path = RAW / frame["raw"]
        if not path.exists():
            missing.append(path.name)
            continue
        shot = Image.open(path)
        out = compose_frame(frame, args.lang, shot)
        name = f"poster-{frame['id']}-{args.lang}.png"
        out.save(OUT / name, optimize=True)
        print(f"wrote {OUT / name}")

    if missing:
        print("Missing screenshots in raw/:")
        for name in missing:
            print(f"  - {name}")
        print("Capture from Simulator/device, drop into marketing/app-store/raw/, re-run.")
        raise SystemExit(1)

if __name__ == "__main__":
    main()
