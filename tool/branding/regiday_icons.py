#!/usr/bin/env python3
"""Regiday icon master and platform exports.

One glyph geometry (below, in 100-unit glyph space) produces:

- design/branding/regiday/*.svg            editable vector masters
- design/branding/regiday/exports/*.png    Play 512, iOS 1024 masters
- design/branding/regiday/previews/*.png   size/mask/theme previews, contact sheet
- android/app/src/main/res/...             adaptive (vector) + legacy launcher icons
- ios/Runner/Assets.xcassets/AppIcon.appiconset  single-size any/dark/tinted

SVG path data and Android VectorDrawable pathData share the same absolute
M/L/Q/C/Z syntax, so both are emitted from the same commands. PNGs are
rasterized here (4x supersampled polygons) so no SVG renderer is needed.

Usage (from the repository root):

    python3 -m venv build/branding-venv
    build/branding-venv/bin/pip install pillow==11.3.0
    build/branding-venv/bin/python tool/branding/regiday_icons.py
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
DESIGN = ROOT / "design" / "branding" / "regiday"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
APPICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

INDIGO = "#4E46E5"
DEEP_INDIGO = "#272078"
GRADIENT_END = "#332B99"  # 70% of the way from INDIGO to DEEP_INDIGO
IVORY = "#FFFDF8"
MINT = "#94E1C8"
FOLD_SHADOW_ALPHA = 0.16

SS = 4  # supersampling factor for PNG rasterization

# --- Glyph geometry (glyph box x 0..84, y 0..100) -------------------------
# Folded-document R: the bowl's top-right corner is cut on the diagonal and
# the folded flap sits in that corner.

PAGE = [
    ("M", 0, 7), ("Q", 0, 0, 7, 0),
    ("L", 62, 0),
    ("L", 82, 20),
    ("L", 82, 34),
    ("C", 82, 50, 72, 60, 58, 62),
    ("L", 84, 100),
    ("L", 57, 100),
    ("L", 35, 66),
    ("L", 27, 66),
    ("L", 27, 93), ("Q", 27, 100, 20, 100),
    ("L", 7, 100), ("Q", 0, 100, 0, 93),
    ("Z",),
]

COUNTER = [
    ("M", 27, 22),
    ("L", 50, 22),
    ("C", 56, 22, 58, 27, 58, 33),
    ("C", 58, 39, 56, 44, 50, 44),
    ("L", 27, 44),
    ("Z",),
]

FLAP = [
    ("M", 62, 0),
    ("L", 62, 16), ("Q", 62, 20, 66, 20),
    ("L", 82, 20),
    ("Z",),
]

FLAP_SHADOW = [
    ("M", 60, 2),
    ("L", 60, 22),
    ("L", 80, 22),
    ("Z",),
]

# Monochrome: the page is notched where the flap sits, leaving a gap so the
# fold still reads when everything is one colour.
MONO_PAGE = [
    ("M", 0, 7), ("Q", 0, 0, 7, 0),
    ("L", 58.5, 0),
    ("L", 58.5, 23.5),
    ("L", 82, 23.5),
    ("L", 82, 34),
    ("C", 82, 50, 72, 60, 58, 62),
    ("L", 84, 100),
    ("L", 57, 100),
    ("L", 35, 66),
    ("L", 27, 66),
    ("L", 27, 93), ("Q", 27, 100, 20, 100),
    ("L", 7, 100), ("Q", 0, 100, 0, 93),
    ("Z",),
]

GLYPH_W, GLYPH_H = 84.0, 100.0


def placement(canvas: float, glyph_height: float):
    """Scale/offset that centres the glyph box with the given height."""
    s = glyph_height / GLYPH_H
    return s, canvas / 2 - GLYPH_W / 2 * s, canvas / 2 - GLYPH_H / 2 * s


# iOS / Play square master: glyph is 56% of the canvas height.
SQUARE_GLYPH = 0.56
# Android adaptive: 108dp canvas, 66dp safe circle. A 46dp glyph keeps its
# farthest corner ~30dp from the centre.
ADAPTIVE_GLYPH_DP = 46.0


# --- Path helpers ---------------------------------------------------------

def _fmt(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".")


def path_data(cmds, s, tx, ty) -> str:
    out = []
    for c in cmds:
        op, pts = c[0], c[1:]
        mapped = [
            _fmt(p * s + (tx if i % 2 == 0 else ty)) for i, p in enumerate(pts)
        ]
        out.append(op + ",".join(mapped) if mapped else op)
    return " ".join(out)


def flatten(cmds, s, tx, ty, steps=24):
    polys, cur, pos = [], [], (0.0, 0.0)

    def m(x, y):
        return (x * s + tx, y * s + ty)

    for c in cmds:
        op = c[0]
        if op == "M":
            if cur:
                polys.append(cur)
            pos = m(c[1], c[2])
            cur = [pos]
        elif op == "L":
            pos = m(c[1], c[2])
            cur.append(pos)
        elif op == "Q":
            p0, p1, p2 = pos, m(c[1], c[2]), m(c[3], c[4])
            for i in range(1, steps + 1):
                t = i / steps
                cur.append(
                    tuple(
                        (1 - t) ** 2 * p0[k] + 2 * (1 - t) * t * p1[k] + t * t * p2[k]
                        for k in range(2)
                    )
                )
            pos = p2
        elif op == "C":
            p0, p1, p2, p3 = pos, m(c[1], c[2]), m(c[3], c[4]), m(c[5], c[6])
            for i in range(1, steps + 1):
                t = i / steps
                cur.append(
                    tuple(
                        (1 - t) ** 3 * p0[k]
                        + 3 * (1 - t) ** 2 * t * p1[k]
                        + 3 * (1 - t) * t * t * p2[k]
                        + t**3 * p3[k]
                        for k in range(2)
                    )
                )
            pos = p3
        elif op == "Z":
            if cur:
                polys.append(cur)
            cur = []
    if cur:
        polys.append(cur)
    return polys


def rgb(hex_color: str):
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


# --- Raster helpers -------------------------------------------------------

def mask(size, shapes):
    """shapes: list of (cmds, s, tx, ty, fill) in output-pixel units."""
    big = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(big)
    for cmds, s, tx, ty, fill in shapes:
        for poly in flatten(cmds, s * SS, tx * SS, ty * SS):
            d.polygon(poly, fill=fill)
    return big.resize((size, size), Image.LANCZOS)


def gradient(size, start=INDIGO, end=GRADIENT_END):
    n = 64
    g = Image.new("L", (n, n))
    g.putdata([round(255 * (x + y) / (2 * (n - 1))) for y in range(n) for x in range(n)])
    g = g.resize((size, size), Image.BICUBIC)
    return Image.composite(
        Image.new("RGBA", (size, size), rgb(end) + (255,)),
        Image.new("RGBA", (size, size), rgb(start) + (255,)),
        g,
    )


def solid(size, color, alpha=255):
    return Image.new("RGBA", (size, size), rgb(color) + (alpha,))


def paint(base, color, m, alpha=1.0):
    layer = solid(base.size[0], color)
    if alpha < 1.0:
        m = m.point(lambda v: round(v * alpha))
    base.alpha_composite(Image.composite(layer, Image.new("RGBA", base.size, (0, 0, 0, 0)), m))
    return base


def glyph_color(base, s, tx, ty, page=IVORY, flap=MINT, shadow=True):
    size = base.size[0]
    paint(base, page, mask(size, [(PAGE, s, tx, ty, 255), (COUNTER, s, tx, ty, 0)]))
    if shadow:
        page_m = mask(size, [(PAGE, s, tx, ty, 255), (COUNTER, s, tx, ty, 0)])
        sh = mask(size, [(FLAP_SHADOW, s, tx, ty, 255)])
        paint(base, DEEP_INDIGO, ImageChops.multiply(sh, page_m), FOLD_SHADOW_ALPHA)
    paint(base, flap, mask(size, [(FLAP, s, tx, ty, 255)]))
    return base


def mono_mask(size, s, tx, ty):
    return mask(
        size,
        [(MONO_PAGE, s, tx, ty, 255), (COUNTER, s, tx, ty, 0), (FLAP, s, tx, ty, 255)],
    )


def square_master(size, background=True, page=IVORY, flap=MINT, shadow=True):
    base = gradient(size) if background else Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s, tx, ty = placement(size, size * SQUARE_GLYPH)
    return glyph_color(base, s, tx, ty, page, flap, shadow)


def adaptive_full(size):
    """Adaptive background + foreground on the full 108dp canvas."""
    base = gradient(size)
    s, tx, ty = placement(size, size * ADAPTIVE_GLYPH_DP / 108)
    return glyph_color(base, s, tx, ty)


def shape_mask(size, shape, inset=0.0):
    big = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(big)
    a, b = inset * size * SS, (size - inset * size) * SS - 1
    if shape == "circle":
        d.ellipse((a, a, b, b), fill=255)
    elif shape == "rounded":
        d.rounded_rectangle((a, a, b, b), radius=(b - a) * 0.22, fill=255)
    elif shape == "squircle":
        n, r, c = 4.0, (b - a) / 2, (a + b) / 2
        pts = []
        for i in range(360):
            t = math.radians(i)
            ct, st = math.cos(t), math.sin(t)
            pts.append(
                (
                    c + r * math.copysign(abs(ct) ** (2 / n), ct),
                    c + r * math.copysign(abs(st) ** (2 / n), st),
                )
            )
        d.polygon(pts, fill=255)
    elif shape == "ios":
        d.rounded_rectangle((a, a, b, b), radius=(b - a) * 0.2237, fill=255)
    elif shape == "play":
        d.rounded_rectangle((a, a, b, b), radius=(b - a) * 0.20, fill=255)
    return big.resize((size, size), Image.LANCZOS)


def masked(img, shape, inset=0.0):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), shape_mask(img.size[0], shape, inset))
    return out


def launcher_view(size, shape):
    """What a launcher shows: centre 72dp of the 108dp adaptive canvas, masked."""
    full = adaptive_full(round(size * 108 / 72))
    off = (full.size[0] - size) // 2
    return masked(full.crop((off, off, off + size, off + size)), shape)


def themed_view(size, shape, bg, fg):
    full_size = round(size * 108 / 72)
    s, tx, ty = placement(full_size, full_size * ADAPTIVE_GLYPH_DP / 108)
    base = solid(full_size, bg)
    paint(base, fg, mono_mask(full_size, s, tx, ty))
    off = (full_size - size) // 2
    return masked(base.crop((off, off, off + size, off + size)), shape)


# --- Writers --------------------------------------------------------------

def write_svgs():
    DESIGN.mkdir(parents=True, exist_ok=True)
    s, tx, ty = placement(1024, 1024 * SQUARE_GLYPH)
    page = path_data(PAGE, s, tx, ty) + " " + path_data(COUNTER, s, tx, ty)
    master = f"""<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <title>Regiday icon master (square, opaque; the OS applies the mask)</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1024" y2="1024" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{INDIGO}"/>
      <stop offset="1" stop-color="{GRADIENT_END}"/>
    </linearGradient>
  </defs>
  <rect id="background" width="1024" height="1024" fill="url(#bg)"/>
  <path id="page" fill="{IVORY}" fill-rule="evenodd" d="{page}"/>
  <path id="fold-shadow" fill="{DEEP_INDIGO}" fill-opacity="{FOLD_SHADOW_ALPHA}" d="{path_data(FLAP_SHADOW, s, tx, ty)}"/>
  <path id="fold" fill="{MINT}" d="{path_data(FLAP, s, tx, ty)}"/>
</svg>
"""
    (DESIGN / "regiday_icon_master.svg").write_text(master)

    s, tx, ty = placement(108, ADAPTIVE_GLYPH_DP)
    fg_page = path_data(PAGE, s, tx, ty) + " " + path_data(COUNTER, s, tx, ty)
    fg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">
  <title>Regiday Android adaptive foreground (108dp canvas, 66dp safe circle)</title>
  <path id="page" fill="{IVORY}" fill-rule="evenodd" d="{fg_page}"/>
  <path id="fold-shadow" fill="{DEEP_INDIGO}" fill-opacity="{FOLD_SHADOW_ALPHA}" d="{path_data(FLAP_SHADOW, s, tx, ty)}"/>
  <path id="fold" fill="{MINT}" d="{path_data(FLAP, s, tx, ty)}"/>
</svg>
"""
    (DESIGN / "regiday_adaptive_foreground.svg").write_text(fg)

    mono_page = path_data(MONO_PAGE, s, tx, ty) + " " + path_data(COUNTER, s, tx, ty)
    mono = f"""<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">
  <title>Regiday monochrome (themed icon) layer</title>
  <path id="page" fill="#000000" fill-rule="evenodd" d="{mono_page}"/>
  <path id="fold" fill="#000000" d="{path_data(FLAP, s, tx, ty)}"/>
</svg>
"""
    (DESIGN / "regiday_monochrome.svg").write_text(mono)


def write_android():
    s, tx, ty = placement(108, ADAPTIVE_GLYPH_DP)
    drawable = RES / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    header = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/branding/regiday_icons.py. Do not edit by hand. -->\n"
    )
    vec = (
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"{extra}\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
    )
    page = path_data(PAGE, s, tx, ty) + " " + path_data(COUNTER, s, tx, ty)
    (drawable / "ic_launcher_foreground.xml").write_text(
        header
        + vec.format(extra="")
        + f'    <path\n        android:fillColor="{IVORY}"\n        android:fillType="evenOdd"\n        android:pathData="{page}" />\n'
        + f'    <path\n        android:fillColor="{DEEP_INDIGO}"\n        android:fillAlpha="{FOLD_SHADOW_ALPHA}"\n        android:pathData="{path_data(FLAP_SHADOW, s, tx, ty)}" />\n'
        + f'    <path\n        android:fillColor="{MINT}"\n        android:pathData="{path_data(FLAP, s, tx, ty)}" />\n'
        + "</vector>\n"
    )
    (drawable / "ic_launcher_background.xml").write_text(
        header
        + vec.format(extra='\n    xmlns:aapt="http://schemas.android.com/aapt"')
        + '    <path android:pathData="M0,0h108v108h-108z">\n'
        + '        <aapt:attr name="android:fillColor">\n'
        + '            <gradient\n'
        + '                android:type="linear"\n'
        + '                android:startX="0"\n'
        + '                android:startY="0"\n'
        + '                android:endX="108"\n'
        + '                android:endY="108">\n'
        + f'                <item android:offset="0" android:color="{INDIGO}" />\n'
        + f'                <item android:offset="1" android:color="{GRADIENT_END}" />\n'
        + "            </gradient>\n"
        + "        </aapt:attr>\n"
        + "    </path>\n"
        + "</vector>\n"
    )
    mono_page = path_data(MONO_PAGE, s, tx, ty) + " " + path_data(COUNTER, s, tx, ty)
    (drawable / "ic_launcher_monochrome.xml").write_text(
        header
        + vec.format(extra="")
        + f'    <path\n        android:fillColor="#FFFFFFFF"\n        android:fillType="evenOdd"\n        android:pathData="{mono_page}" />\n'
        + f'    <path\n        android:fillColor="#FFFFFFFF"\n        android:pathData="{path_data(FLAP, s, tx, ty)}" />\n'
        + "</vector>\n"
    )

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/branding/regiday_icons.py. Do not edit by hand. -->\n"
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )
    (anydpi / "ic_launcher.xml").write_text(adaptive)
    (anydpi / "ic_launcher_round.xml").write_text(adaptive)

    # Legacy (API < 26) bitmaps: the launcher does not mask these, so the
    # shape is part of the bitmap, as in the platform's legacy templates.
    for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        art = square_master(px * 2).resize((px, px), Image.LANCZOS)
        masked(art, "rounded", inset=1 / 24).save(folder / "ic_launcher.png", optimize=True)
        masked(art, "circle", inset=1 / 24).save(folder / "ic_launcher_round.png", optimize=True)


def write_ios():
    APPICON.mkdir(parents=True, exist_ok=True)
    for old in APPICON.glob("Icon-App-*.png"):
        old.unlink()
    square_master(1024).convert("RGB").save(APPICON / "AppIcon-1024.png", optimize=True)
    # Dark: transparent background so iOS supplies its dark backdrop.
    square_master(1024, background=False).save(APPICON / "AppIcon-1024-dark.png", optimize=True)
    # Tinted: grayscale artwork; iOS maps luminance to the user's tint.
    square_master(1024, background=False, page="#FFFFFF", flap="#8E8E8E", shadow=False).save(
        APPICON / "AppIcon-1024-tinted.png", optimize=True
    )
    contents = {
        "images": [
            {"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "filename": "AppIcon-1024-dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
            {
                "appearances": [{"appearance": "luminosity", "value": "tinted"}],
                "filename": "AppIcon-1024-tinted.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (APPICON / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def write_exports():
    exports = DESIGN / "exports"
    exports.mkdir(parents=True, exist_ok=True)
    master = square_master(1024).convert("RGB")
    master.save(exports / "regiday_ios_master_1024.png", optimize=True)
    square_master(1024).convert("RGB").resize((512, 512), Image.LANCZOS).save(
        exports / "regiday_play_listing_512.png", optimize=True
    )
    adaptive_full(432).save(exports / "regiday_android_adaptive_full_432.png", optimize=True)


def _font(px):
    for f in ("/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/SFNS.ttf"):
        try:
            return ImageFont.truetype(f, px)
        except OSError:
            continue
    return ImageFont.load_default()


def write_previews():
    out = DESIGN / "previews"
    out.mkdir(parents=True, exist_ok=True)
    tile, pad, label_h = 200, 28, 44
    font, head = _font(15), _font(22)

    ios_dark_bg = Image.new("RGBA", (tile, tile), (28, 28, 30, 255))
    dark = ios_dark_bg.copy()
    dark.alpha_composite(square_master(tile, background=False))
    tinted = Image.new("RGBA", (tile, tile), (20, 20, 22, 255))
    t = square_master(tile, background=False, page="#FFFFFF", flap="#8E8E8E", shadow=False)
    luminance = ImageChops.multiply(t.convert("L"), t.split()[3])
    paint(tinted, "#FFC478", luminance)

    rows = [
        (
            "iOS (OS applies mask; previews masked for review)",
            [
                ("Master 1024, unmasked", square_master(tile)),
                ("iOS light, masked", masked(square_master(tile), "ios")),
                ("iOS dark (transparent art)", masked(dark, "ios")),
                ("iOS tinted (simulated)", masked(tinted, "ios")),
                ("Play 512, Play mask", masked(square_master(tile), "play")),
            ],
        ),
        (
            "Android adaptive (72dp visible of 108dp canvas)",
            [
                ("Circle", launcher_view(tile, "circle")),
                ("Rounded square", launcher_view(tile, "rounded")),
                ("Squircle", launcher_view(tile, "squircle")),
                ("Themed, light", themed_view(tile, "circle", "#E6E4FF", "#2E2A7A")),
                ("Themed, dark", themed_view(tile, "circle", "#2A2940", "#CFCBFF")),
            ],
        ),
        (
            "Android safe zone and legacy",
            [
                ("Full 108dp canvas", adaptive_full(tile)),
                ("66dp safe circle overlay", None),
                ("Legacy ic_launcher", Image.open(RES / "mipmap-xxxhdpi" / "ic_launcher.png").convert("RGBA").resize((tile, tile), Image.LANCZOS)),
                ("Legacy round", Image.open(RES / "mipmap-xxxhdpi" / "ic_launcher_round.png").convert("RGBA").resize((tile, tile), Image.LANCZOS)),
                ("Monochrome layer", themed_view(tile, "rounded", "#FFFFFF", "#000000")),
            ],
        ),
    ]
    safe = adaptive_full(tile)
    d = ImageDraw.Draw(safe)
    r = tile * 33 / 108
    c = tile / 2
    d.ellipse((c - r, c - r, c + r, c + r), outline=(255, 80, 80, 255), width=2)
    v = tile * 18 / 108
    d.rectangle((v, v, tile - v, tile - v), outline=(255, 220, 0, 255), width=1)
    rows[2][1][1] = ("Safe circle / 72dp view", safe)

    small_sizes = [24, 32, 48]
    small_row_h = 48 * 4 + label_h + pad
    cols = 5
    small_w = pad + sum(2 * (px * 5 + 8 + 40) for px in small_sizes)
    width = max(pad + cols * (tile + pad), small_w)
    height = pad + len(rows) * (36 + tile + label_h + pad) + 36 + small_row_h + pad
    sheet = Image.new("RGBA", (width, height), (246, 245, 250, 255))
    d = ImageDraw.Draw(sheet)
    y = pad
    for title, items in rows:
        d.text((pad, y), title, fill=(30, 30, 40), font=head)
        y += 36
        for i, (label, img) in enumerate(items):
            x = pad + i * (tile + pad)
            sheet.alpha_composite(img, (x, y))
            d.text((x, y + tile + 8), label, fill=(60, 60, 70), font=font)
        y += tile + label_h + pad
    d.text((pad, y), "Small sizes: actual pixels (left) and 4x nearest-neighbour zoom (right)", fill=(30, 30, 40), font=head)
    y += 36
    x = pad
    for px in small_sizes:
        for label, img in (
            (f"Android circle {px}px", launcher_view(px * 4, "circle").resize((px, px), Image.LANCZOS)),
            (f"iOS {px}px", masked(square_master(px * 4), "ios").resize((px, px), Image.LANCZOS)),
        ):
            sheet.alpha_composite(img, (x, y))
            zoom = img.resize((px * 4, px * 4), Image.NEAREST)
            sheet.alpha_composite(zoom, (x + px + 8, y))
            d.text((x, y + px * 4 + 8), label, fill=(60, 60, 70), font=font)
            x += px * 5 + 8 + 40
    sheet.convert("RGB").save(out / "regiday_icon_contact_sheet.png", optimize=True)

    for px in small_sizes:
        launcher_view(px * 4, "circle").resize((px, px), Image.LANCZOS).save(out / f"android_circle_{px}.png")
        masked(square_master(px * 4), "ios").resize((px, px), Image.LANCZOS).save(out / f"ios_{px}.png")


def main():
    write_svgs()
    write_android()
    write_ios()
    write_exports()
    write_previews()
    print("Regiday icons written.")


if __name__ == "__main__":
    main()
