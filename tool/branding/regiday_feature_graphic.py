#!/usr/bin/env python3
"""Generate the Google Play feature graphic (1024x500 PNG) for Regiday.

Run from the repo root with the branding venv (see design/branding/regiday/README.md):

    build/branding-venv/bin/python tool/branding/regiday_feature_graphic.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
W, H = 1024, 500

INDIGO = (0x4E, 0x46, 0xE5)
DEEP_INDIGO = (0x33, 0x2B, 0x99)
IVORY = (0xFF, 0xFD, 0xF8)

ICON = ROOT / "design/branding/regiday/exports/regiday_play_listing_512.png"
PHONE_A = ROOT / "screenshots/paper_wallet/documents_wallet.png"
PHONE_B = ROOT / "screenshots/paper_wallet/subscriptions_calendar.png"
FONT_BOLD = ROOT / "assets/fonts/Lora-Bold.ttf"
FONT_SEMI = ROOT / "assets/fonts/Lora-SemiBold.ttf"
OUT = ROOT / "design/branding/regiday/exports/regiday_play_feature_graphic_1024x500.png"


def gradient_background() -> Image.Image:
    """Diagonal indigo gradient matching the app icon."""
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x / (W - 1) + y / (H - 1)) / 2
            px[x, y] = tuple(
                round(INDIGO[i] + (DEEP_INDIGO[i] - INDIGO[i]) * t) for i in range(3)
            )
    return img


def rounded_phone(path: Path, height: int, radius: int = 34) -> Image.Image:
    """Screenshot scaled to height, with rounded corners and a soft shadow."""
    shot = Image.open(path).convert("RGBA")
    width = round(shot.width * height / shot.height)
    shot = shot.resize((width, height), Image.LANCZOS)
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius, fill=255)
    shot.putalpha(mask)
    return shot


def paste_with_shadow(base: Image.Image, img: Image.Image, xy: tuple[int, int]) -> None:
    shadow = Image.new("RGBA", (img.width + 80, img.height + 80), (0, 0, 0, 0))
    alpha = Image.new("L", img.size, 150)
    shadow.paste((10, 8, 40, 0), (40, 52), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    base.alpha_composite(shadow, (xy[0] - 40, xy[1] - 40))
    base.alpha_composite(img, xy)


def main() -> None:
    base = gradient_background().convert("RGBA")

    # Faint concentric arcs on the right, echoing the app's document backdrop.
    arcs = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(arcs)
    cx, cy = 880, 260
    for r in range(120, 620, 60):
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 253, 248, 30), width=2)
    base.alpha_composite(arcs)

    # Two phones on the right.
    phone_a = rounded_phone(PHONE_A, 380)
    phone_b = rounded_phone(PHONE_B, 380)
    paste_with_shadow(base, phone_b, (812, 120))
    paste_with_shadow(base, phone_a, (608, 60))

    # Left column: icon, wordmark, tagline.
    icon = Image.open(ICON).convert("RGBA").resize((120, 120), Image.LANCZOS)
    base.alpha_composite(icon, (80, 96))

    draw = ImageDraw.Draw(base)
    f_title = ImageFont.truetype(str(FONT_BOLD), 112)
    f_tag = ImageFont.truetype(str(FONT_SEMI), 36)
    draw.text((78, 236), "Regiday", font=f_title, fill=IVORY)
    draw.text((82, 370), "Your papers. Your dates.", font=f_tag, fill=(255, 253, 248, 230))
    draw.text((82, 420), "One private wallet.", font=f_tag, fill=(0x94, 0xE1, 0xC8))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    base.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT.relative_to(ROOT)} ({W}x{H})")


if __name__ == "__main__":
    main()
