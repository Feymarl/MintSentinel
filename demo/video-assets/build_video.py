#!/usr/bin/env python3
"""Assemble MintSentinel-demo.mp4 from stills + narration.
Adapted from the Dubai build (MintGuard-demo-arbitrum.mp4): per-scene
zoompan clips, per-scene wav, concat lists, final mux. All durations
derived from measured narration."""
import subprocess, os

A = "/home/hatch/workspace/hackathons/mintsentinel/demo/video-assets"
OUT = "/home/hatch/workspace/hackathons/mintsentinel/demo/MintSentinel-demo.mp4"

# scene: (still, narr mp3, pad seconds)
SCENES = [
    ("term-vet-risky.png",       "narr/narr-s0.mp3", 1.5),
    ("diagram-loop.png",         "narr/narr-s1.mp3", 1.5),
    ("term-safe-request.png",    "narr/narr-s2.mp3", 1.5),
    ("shot-reactscan-safe.jpg",  "narr/narr-s3.mp3", 1.5),
    ("term-safe-verdict.png",    "narr/narr-s4.mp3", 1.5),
    ("shot-blockscout-claim.jpg","narr/narr-s5.mp3", 1.5),
    ("term-risky-request.png",   "narr/narr-s6.mp3", 1.5),
    ("term-risky-verdict.png",   "narr/narr-s7.mp3", 1.5),
    ("term-risky-claim.png",     "narr/narr-s8.mp3", 1.5),
    ("endcard.png",              "narr/narr-s9.mp3", 1.5),
]

def run(cmd):
    print("+", " ".join(cmd[:6]), "...")
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-2000:]); print(r.stderr[-2000:])
        raise SystemExit(f"FAILED: {' '.join(cmd[:4])}")
    return r

def dur(path):
    r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", path])
    return float(r.stdout.strip())

# 1. narration -> wav + per-scene clip
vlist, alist = [], []
for i, (still, narr, pad) in enumerate(SCENES):
    nd = dur(os.path.join(A, narr))
    cd = round(nd + pad, 1)          # clip duration
    frames = int(cd * 30)
    wav = os.path.join(A, f"au-ms-s{i}.wav")
    run(["ffmpeg", "-y", "-v", "error", "-i", os.path.join(A, narr),
         "-af", f"aresample=48000,apad,atrim=0:{cd}", wav])
    alist.append(wav)
    clip = os.path.join(A, f"sc-ms-s{i}.mp4")
    # scale still up 10% for zoom headroom, then slow zoom-in 1.00 -> 1.06
    vf = (f"scale=2112:1188:force_original_aspect_ratio=increase,"
          f"crop=2112:1188,"
          f"zoompan=z='min(1+0.06*on/{frames},1.06)':d={frames}:"
          f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=30")
    run(["ffmpeg", "-y", "-v", "error", "-loop", "1", "-i", os.path.join(A, still),
         "-vf", vf, "-t", str(cd), "-c:v", "libx264", "-pix_fmt", "yuv420p",
         "-r", "30", clip])
    vlist.append(clip)
    print(f"scene {i}: narr={nd:.2f}s clip={cd}s frames={frames}")

# end card: 3s silent hold
end_clip = os.path.join(A, "sc-ms-end.mp4")
run(["ffmpeg", "-y", "-v", "error", "-loop", "1", "-i", os.path.join(A, "endcard.png"),
     "-vf", "scale=1920:1080,fps=30", "-t", "3", "-c:v", "libx264",
     "-pix_fmt", "yuv420p", "-r", "30", end_clip])
vlist.append(end_clip)
with open(os.path.join(A, "au-ms-end.wav"), "wb") as f:
    pass
run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
     "-t", "3", os.path.join(A, "au-ms-end.wav")])
alist.append(os.path.join(A, "au-ms-end.wav"))

# 2. concat video + audio
with open(os.path.join(A, "vlist-ms.txt"), "w") as f:
    for c in vlist:
        f.write(f"file '{c}'\n")
with open(os.path.join(A, "alist-ms.txt"), "w") as f:
    for a in alist:
        f.write(f"file '{a}'\n")
video_only = os.path.join(A, "video-only-ms.mp4")
run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0",
     "-i", os.path.join(A, "vlist-ms.txt"), "-c", "copy", video_only])
audio_full = os.path.join(A, "audio-full-ms.wav")
run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0",
     "-i", os.path.join(A, "alist-ms.txt"), "-c", "copy", audio_full])

# 3. mux
run(["ffmpeg", "-y", "-v", "error", "-i", video_only, "-i", audio_full,
     "-c:v", "copy", "-c:a", "aac", "-movflags", "+faststart", "-shortest", OUT])
r = run(["ffprobe", "-v", "error", "-show_entries",
         "format=duration,size", "-show_entries", "stream=codec_name,width,height,r_frame_rate",
         "-of", "default=noprint_wrappers=1", OUT])
print(r.stdout)
print("DONE:", OUT)
