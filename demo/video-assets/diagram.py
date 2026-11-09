#!/usr/bin/env python3
"""Loop diagram PNG (1920x1080) for the MintSentinel demo: 5 stages, dark bg
matching the terminal renders."""
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
BG = (22, 24, 29)
BOX = (35, 38, 45)
GREEN = (126, 231, 135)
AMBER = (232, 163, 61)
BODY = (230, 230, 230)
DIM = (170, 170, 170)
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SANS_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
f_title = ImageFont.truetype(SANS_B, 64)
f_h = ImageFont.truetype(SANS_B, 34)
f_b = ImageFont.truetype(SANS, 27)
f_small = ImageFont.truetype(MONO, 24)
f_foot = ImageFont.truetype(SANS, 30)

title = "MintSentinel — the loop"
tw = d.textlength(title, font=f_title)
d.text(((W - tw) / 2, 90), title, font=f_title, fill=BODY)
sub = "An AI verdict with real on-chain effect"
sw = d.textlength(sub, font=f_foot)
d.text(((W - sw) / 2, 180), sub, font=f_foot, fill=DIM)

stages = [
    ("1. MINT", "Free mint on", "Base Sepolia", "MintRequested event", GREEN),
    ("2. REACTIVE", "Lasna picks", "it up", "no off-chain bot", GREEN),
    ("3. CALLBACK", "Back to", "Base Sepolia", "gate armed", GREEN),
    ("4. AI VETTING", "MintGuard", "verdict", "posted on-chain", AMBER),
    ("5. GATE", "SAFE claims", "RISKY blocked", "enforced on-chain", AMBER),
]
bw, bh = 320, 300
gap = 28
x0 = (W - (5 * bw + 4 * gap)) // 2
y0 = 300
for i, (h, l1, l2, l3, accent) in enumerate(stages):
    x = x0 + i * (bw + gap)
    d.rounded_rectangle([x, y0, x + bw, y0 + bh], radius=18, fill=BOX, outline=accent, width=3)
    d.text((x + 24, y0 + 26), h, font=f_h, fill=accent)
    d.text((x + 24, y0 + 96), l1, font=f_b, fill=BODY)
    d.text((x + 24, y0 + 136), l2, font=f_b, fill=BODY)
    d.text((x + 24, y0 + 196), l3, font=f_b, fill=DIM)
    if i < 4:
        ax = x + bw + 2
        ay = y0 + bh // 2
        d.polygon([(ax, ay - 14), (ax + 22, ay), (ax, ay + 14)], fill=GREEN)
        d.line([ax - 2, ay, ax + 2, ay], fill=GREEN, width=4)

foot1 = "SentinelMint v2  0x11f163d82ba0be90dca99113b44cf1cfa719bee2"
foot2 = "SentinelReactiveV4  0xe5bef718142b911ac234ca524970e34d1496bc66  (Lasna)"
foot3 = "Reactive Omni Buildathon — Reactive Meets AI  ·  Nov 2026"
for j, (t, fnt, col) in enumerate([(foot1, f_small, BODY), (foot2, f_small, BODY), (foot3, f_foot, DIM)]):
    tw = d.textlength(t, font=fnt)
    d.text(((W - tw) / 2, 700 + j * 52), t, font=fnt, fill=col)

img.save("/home/hatch/workspace/hackathons/mintsentinel/demo/video-assets/diagram-loop.png")
print("wrote diagram-loop.png")
