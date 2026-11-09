#!/usr/bin/env python3
"""Render terminal-style PNGs (1920x1080) in the NEAR-video style:
dark bg, mac-dot title bar, green command line, light body text,
amber highlight on key lines. Input: text file (+ optional title).
Long lines are wrapped at MAX_COLS. Lines matching HIGHLIGHT substrings
are drawn amber; lines starting with '$' are drawn green+bold."""
import sys, textwrap
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
BG = (22, 24, 29)
TITLE_BG = (35, 38, 45)
GREEN = (126, 231, 135)
AMBER = (232, 163, 61)
BODY = (230, 230, 230)
DIM = (150, 150, 150)
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
MONO_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
SANS_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

HIGHLIGHT = ('"score"', '"verdict"', '"simulationError"', '"simulationOk"',
             'MPC sign latency', 'recovery:', 'receipt: status=success',
             'LAYER A', 'ownerOf(1)', 'Contract deployed', 'broadcast:',
             'BadStatus', 'execution reverted', 'CLAIMED', '(SAFE)', '(RISKY)')

def render(in_path, out_path, title, font_size=21, max_cols=150):
    font = ImageFont.truetype(MONO, font_size)
    font_b = ImageFont.truetype(MONO_B, font_size)
    font_t = ImageFont.truetype(MONO, 26)
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 62], fill=TITLE_BG)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([28 + i * 34, 21, 48 + i * 34, 41], fill=c)
    d.text((140, 18), title, font=font_t, fill=(200, 200, 200))
    lines = []
    for raw in open(in_path, encoding="utf-8").read().splitlines():
        if raw == "":
            lines.append("")
        else:
            lines.extend(textwrap.wrap(raw, width=max_cols,
                                       replace_whitespace=False,
                                       drop_whitespace=False) or [""])
    lh = int(font_size * 1.42)
    y = 84
    for line in lines:
        if y + lh > H - 10:
            break
        if line.startswith("$ "):
            d.text((48, y), line, font=font_b, fill=GREEN)
        elif any(h in line for h in HIGHLIGHT):
            d.text((48, y), line, font=font_b, fill=AMBER)
        elif line.startswith("[ok ]"):
            d.text((48, y), line, font=font, fill=(140, 220, 160))
        else:
            d.text((48, y), line, font=font, fill=BODY)
        y += lh
    img.save(out_path)
    print(f"wrote {out_path} ({len(lines)} lines)")

if __name__ == "__main__":
    # usage: render_term.py <in.txt> <out.png> <title> [font_size]
    render(sys.argv[1], sys.argv[2], sys.argv[3],
           int(sys.argv[4]) if len(sys.argv) > 4 else 21)
