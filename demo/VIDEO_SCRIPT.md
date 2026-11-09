# MintSentinel Demo Video — Script (<3 min, target ~165s)

Status: **RECORDED RUNS READY 10 Nov 2026 ~01:09 WIB.** Both legs proven live
tonight — no more top-ups needed. Build the video from the runs below.

## Format
- 1920x1080 30fps, H.264 + AAC, English TTS narration, no music (same as the
  NEAR MintGuard demo: demo/MintGuard-demo.mp4, 164.5s; Dubai:
  demo/MintGuard-demo-arbitrum.mp4, 135.2s).
- All visuals real data: terminal casts, Reactscan pages, Base Sepolia explorer.
- Every tx hash shown must be from the RECORDED runs below (not the 9 Nov
  proof runs #3/#2).
- Pipeline (reuse, do not reinvent): copy
  `~/workspace/hackathon-near-mintguard/demo/video-assets-arbitrum/` to
  `~/workspace/hackathons/mintsentinel/demo/video-assets/` and adapt paths:
  `render_term.py` (PIL terminal renderer), `box_shot.py` (Simular Box "main"
  real Chrome screenshots), TTS `/opt/hatch/bin/tts` voice avocado_v2:MAI_03,
  `build_video.py` (ffmpeg zoompan 1.00→1.06, concat, mux). See the Arbitrum
  `BUILD-NOTE.md` in that folder for the exact recipe + verification steps.

## RECORDED RUNS (the video's only source of hashes)

### SAFE leg — fresh SentinelMint v2 (the fallback that worked)
- Mint contract: **0x11f163d82ba0be90dca99113b44cf1cfa719bee2** (Base Sepolia,
  Sourcify VERIFIED, vet SAFE 100). Deploy tx
  0x69c7ba7278264da9b1b6241dbb2e0ae1ef34046bce562f41a29d50748660aed6.
- Reactive: **SentinelReactiveV4 (SAFE #2)
  0xe5bef718142b911ac234ca524970e34d1496bc66** (Lasna), deploy tx
  0xc3a96239ee7e9d9ef2653c52fb4ff15c14b7fb348eae14c33a9095a4bad35f2e,
  funded 0.05 lREACT BEFORE the mint (tx 0x7f878693...).
- requestMint (tokenId 0, nonce 0): **0x8bd32ce76fae97797c0cc28f530441ad770f813de260b1c29c4c53a4046e5bd9**,
  block 0x360177a, status 1.
- Callback DELIVERED ~30s. Agent verdict **SAFE 100** (verified=true,
  exact=true, price=0, sim=ok), submitVerdict tx
  **0xeaf461c3688da43d54cdbf91b8125bdd1a283d7928393cb0340b573e182eb1cf**.
- claimMint(0) SUCCESS: **0x7a166a1180f28170f66cbc02f0a26be9b6c5c3ee38e24ed5e05bb933af885214**,
  block 0x360189b; mints(0) status 5 (CLAIMED), score 100; ownerOf(0) =
  deployer 0xa9Fc6461303EC7DA70A4faA7820a63EeB9c952da.

### RISKY leg — round-2 #4 (proven 9 Nov ~23:49 WIB)
- Mint contract: **SentinelMintRisky
  0x161820a753adeb14b729961e71489abe2024fe4c** (Base Sepolia, Sourcify
  VERIFIED, vet RISKY 45).
- Reactive: **SentinelReactiveV4 (RISKY)
  0x06869e9e1e0fad23f6e05a9c35893fdf97339f5d** (Lasna), funded 0.05 lREACT
  BEFORE the mint.
- requestMint (tokenId 4, nonce 4, paid 0.0001 ETH):
  **0x12d51ce4f7cf46cf171ed57ebb2349f2da53257b8454174b5810b34063c89994**,
  block 0x35fbaf7, status 1.
- Callback DELIVERED ~2 min. Agent verdict **RISKY 45** (paid 0.0001 ETH,
  value-0 sim reverts "pay mint price"), submitVerdict tx
  **0x613120bdccf8338240650144aab6cf6270d00ff912f5d12ed7e93751b635174d**.
- claimMint(4) **REVERTED `BadStatus` (0x5c975bda)** as designed — the gate
  blocked it on-chain.

## Narration + shots

### 0:00–0:15 — Hook
"AI agents are starting to mint NFTs on their own. But an agent that mints
blind will sign anything — including a contract designed to drain it."
Shot: terminal, `npm run vet` on the risky contract showing RISKY 45.

### 0:15–0:40 — The loop
"MintSentinel fixes that. A free mint on Base Sepolia emits an event. A
reactive contract on Reactive Lasna picks it up — no off-chain bot — and sends
a callback back. Then an AI agent vets the contract and posts its verdict
on-chain. Only a SAFE mint can be claimed."
Shot: loop diagram (5 stages), then the two contract addresses.

### 0:40–1:40 — SAFE leg (live)
"First, a safe mint on a fresh contract. I request the mint."
Shot: `cast send requestMint()` -> MintRequested log.
"The reactive contract reacts in about thirty seconds and requests the
callback through the system contract."
Shot: Reactscan Lasna, v4 execution SUCCESS, CallbackRequest.
"The callback lands. The gate is armed. The AI agent vets the contract —
verified, exact match, free, simulation passes — SAFE, score 100."
Shot: agent log lines + submitVerdict tx; `mints(0)` status SAFE.
"And the claim succeeds. The NFT is minted."
Shot: `claimMint()` success, Transfer log, `ownerOf(0)` = deployer.

### 1:40–2:30 — RISKY leg (live)
"Now the same flow, with a risky mint — one that charges a hidden price."
Shot: `requestMint()` with 0.0001 ETH value -> MintRequested.
"The callback lands again. But this time the AI says RISKY, score 45 —
paid mint, simulation reverts."
Shot: agent-risky log + submitVerdict RISKY tx; `mints(4)` status RISKY.
"And the claim is blocked by the contract itself."
Shot: `claimMint()` reverting `BadStatus` on screen.

### 2:30–2:45 — Close
"Same loop, two outcomes. The AI verdict has real on-chain effect — safe
mints claim, risky mints can't. That's MintSentinel."
Shot: repo URL + both explorer links on screen.

## Proof runs (reference only — DO NOT show these hashes as the demo)
- SAFE mint #3: request 0xcf128781…, verdict 0x0c511587…, claim 0x8ec1bdd8…
- RISKY mint #2: request 0x8c6c4b89…, verdict 0x6ba79f9f…, claim reverts BadStatus.
- OLD contracts (DO NOT use — the old mint 0xe521... is poisoned by the v1
  debt; its callbacks never deliver): SentinelMint 0xe5213387beb36e4d75020689c5694bc449122f16,
  v3 SAFE 0xa2b63c8e2f3530379aca441cd8c59bd84b6bd692,
  v3 RISKY 0xb899f2E139C227B78b10d09B70d10b7A63bB4B8A.

## Recording checklist
- [x] Both legs proven live (SAFE fresh #0 ~01:09, RISKY #4 9 Nov 23:49)
- [x] Both agents running (agent-safe2.log + agent-risky.log)
- [x] Capture terminal outputs (vet SAFE 100 fresh mint, vet RISKY 45,
  requestMint/claim receipts) into display-*.txt — **DONE 10 Nov ~01:18 WIB**
- [x] Simular Box screenshots (Reactscan callback pages, BaseScan tx pages)
  — **DONE 10 Nov ~01:15 WIB** (Reactscan callbacks CONFIRMED + Blockscout claimMint Success)
- [x] TTS narration per scene (voice avocado_v2:MAI_03) — **DONE 10 Nov ~01:17 WIB**
- [x] Build + verify (ffprobe 1920x1080 30fps H.264+AAC, duration <180s,
  extract frames and check them visually) — **DONE 10 Nov ~01:21 WIB: 92.1s, 11 frames checked**
- [x] Output: `~/workspace/hackathons/mintsentinel/demo/MintSentinel-demo.mp4`
  — **DONE: 92.1s, 13.2MB. Build note: demo/video-assets/BUILD-NOTE.md**
