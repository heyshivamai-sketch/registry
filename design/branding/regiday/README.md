# Regiday icon (candidate brand)

Status: **candidate brand for private QA**. Name and mark clearance (trademark, store name, domain) is still pending. Do not publish on the basis of these files.

## Reference

The concept icon generated with the brief ("ivory folded-document R, small mint page fold, indigo background") was **not available** to this task: the brief was attached without the image, and no copy was found in the repository. `regiday_icon_reference.png` is therefore not present.

The vector master here was drawn from the brief's written description and palette tokens. It is an interpretation, not a trace of the concept image. When the reference image is supplied, save it as `regiday_icon_reference.png` in this folder, compare, and adjust the geometry in `tool/branding/regiday_icons.py`, then regenerate.

## Palette

| Token | Value | Use |
| --- | --- | --- |
| Indigo | `#4E46E5` | Background gradient start |
| Deep indigo | `#272078` | Fold shadow (16% opacity); gradient end is 70% toward it, `#332B99` |
| Ivory | `#FFFDF8` | Folded-document R |
| Mint | `#94E1C8` | Page fold |

## Files

| File | What it is |
| --- | --- |
| `regiday_icon_master.svg` | Editable 1024 square master, opaque, no rounded corners (the OS applies the mask) |
| `regiday_adaptive_foreground.svg` | Android adaptive foreground on the 108dp canvas (glyph inside the 66dp safe circle) |
| `regiday_monochrome.svg` | Single-colour layer for Android themed icons (fold separated by a gap) |
| `exports/regiday_ios_master_1024.png` | 1024 opaque iOS master (same as `AppIcon-1024.png`) |
| `exports/regiday_play_listing_512.png` | 512 Play listing icon, opaque, square |
| `exports/regiday_android_adaptive_full_432.png` | Full adaptive canvas for review |
| `previews/regiday_icon_contact_sheet.png` | Masks, themes, safe zone, legacy, 24/32/48 px |

Platform outputs (all generated):

- Android: `res/drawable/ic_launcher_{foreground,background,monochrome}.xml` (vectors), `res/mipmap-anydpi-v26/ic_launcher{,_round}.xml` (adaptive with monochrome), `res/mipmap-*/ic_launcher{,_round}.png` (legacy, API < 26). The notification small icon `res/drawable/ic_notification.xml` is unchanged (single-colour bell).
- iOS: `Assets.xcassets/AppIcon.appiconset` single-size 1024 with Any, Dark (transparent background) and Tinted (grayscale) appearances. Xcode derives the smaller sizes.

## Regenerate

```sh
python3 -m venv build/branding-venv
build/branding-venv/bin/pip install pillow==11.3.0
build/branding-venv/bin/python tool/branding/regiday_icons.py
```

## Known limits

- At 24 px the mint fold is only about two pixels; it reads from 32 px up.
- The dark and tinted iOS appearances follow the asset-catalog appearance slots. An Icon Composer (`.icon`) layered icon has not been made.
