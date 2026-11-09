# MintSentinel Demo Video — Script (<3 min, target ~165s)

Status: SCRIPT READY 9 Nov 2026 ~21:50 WIB. Recording BLOCKED on 0.01 Sepolia ETH
top-up from Rakha (deployer lREACT 0.0022; RISKY v3 needs ~0.05 funding for a
fresh callback run). SAFE v3 still holds 0.0329 lREACT (enough for 1 callback).
Once the top-up lands: faucet 0.0025 Sepolia ETH -> 0.25 lREACT, fund RISKY v3
0.05, then record BOTH legs fresh (new tokenIds) so the video shows live runs.

## Format
- 1920x1080 30fps, H.264 + AAC, English TTS narration, no music (same as the
  NEAR MintGuard demo: demo/MintGuard-demo.mp4, 164.5s).
- All visuals real data: terminal casts, Reactscan pages, Base Sepolia explorer.
- Every tx hash shown must be from the RECORDED run (not the 9 Nov proof runs).

## Narration + shots

### 0:00–0:15 — Hook
"AI agents are starting to mint NFTs on their own. But an agent that mints
blind will sign anything — including a contract designed to drain it."
Shot: terminal, `npm run vet` on a risky contract showing RISKY 45.

### 0:15–0:40 — The loop
"MintSentinel fixes that. A free mint on Base Sepolia emits an event. A
reactive contract on Reactive Lasna picks it up — no off-chain bot — and sends
a callback back. Then an AI agent vets the contract and posts its verdict
on-chain. Only a SAFE mint can be claimed."
Shot: loop diagram (5 stages), then the two contract addresses.

### 0:40–1:40 — SAFE leg (live)
"First, a safe mint. I request mint number four."
Shot: `cast send requestMint()` -> MintRequested log.
"The reactive contract reacts in about a minute and requests the callback
through the system contract."
Shot: Reactscan Lasna, v3 execution SUCCESS, CallbackRequest.
"The callback lands. The gate is armed. The AI agent vets the contract —
verified, exact match, free, simulation passes — SAFE, score 100."
Shot: agent log lines + submitVerdict tx; `mints(n)` status SAFE.
"And the claim succeeds. The NFT is minted."
Shot: `claimMint()` success, Transfer log, `ownerOf(n)` = deployer.

### 1:40–2:30 — RISKY leg (live)
"Now the same flow, with a risky mint — one that charges a hidden price."
Shot: `requestMint()` with 0.0001 ETH value -> MintRequested.
"The callback lands again. But this time the AI says RISKY, score 45 —
paid mint, simulation reverts."
Shot: agent-risky log + submitVerdict RISKY tx; `mints(n)` status RISKY.
"And the claim is blocked by the contract itself."
Shot: `claimMint()` reverting `BadStatus` on screen.

### 2:30–2:45 — Close
"Same loop, two outcomes. The AI verdict has real on-chain effect — safe
mints claim, risky mints can't. That's MintSentinel."
Shot: repo URL + both explorer links on screen.

## Proof runs (reference only — DO NOT show these hashes as the demo)
- SAFE mint #3: request 0xcf128781…, verdict 0x0c511587…, claim 0x8ec1bdd8…
- RISKY mint #2: request 0x8c6c4b89…, verdict 0x6ba79f9f…, claim reverts BadStatus.
- Contracts: SentinelMint 0xe5213387beb36e4d75020689c5694bc449122f16,
  SentinelMintRisky 0x161820a753adeb14b729961e71489abe2024fe4c,
  v3 SAFE 0xa2b63c8e2f3530379aca441cd8c59bd84b6bd692,
  v3 RISKY 0xb899f2E139C227B78b10d09B70d10b7A63bB4B8A.

## Recording checklist
- [ ] Top-up 0.01 Sepolia ETH received (deployer balance check)
- [ ] Faucet 0.0025 Sepolia ETH -> +0.25 lREACT (deployer)
- [ ] Fund RISKY v3 0.05 lREACT (SAFE v3 already 0.0329)
- [ ] Both agents running (check ps: agent.log + agent-risky.log tail)
- [ ] Record SAFE leg fresh (tokenId 4), then RISKY leg fresh (tokenId 3)
- [ ] Verify each tx hash, then edit + TTS + export <3 min
