# MintSentinel demo video — build note

Output: `demo/MintSentinel-demo.mp4` — **92.1 s (1:32)**, 1920×1080 30 fps,
H.264 + AAC 48 kHz, 13.2 MB. Same style as the NEAR + Dubai videos: slow
zoom-in stills + English TTS narration (voice avocado_v2:MAI_03,
`/opt/hatch/bin/tts`), no music. Built 10 Nov 2026 ~01:20 WIB.

## Scenes (clip = narration + 1.5 s pad)

| # | Visual | Narration | Dur |
|---|--------|-----------|-----|
| s0 | Terminal PNG, live vet of risky mint → **RISKY 45** | hook: agents minting blind sign anything | 9.6 s |
| s1 | Loop diagram (5 stages + both contract addresses) | the loop: event → reactive → callback → AI verdict → gate | 20.2 s |
| s2 | Terminal PNG, SAFE requestMint receipt (tokenId 0, nonce 0) | first, a safe mint — I request the mint | 5.3 s |
| s3 | Simular Box Chrome screenshot, Reactscan Lasna callbacks page | reactive reacts in ~30 s, callback requested | 6.9 s |
| s4 | Terminal PNG, agent-safe2.log + submitVerdict receipt + mints(0) SAFE | callback lands, AI vets — SAFE, score 100 | 12.8 s |
| s5 | Simular Box Chrome screenshot, Blockscout claimMint tx page | the claim succeeds, the NFT is minted | 4.7 s |
| s6 | Terminal PNG, RISKY requestMint tx (paid 0.0001 ETH, tokenId 4) | now the same flow, with a risky mint | 5.9 s |
| s7 | Terminal PNG, submitVerdict receipt + mints(4) RISKY 45 | the AI says RISKY, score 45 | 9.0 s |
| s8 | Terminal PNG, claimMint(4) reverts `BadStatus` (0x5c975bda) | the claim is blocked by the contract itself | 4.2 s |
| s9 | End card PNG (explorer links, no repo URL — see below) | same loop, two outcomes | 10.5 s |
| end | End card, 3 s silent hold | — | 3.0 s |

## How it was made

- Assets in `demo/video-assets/`: `render_term.py` (PIL terminal renderer,
  copied from the Dubai build; HIGHLIGHT extended with `BadStatus`,
  `execution reverted`, `CLAIMED`, `(SAFE)`, `(RISKY)`), `display-*.txt`
  (trimmed display text), `terminal-*.txt` (full untrimmed captures),
  `term-*.png`, `diagram-loop.png` (`diagram.py`), `endcard.png`
  (`endcard.py`), `shot-reactscan-safe.jpg` + `shot-blockscout-claim.jpg`
  (Simular Box "main" cb-956b7e37ccab, real Chrome, via `box_shot.py` +
  `browser_navigate`; both files are JPEG content despite the .jpg name on
  the Reactscan one — it was renamed from .webp after the box returned
  `image/jpeg`), `narr/narr-s*.mp3` (TTS), `build_video.py` (ffmpeg
  zoompan 1.00→1.06, concat, mux), `video-only-ms.mp4`,
  `audio-full-ms.wav`, `alist-ms.txt` / `vlist-ms.txt`.
- Narration text is verbatim from `demo/VIDEO_SCRIPT.md` (10 scenes).
- The diagram's first box originally read "1. MINT REQUESTED" and was
  clipped at the box edge; shortened to "1. MINT" (the body line already
  says "MintRequested event") and re-rendered + re-checked.

## Verification commands run (all 10 Nov 2026, before rendering)

- `npm run vet -- --ca 0x11f163d82ba0be90dca99113b44cf1cfa719bee2 --chain base-sepolia`
  → verified=true, exactMatch=true, mintPriceWei "0", simulationOk=true,
  **score 100, verdict SAFE** (saved: `terminal-vet-safe.txt`).
- `npm run vet -- --ca 0x161820a753adeb14b729961e71489abe2024fe4c --chain base-sepolia`
  → verified=true, exactMatch=true, mintPriceWei "100000000000000",
  simulationOk=false, simulationError "pay mint price",
  **score 45, verdict RISKY** (saved: `terminal-vet-risky.txt`).
- `cast receipt` / `cast tx` / `cast call` (base-sepolia-rpc.publicnode.com)
  for every recorded hash:
  - SAFE request `0x8bd32ce7…e5bd9`: status 1, block **56629114** (0x360177a),
    MintRequested log, tokenId 0, nonce 0.
  - SAFE verdict `0xeaf461c3…182eb1cf`: status 1, block **56629241**,
    VerdictSubmitted log "SAFE 100: verified=true exact=true price=0 sim=ok";
    mints(0) = (deployer, status **3 SAFE**, score **100**).
  - SAFE claim `0x7a166a11…f885214`: status 1, block **56629403** (0x360189b),
    Transfer log; ownerOf(0) = deployer 0xa9Fc…952da; mints(0) status **5
    (CLAIMED)**, score 100.
  - RISKY request `0x12d51ce4…c89994`: status 1, block **56605431**
    (0x35fbaf7), value **100000000000000 wei (0.0001 ETH)**, gasUsed 61780,
    MintRequested tokenId 4, nonce 4.
  - RISKY verdict `0x613120bd…35174d`: status 1, block **56605493**,
    VerdictSubmitted log "RISKY 45: … price=100000000000000
    sim=FAIL:pay mint price"; mints(4) = (deployer, status **4 RISKY**,
    score **45**).
  - RISKY claim: `cast call … "claimMint(uint256)" 4 --from deployer`
    → **"Error: execution reverted: BadStatus"**, data `0x5c975bda`
    (read-only reproduction; no tx sent, no gas spent — matches the
    recorded round-2 revert).
- Agent log used verbatim: `agent/agent-safe2.log` lines 2–4 (token 0
  PENDING 18:08:31Z → verdict SAFE 100 18:08:33Z → submitVerdict tx
  18:08:38Z).
- Final file verified: `ffprobe` (1920×1080, 30 fps, H.264 + AAC,
  duration **92.1 s**, 13.2 MB) + **11 extracted frames visually checked**
  (one per scene + end hold): hook vet, diagram, both request terminals,
  Reactscan callbacks CONFIRMED, both verdict terminals, Blockscout claim
  Success, BadStatus revert, end card. Audio checked with volumedetect on
  the full mix: mean −29.1 dB, max −5.7 dB (narration present, not silent);
  per-scene wav durations match narr + 1.5 s pad.

## What I could NOT verify myself

- **RISKY agent log lines:** `agent/agent-risky.log` contains only the
  startup line — it was relaunched (log overwritten) after the 10 Nov
  ~00:10 VM restart, and the RISKY #4 verdict lines went to the pre-restart
  log, which is lost. The s7 visual therefore shows the on-chain
  submitVerdict receipt + mints(4) state instead of agent log lines (the
  receipt's VerdictSubmitted log carries the same "RISKY 45 …" text). The
  SAFE agent log survived (agent-safe2.log) and is shown verbatim in s4.
- **The Blockscout screenshot has an ad banner** ("Build Skills Employers
  Want") over the bottom Sponsored row; the hash, Success status,
  claimMint method and block are all visible above it (same class of
  imperfection as the Dubai video's Arbiscan cookie banner).
- **End card has NO repo URL:** the public `Feymarl/MintSentinel` repo does
  not exist yet, so the card shows the three live explorer links instead
  (both mint contracts + the Lasna reactive). Add the repo URL once the
  repo is created.

## Honesty notes

- No mint or transaction was re-fired for this video — every hash on screen
  is from the RECORDED runs in `demo/VIDEO_SCRIPT.md` (SAFE fresh mint #0,
  RISKY round-2 #4) or from fresh read-only RPC reads of those same hashes.
  The two `npm run vet` calls and all `cast` calls are read-only.
- The old mint 0xe5213387beb36e4d75020689c5694bc449122f16 was NOT touched
  (poisoned by the v1 debt; its callbacks never deliver).
- The running AI agents (agent-safe2.log / agent-risky.log) were NOT killed
  or restarted.
- The requestMint display PNGs show the `cast receipt` / `cast tx` commands
  actually run to read the recorded txs, with a "(recorded …)" note — they
  do NOT pretend the mint was sent during the video build.
- The RISKY claim "revert" visual is a read-only `cast call` reproduction
  of the recorded revert (same calldata, same from-address, same BadStatus
  0x5c975bda); the recorded round-2 attempt also reverted at estimation
  with no tx sent.
- No number or hash on screen was invented: every value comes from the
  recorded runs / live RPC receipts listed above.
