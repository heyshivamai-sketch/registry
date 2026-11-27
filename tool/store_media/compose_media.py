#!/usr/bin/env python3
"""Build Google Play screenshots and a promo video for Regiday.

Inputs:
  artifacts/store_media/raw/*.png   1080x1920 app screenshots from
                                    integration_test/store_media_test.dart

Outputs:
  artifacts/store_media/play/phone_*.png   8 captioned 1080x1920 phone screenshots
  artifacts/store_media/promo/Regiday-promo-1920x1080.mp4
  artifacts/store_media/promo/Regiday-promo-thumbnail-1280x720.png
  artifacts/store_media/promo/narration.wav, music.wav

Narration uses macOS `say` (voice Daniel). Background music is generated here.
Nothing is downloaded, and no third-party music or voice is used.

Run from the repo root:
    build/branding-venv/bin/python tool/store_media/compose_media.py
"""

import shutil
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
RAW = ROOT / "artifacts/store_media/raw"
PLAY = ROOT / "artifacts/store_media/play"
PROMO = ROOT / "artifacts/store_media/promo"
WORK = ROOT / "build/store_media"
ICON = ROOT / "design/branding/regiday/exports/regiday_play_listing_512.png"
FONT_BOLD = ROOT / "assets/fonts/Lora-Bold.ttf"
FONT_SEMI = ROOT / "assets/fonts/Lora-SemiBold.ttf"

W, H = 1920, 1080
FPS = 30
DISSOLVE = 0.8
SR = 48000
VOICE = "Daniel"  # en_GB, matches the en-GB store listing

INDIGO = (0x4E, 0x46, 0xE5)
DEEP_INDIGO = (0x33, 0x2B, 0x99)
IVORY = (0xFF, 0xFD, 0xF8)
MINT = (0x94, 0xE1, 0xC8)

# (raw file, headline, supporting line, narration)
SCENES = [
    (
        "01_home",
        "Every renewal, in view.",
        "See what needs your attention next.",
        "Start with what needs attention. Regiday shows your renewals and deadlines first.",
    ),
    (
        "02_documents",
        "Every document, one wallet.",
        "Search and filter in seconds.",
        "Every important document, in one searchable wallet.",
    ),
    (
        "03_document_detail",
        "Know every date that matters.",
        "Issue, action and expiry dates at a glance.",
        "Open any document to see its issue, action and expiry dates at a glance.",
    ),
    (
        "04_add_document",
        "Add a document in a few steps.",
        "Scan fills in the details. You check every field first.",
        "Add a document in a few steps. Scan can fill in the details, and you check every field before saving.",
    ),
    (
        "05_subscriptions",
        "Track every subscription.",
        "Cost and next payment, always visible.",
        "Track every subscription, with its cost and next payment date.",
    ),
    (
        "06_calendar",
        "Never miss a renewal.",
        "Your month of renewals on one calendar.",
        "See all your renewals on one calendar, so nothing catches you off guard.",
    ),
    (
        "07_profile",
        "Private by design.",
        "Stored on your device. Encrypted backups. App lock.",
        "Your records stay on this device. Make encrypted backups, and lock the app with your fingerprint or face.",
    ),
    (
        "08_home_end",
        "Your papers. Your dates.",
        "One private wallet.",
        "Regiday. Your papers. Your dates. One private wallet.",
    ),
]
INTRO_NARRATION = "Meet Regiday. Your papers, your dates, one private wallet."
OUTRO_NARRATION = "Regiday is built by Ventrova Labs. Your records stay on your device."


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def gradient(width: int, height: int) -> Image.Image:
    """Diagonal indigo gradient, matching the app icon and feature graphic."""
    xs = np.linspace(0, 1, width)[None, :]
    ys = np.linspace(0, 1, height)[:, None]
    t = ((xs + ys) / 2)[..., None]
    start = np.array(INDIGO, dtype=float)
    end = np.array(DEEP_INDIGO, dtype=float)
    rgb = (start + (end - start) * t).round().astype(np.uint8)
    return Image.fromarray(rgb).convert("RGBA")


def add_arcs(base: Image.Image, cx: int, cy: int, step: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    r = step
    while r < max(base.size) * 1.2:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 253, 248, 26), width=2)
        r += step
    base.alpha_composite(layer)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    words, lines, line = text.split(), [], ""
    for word in words:
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=fnt) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def draw_block(draw, x, y, lines, fnt, fill, spacing) -> int:
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + spacing
    return y


def framed(raw: Path, width: int, radius: int, margin: int) -> Image.Image:
    """Screenshot with rounded corners and a soft shadow, padded by margin."""
    shot = Image.open(raw).convert("RGBA")
    height = round(width * shot.height / shot.width)
    shot = shot.resize((width, height), Image.LANCZOS)
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius, fill=255)
    shot.putalpha(mask)

    out = Image.new("RGBA", (width + 2 * margin, height + 2 * margin), (0, 0, 0, 0))
    shadow = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (margin, margin + 26, margin + width, margin + height + 26),
        radius,
        fill=(8, 6, 40, 150),
    )
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(34)))
    out.alpha_composite(shot, (margin, margin))
    return out


def play_screenshot(raw: Path, headline: str, support: str, out: Path) -> None:
    """1080x1920 captioned phone screenshot for the Play listing."""
    canvas = gradient(1080, 1920)
    add_arcs(canvas, cx=980, cy=420, step=90)
    draw = ImageDraw.Draw(canvas)
    f_head = font(FONT_BOLD, 84)
    f_sub = font(FONT_SEMI, 40)
    lines = wrap(draw, headline, f_head, 760)
    y = draw_block(draw, 80, 130, lines, f_head, IVORY, 6)
    draw_block(draw, 80, y + 18, wrap(draw, support, f_sub, 920), f_sub, MINT, 8)

    phone = framed(raw, width=820, radius=56, margin=40)
    canvas.alpha_composite(phone, (90, 410))
    canvas.convert("RGB").save(out, "PNG", optimize=True)


def caption_layer(headline: str, support: str) -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    f_head = font(FONT_BOLD, 92)
    f_sub = font(FONT_SEMI, 44)
    lines = wrap(draw, headline, f_head, 720)
    y = draw_block(draw, 120, 360, lines, f_head, IVORY, 8)
    draw_block(draw, 120, y + 26, wrap(draw, support, f_sub, 720), f_sub, MINT, 10)
    return layer


def brand_card(headline: str, support: str, footer: str | None, out: Path) -> None:
    card = gradient(W, H)
    add_arcs(card, cx=1500, cy=540, step=110)
    icon = Image.open(ICON).convert("RGBA").resize((380, 380), Image.LANCZOS)
    card.alpha_composite(icon, (150, 350))
    draw = ImageDraw.Draw(card)
    draw.text((620, 300), "Regiday", font=font(FONT_BOLD, 150), fill=IVORY)
    draw_block(draw, 626, 500, [headline], font(FONT_SEMI, 60), MINT, 8)
    draw_block(draw, 626, 590, wrap(draw, support, font(FONT_SEMI, 44), 1000), font(FONT_SEMI, 44), IVORY, 10)
    if footer:
        draw.text((626, 900), footer, font=font(FONT_SEMI, 38), fill=(255, 253, 248, 200))
    card.convert("RGB").save(out, "PNG", optimize=True)


def speech(text: str, out_wav: Path) -> float:
    """Synthesize narration with macOS say; return duration in seconds."""
    aiff = out_wav.with_suffix(".aiff")
    subprocess.run(["say", "-v", VOICE, "-r", "170", "-o", str(aiff), text], check=True)
    subprocess.run(
        [FFMPEG, "-y", "-loglevel", "error", "-i", str(aiff), "-ar", str(SR), "-ac", "1",
         "-sample_fmt", "s16", str(out_wav)],
        check=True,
    )
    return read_wav(out_wav).size / SR


def read_wav(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as w:
        frames = w.readframes(w.getnframes())
    return np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0


def music(seconds: float) -> np.ndarray:
    """Soft, generated pad in C major. Original synthesis, no samples."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    chords = [
        (130.81, 164.81, 196.00, 246.94),  # C
        (110.00, 130.81, 164.81, 196.00),  # Am
        (87.31, 110.00, 130.81, 164.81),   # F
        (98.00, 123.47, 146.83, 174.61),   # G
    ]
    bar = 8.0
    out = np.zeros(n, dtype=np.float32)
    for index in range(int(seconds / bar) + 1):
        start = index * bar
        mask = (t >= start) & (t < start + bar)
        if not mask.any():
            continue
        local = t[mask] - start
        env = np.minimum(1.0, local / 1.2) * np.minimum(1.0, (bar - local) / 1.5)
        tone = np.zeros(local.shape, dtype=np.float32)
        for freq in chords[index % len(chords)]:
            tone += np.sin(2 * np.pi * freq * local) + 0.3 * np.sin(2 * np.pi * freq * 2 * local)
        tone *= env / 4.0
        out[mask] += tone * 0.09
    fade = np.minimum(1.0, t / 2.0) * np.minimum(1.0, (seconds - t) / 3.0)
    return out * fade


def write_wav(path: Path, samples: np.ndarray) -> None:
    peak = np.max(np.abs(samples)) or 1.0
    pcm = (np.clip(samples / peak * 0.89, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def run(cmd: list[str]) -> None:
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", *cmd], check=True)


def still_clip(image: Path, seconds: float, out: Path) -> None:
    run([
        "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(image),
        "-vf", "format=yuv420p", "-r", str(FPS), "-c:v", "libx264", "-preset", "medium",
        "-crf", "18", str(out),
    ])


def scene_clip(bg: Path, caption: Path, phone: Path, seconds: float, out: Path) -> None:
    """Background, caption and phone; the phone drifts gently so the frame never sits still."""
    x0, y0 = 1340 - 40, 150 - 40
    fc = (
        "[0:v][1:v]overlay=0:0[a];"
        f"[a][2:v]overlay=x='{x0}+16*sin(2*PI*t/11)':y='{y0}+10*cos(2*PI*t/13)',"
        "format=yuv420p[v]"
    )
    run([
        "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(bg),
        "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(caption),
        "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(phone),
        "-filter_complex", fc, "-map", "[v]", "-r", str(FPS),
        "-c:v", "libx264", "-preset", "medium", "-crf", "18", str(out),
    ])


def dissolve(clips: list[Path], durations: list[float], out: Path) -> None:
    """Chain clips with cross-dissolves. Offsets keep the dissolves aligned with the audio."""
    inputs: list[str] = []
    for clip in clips:
        inputs += ["-i", str(clip)]
    parts = []
    prev = "[0:v]"
    cumulative = 0.0
    for i in range(1, len(clips)):
        cumulative += durations[i - 1]
        offset = cumulative - i * DISSOLVE
        label = f"[x{i}]" if i < len(clips) - 1 else "[vout]"
        parts.append(f"{prev}[{i}:v]xfade=transition=fade:duration={DISSOLVE}:offset={offset:.3f}{label}")
        prev = label
    run([*inputs, "-filter_complex", ";".join(parts), "-map", "[vout]", "-r", str(FPS),
         "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", str(out)])


def scene_start(durations: list[float], index: int) -> float:
    """Start time of clip `index` on the final timeline."""
    return sum(durations[:index]) - index * DISSOLVE


def main() -> None:
    for folder in (PLAY, PROMO, WORK):
        folder.mkdir(parents=True, exist_ok=True)
        
    # Captioned Play screenshots.
    for name, headline, support, _ in SCENES:
        play_screenshot(RAW / f"{name}.png", headline, support, PLAY / f"phone_{name}.png")
    print(f"play screenshots: {len(SCENES)} in {PLAY.relative_to(ROOT)}")

    # Narration lengths decide scene lengths, so no line is cut off.
    lines = [("intro", INTRO_NARRATION)] + [(n, s[3]) for n, s in zip([s[0] for s in SCENES], SCENES)]
    lines.append(("outro", OUTRO_NARRATION))
    speech_files = {}
    speech_len = {}
    for key, text in lines:
        wav = WORK / f"narr_{key}.wav"
        speech_len[key] = speech(text, wav)
        speech_files[key] = wav

    bg = WORK / "bg.png"
    gradient(W, H).convert("RGB").save(bg)

    brand_card(
        "Your papers. Your dates.",
        "One private wallet for the documents and renewals you can't afford to miss.",
        None,
        WORK / "intro.png",
    )
    brand_card(
        "Get Regiday",
        "Your papers. Your dates. One private wallet.",
        "ventrovatech.com",
        WORK / "outro.png",
    )

    clips, durations, starts = [], [], []
    intro_d = max(5.5, speech_len["intro"] + 1.6)
    still_clip(WORK / "intro.png", intro_d, WORK / "clip_00_intro.mp4")
    clips.append(WORK / "clip_00_intro.mp4")
    durations.append(intro_d)
    starts.append(("intro", "intro"))

    for i, (name, headline, support, _) in enumerate(SCENES, start=1):
        d = max(6.0, speech_len[name] + 1.8)
        caption = WORK / f"caption_{name}.png"
        caption_layer(headline, support).save(caption)
        phone = WORK / f"phone_{name}.png"
        framed(RAW / f"{name}.png", width=484, radius=40, margin=40).save(phone)
        clip = WORK / f"clip_{i:02d}_{name}.mp4"
        scene_clip(bg, caption, phone, d, clip)
        clips.append(clip)
        durations.append(d)
        starts.append((name, name))

    outro_d = max(7.0, speech_len["outro"] + 2.0)
    still_clip(WORK / "outro.png", outro_d, WORK / "clip_99_outro.mp4")
    clips.append(WORK / "clip_99_outro.mp4")
    durations.append(outro_d)
    starts.append(("outro", "outro"))

    total = sum(durations) - (len(durations) - 1) * DISSOLVE
    print("timeline (s):")
    for idx, (key, _) in enumerate(starts):
        print(f"  {key:18s} start {scene_start(durations, idx):6.1f}  length {durations[idx]:5.1f}")
    print(f"  total length {total:.1f}s")

    # Narration placed at each clip's start, plus a short lead-in.
    narration = np.zeros(int((total + 1) * SR), dtype=np.float32)
    for idx, (key, _) in enumerate(starts):
        voice = read_wav(speech_files[key])
        begin = int((scene_start(durations, idx) + 0.7) * SR)
        voice = voice[: max(0, len(narration) - begin)]
        narration[begin:begin + len(voice)] += voice
    music_track = music(total + 1) * 0.4
    mix = narration + music_track
    write_wav(PROMO / "narration.wav", narration)
    write_wav(PROMO / "music.wav", music_track)
    mix_path = WORK / "mix.wav"
    write_wav(mix_path, mix)

    video_only = WORK / "promo_video_only.mp4"
    dissolve(clips, durations, video_only)

    final = PROMO / "Regiday-promo-1920x1080.mp4"
    run([
        "-i", str(video_only), "-i", str(mix_path),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", str(SR),
        "-t", f"{total:.3f}", "-movflags", "+faststart", str(final),
    ])

    shutil.copy(WORK / "intro.png", PROMO / "intro_card.png")
    Image.open(WORK / "intro.png").resize((1280, 720), Image.LANCZOS).save(
        PROMO / "Regiday-promo-thumbnail-1280x720.png", optimize=True
    )
    print(f"promo video: {final.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
