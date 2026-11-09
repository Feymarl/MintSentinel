#!/usr/bin/env python3
"""End card PNG (1920x1080) for the MintSentinel demo.
No repo URL: the public MintSentinel repo is not created yet, so the card
shows the two explorer links instead (both live and verifiable)."""
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
BG = (22, 24, 29)
GREEN = (126, 231, 135)
AMBER = (232, 163, 61)
BODY = (230, 230, 230)
DIM = (170, 170, 170)
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SANS_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
f_big = ImageFont.truetype(SANS_B, 110)
f_mid = ImageFont.truetype(SANS_B, 44)
f_body = ImageFont.truetype(SANS, 34)
f_link = ImageFont.truetype(MONO, 28)
f_foot = ImageFont.truetype(SANS, 30)

def center(y, text, font, fill):
    tw = d.textlength(text, font=font)
    d.text(((W - tw) / 2, y), text, font=font, fill=fill)

center(150, "MintSentinel", f_big, GREEN)
center(300, "Same loop, two outcomes.", f_mid, BODY)
center(370, "SAFE mints claim. RISKY mints can't.", f_mid, AMBER)
center(500, "Proof on-chain:", f_body, DIM)
center(560, "base-sepolia.blockscout.com/address/0x11f163d82ba0be90dca99113b44cf1cfa719bee2", f_link, BODY)
center(610, "base-sepolia.blockscout.com/address/0x161820a753adeb14b729961e71489abe2024fe4c", f_link, BODY)
center(660, "lasna.reactscan.net/address/0xe5bef718142b911ac234ca524970e34d1496bc66", f_link, BODY)
center(800, "Reactive Omni Buildathon — Reactive Meets AI  ·  Nov 2026", f_foot, DIM)

img.save("/home/hatch/workspace/hackathons/mintsentinel/demo/video-assets/endcard.png")
print("wrote endcard.png")
